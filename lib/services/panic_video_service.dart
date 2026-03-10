import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../utils/logging/logger.dart';
import 'background/camera_service/camera_service.dart';
import 'backend/backend_integration_service.dart';

/// Service for handling 10-second video recording on panic button press
/// Records from FRONT CAMERA only
class PanicVideoService {
  static final PanicVideoService _instance = PanicVideoService._internal();
  factory PanicVideoService() => _instance;
  PanicVideoService._internal();

  final CameraService _cameraService = CameraService();
  final BackendIntegrationService _backendService = BackendIntegrationService();

  bool _isRecording = false;
  Timer? _recordingTimer;
  String? _currentVideoPath;

  bool get isRecording => _isRecording;

  /// Start 10-second front camera recording
  /// Returns video path if successful
  Future<String?> startPanicRecording() async {
    if (_isRecording) {
      logger.w('⚠️ Already recording');
      return null;
    }

    try {
      logger.i('🎥 ═══════════════════════════════════════════════════════');
      logger.i('🎥 PANIC BUTTON: Starting 10-second video recording');
      logger.i('🎥 Camera: FRONT CAMERA ONLY');
      logger.i('🎥 ═══════════════════════════════════════════════════════');

      // Initialize camera if not already done
      if (!_cameraService.isInitialized) {
        logger.i('📷 Initializing cameras...');
        // Enable front camera for panic button
        _cameraService.setDualRecordingEnabled(false); // Only front camera
        await _cameraService.initializeCameras();
        
        // Now manually initialize front camera since dual recording is disabled
        logger.i('📷 Manually initializing front camera for panic recording...');
        await _cameraService.initializeFrontCameraOnly();
      }

      // Start front camera recording
      final result = await _cameraService.startFrontCameraRecording();

      if (result.error != null) {
        logger.e('❌ Failed to start recording: ${result.error}');
        _showErrorToast('Failed to start video recording');
        return null;
      }

      _isRecording = true;
      _currentVideoPath = result.videoPath;
      logger.i('✅ Recording started successfully');
      logger.i('📁 Video will be saved to: $_currentVideoPath');

      // Start 10-second countdown
      _startRecordingTimer();

      return _currentVideoPath;
    } catch (e) {
      logger.e('❌ Error starting panic recording: $e');
      _showErrorToast('Recording error: $e');
      return null;
    }
  }

  /// Start 10-second timer
  void _startRecordingTimer() {
    int secondsRemaining = 10;
    logger.i('⏱️  Recording for 10 seconds...');

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsRemaining--;
      
      if (secondsRemaining % 5 == 0 && secondsRemaining > 0) {
        logger.i('⏱️  Recording: $secondsRemaining seconds remaining...');
      }

      if (secondsRemaining <= 0) {
        timer.cancel();
        _stopAndUploadRecording();
      }
    });
  }

  /// Stop recording and upload to backend
  Future<void> _stopAndUploadRecording() async {
    if (!_isRecording) {
      logger.w('⚠️ Not recording');
      return;
    }

    try {
      logger.i('🎥 Stopping recording...');
      
      final result = await _cameraService.stopFrontCameraRecording();
      _isRecording = false;
      _recordingTimer?.cancel();

      if (result.error != null) {
        logger.e('❌ Error stopping recording: ${result.error}');
        _showErrorToast('Failed to stop recording');
        return;
      }

      var videoPath = result.videoPath;
      if (videoPath == null) {
        logger.e('❌ No video path returned');
        _showErrorToast('Recording failed');
        return;
      }

      logger.i('✅ Recording stopped successfully');
      logger.i('📁 Video saved: $videoPath');

      // Rename .temp file to .mp4 if needed
      if (videoPath.endsWith('.temp')) {
        logger.i('🔄 Renaming .temp file to .mp4...');
        final tempFile = File(videoPath);
        final finalPath = videoPath.replaceAll('.temp', '.mp4');
        
        try {
          final renamedFile = await tempFile.rename(finalPath);
          videoPath = renamedFile.path;
          logger.i('✅ File renamed successfully: $videoPath');
        } catch (e) {
          logger.w('⚠️ Could not rename file, using original path: $e');
          // Continue with original path if rename fails
        }
      }

      // Verify file exists and has content
      final file = File(videoPath!);
      if (!await file.exists()) {
        logger.e('❌ Video file does not exist: $videoPath');
        _showErrorToast('Video file not found');
        return;
      }

      final fileSize = await file.length();
      logger.i('📊 Video size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      if (fileSize == 0) {
        logger.e('❌ Video file is empty (0 bytes)');
        logger.e('❌ This usually means the camera recording failed silently');
        _showErrorToast('Video recording failed - file is empty');
        return;
      }

      // Upload to backend
      await _uploadVideoToBackend(videoPath!);

    } catch (e) {
      logger.e('❌ Error in stop and upload: $e');
      logger.e('❌ Stack trace: ${StackTrace.current}');
      _showErrorToast('Upload error: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
    }
  }

  /// Upload video to backend using case_id
  Future<void> _uploadVideoToBackend(String videoPath) async {
    try {
      logger.i('📤 ═══════════════════════════════════════════════════════');
      logger.i('📤 Uploading video to backend...');
      logger.i('📁 Video path: $videoPath');

      // Check if we have an active case
      logger.i('🔍 Checking for active case_id in SharedPreferences...');
      final caseId = await _backendService.getCaseId();
      
      logger.i('📋 Retrieved case_id: $caseId');
      
      if (caseId == null) {
        logger.e('❌ No active case_id found. Cannot upload video.');
        logger.e('❌ Make sure emergency case was created successfully');
        _showErrorToast('No emergency case found');
        return;
      }

      logger.i('✅ Case ID found: $caseId');

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        logger.i('📍 Location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        logger.w('⚠️ Could not get current location, using last known');
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          logger.e('❌ No location available');
          _showErrorToast('Location unavailable');
          return;
        }
        logger.i('📍 Using last known location: ${position.latitude}, ${position.longitude}');
      }

      // Upload video
      final success = await _backendService.uploadRecordedEvidence(
        videoPath: videoPath,
        audioPath: null,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (success) {
        logger.i('✅ Video uploaded successfully!');
        logger.i('📤 ═══════════════════════════════════════════════════════');
        _showSuccessToast('Video uploaded successfully');
      } else {
        logger.e('❌ Video upload failed');
        logger.i('💾 Video saved locally: $videoPath');
        _showErrorToast('Upload failed, video saved locally');
      }

    } catch (e) {
      logger.e('❌ Error uploading video: $e');
      logger.e('❌ Stack trace: ${StackTrace.current}');
      _showErrorToast('Upload error: $e');
    }
  }

  /// Manually stop recording (if user cancels)
  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    logger.i('🛑 Cancelling recording...');
    _recordingTimer?.cancel();
    
    try {
      await _cameraService.stopFrontCameraRecording();
      logger.i('✅ Recording cancelled');
    } catch (e) {
      logger.e('❌ Error cancelling recording: $e');
    }

    _isRecording = false;
    _currentVideoPath = null;
  }

  /// Show success toast
  void _showSuccessToast(String message) {
    logger.i('✅ Toast: $message');
    // Toast will be shown from UI layer
  }

  /// Show error toast
  void _showErrorToast(String message) {
    logger.e('❌ Toast: $message');
    // Toast will be shown from UI layer
  }

  /// Dispose service
  void dispose() {
    _recordingTimer?.cancel();
    _isRecording = false;
  }
}
