import 'dart:async';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

List<CameraDescription> _availableCameras = [];

/// Service for handling camera recording with intelligent dual-camera detection
/// Strategy:
/// 1. Back camera is ALWAYS the primary (required for safety app)
/// 2. Front camera is OPTIONAL (only if device supports simultaneous recording)
/// 3. If device doesn't support dual recording: back camera only
/// 4. If device supports it AND user enables it: both cameras
class CameraService {
  late CameraController _frontCameraController;
  late CameraController _backCameraController;
  late CameraDescription _frontCamera;
  late CameraDescription _backCamera;
  bool _isFrontInitialized = false;
  bool _isBackInitialized = false;
  bool _isRecording = false;
  bool _isFrontRecording = false;
  bool _supportsDualRecording = false; // Device capability
  bool _enableDualRecording = false; // User preference (false by default for panic button)
  
  bool get isInitialized => _isBackInitialized; // Back camera is required
  bool get isRecording => _isRecording;
  bool get supportsDualRecording => _supportsDualRecording;
  CameraController get frontCameraController => _frontCameraController;
  CameraController get backCameraController => _backCameraController;
  
  // Set whether to use dual camera (only works if device supports it)
  void setDualRecordingEnabled(bool enabled) {
    _enableDualRecording = enabled;
    log('Dual recording ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> initializeCameras() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        log('✗ ERROR: No cameras available');
        return;
      }
      
      log('Available cameras: ${_availableCameras.length}');
      for (int i = 0; i < _availableCameras.length; i++) {
        log('  Camera $i: ${_availableCameras[i].lensDirection}');
      }
      
      // Find front and back cameras
      _frontCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () {
          log('⚠ WARNING: No front camera found, using first available');
          return _availableCameras.first;
        },
      );
      
      _backCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () {
          log('⚠ WARNING: No back camera found, using last available');
          return _availableCameras.length > 1 ? _availableCameras.last : _availableCameras.first;
        },
      );

      // Initialize back camera with audio (PRIMARY - REQUIRED)
      log('Initializing back camera (PRIMARY - REQUIRED)...');
      _backCameraController = CameraController(
        _backCamera,
        ResolutionPreset.high,
        enableAudio: true, // Back camera captures audio
      );
      await _backCameraController.initialize();
      _isBackInitialized = true;
      log('✓ Back camera initialized successfully with audio');

      // Initialize front camera (OPTIONAL - based on user preference)
      if (_enableDualRecording) {
        log('Initializing front camera (OPTIONAL - will detect support)...');
        try {
          _frontCameraController = CameraController(
            _frontCamera,
            ResolutionPreset.medium,
            enableAudio: false, // Front camera doesn't need audio
          );
          await _frontCameraController.initialize();
          _isFrontInitialized = true;
          _supportsDualRecording = true; // Device supports dual init
          log('✓ Front camera initialized successfully');
          log('✓ Device SUPPORTS dual camera recording');
        } catch (e) {
          _isFrontInitialized = false;
          _supportsDualRecording = false;
          log('⚠ Front camera initialization failed (device may not support dual): $e');
          log('⚠ Will use BACK CAMERA ONLY for recording');
        }
      } else {
        log('Front camera initialization SKIPPED (dual recording disabled)');
        _isFrontInitialized = false;
        _supportsDualRecording = false;
      }
      
      log('═══════════════════════════════════════════════');
      log('✓ CAMERA INITIALIZATION COMPLETE');
      log('  Back camera: ${_backCamera.lensDirection} (PRIMARY - Required)');
      if (_enableDualRecording && _supportsDualRecording) {
        log('  Front camera: ${_frontCamera.lensDirection} (OPTIONAL - Enabled)');
        log('  Recording mode: DUAL CAMERA');
      } else if (_enableDualRecording && !_supportsDualRecording) {
        log('  Front camera: NOT SUPPORTED by this device');
        log('  Recording mode: BACK CAMERA ONLY (fallback)');
      } else {
        log('  Recording mode: BACK CAMERA ONLY (by choice)');
      }
      log('═══════════════════════════════════════════════');
    } catch (e) {
      log('✗ CRITICAL ERROR initializing cameras: $e');
      _isFrontInitialized = false;
      _isBackInitialized = false;
    }
  }

  /// Initialize ONLY front camera for panic button recording
  Future<void> initializeFrontCameraOnly() async {
    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      
      _frontCamera = _availableCameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _availableCameras.first,
      );

      log('Initializing FRONT camera ONLY for panic recording...');
      _frontCameraController = CameraController(
        _frontCamera,
        ResolutionPreset.high,
        enableAudio: true, // Enable audio for front camera
      );
      await _frontCameraController.initialize();
      _isFrontInitialized = true;
      log('✓ Front camera initialized successfully with audio');
    } catch (e) {
      log('✗ ERROR initializing front camera: $e');
      _isFrontInitialized = false;
    }
  }

  // Check if back camera (main requirement) is ready
  bool _canStartRecording() {
    if (!_isBackInitialized) {
      log('✗ Back camera not initialized');
      return false;
    }
    if (!_backCameraController.value.isInitialized) {
      log('✗ Back camera controller state invalid');
      return false;
    }
    if (_isRecording) {
      log('✗ Already recording');
      return false;
    }
    return true;
  }
  
  // Check if front camera is available for dual recording
  bool _canUseFrontCamera() {
    return _enableDualRecording && 
           _isFrontInitialized && 
           _supportsDualRecording &&
           _frontCameraController.value.isInitialized;
  }

  /// Start front camera recording for panic button (30 seconds)
  /// Returns front camera path only
  Future<({String? videoPath, String? error})> startFrontCameraRecording() async {
    if (!_isFrontInitialized) {
      final error = 'Front camera not initialized';
      log('✗ $error');
      return (videoPath: null, error: error);
    }

    if (!_frontCameraController.value.isInitialized) {
      final error = 'Front camera controller not ready';
      log('✗ $error');
      return (videoPath: null, error: error);
    }

    if (_isRecording) {
      final error = 'Already recording';
      log('✗ $error');
      return (videoPath: null, error: error);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final videoPath = '${tempDir.path}/panic_video_${timestamp}.mp4';

      log('═══════════════════════════════════════════════');
      log('START FRONT CAMERA RECORDING (PANIC BUTTON)');
      log('Timestamp: $timestamp');
      log('Video path: $videoPath');

      await _frontCameraController.startVideoRecording();
      
      if (_frontCameraController.value.isRecordingVideo) {
        _isRecording = true;
        log('✓ Front camera recording started successfully');
        log('═══════════════════════════════════════════════');
        return (videoPath: videoPath, error: null);
      } else {
        log('✗ Front camera not in recording state');
        return (videoPath: null, error: 'Failed to start recording');
      }
    } catch (e) {
      log('✗ ERROR starting front camera: $e');
      return (videoPath: null, error: 'Recording failed: $e');
    }
  }

  /// Stop front camera recording
  Future<({String? videoPath, String? error})> stopFrontCameraRecording() async {
    log('═══════════════════════════════════════════════');
    log('STOP FRONT CAMERA RECORDING');

    if (!_isRecording) {
      final error = 'Not currently recording';
      log('✗ $error');
      return (videoPath: null, error: error);
    }

    if (!_frontCameraController.value.isRecordingVideo) {
      final error = 'Front camera not recording';
      log('✗ $error');
      _isRecording = false;
      return (videoPath: null, error: error);
    }

    try {
      final video = await _frontCameraController.stopVideoRecording();
      _isRecording = false;
      
      log('✓ Front camera recording stopped');
      log('  File: ${video.path}');
      log('═══════════════════════════════════════════════');
      
      return (videoPath: video.path, error: null);
    } catch (e) {
      log('✗ ERROR stopping front camera: $e');
      _isRecording = false;
      return (videoPath: null, error: 'Stop recording failed: $e');
    }
  }

  /// Start recording - intelligently uses back camera only or dual based on device capability
  /// Returns both paths if available, but back camera is REQUIRED
  Future<({String? frontPath, String? backPath, String? error})> startDualVideoRecording() async {
    if (!_canStartRecording()) {
      final error = 'Cannot start recording: back camera not properly initialized';
      log('✗ $error');
      return (frontPath: null, backPath: null, error: error);
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final backPath = '${tempDir.path}/video_back_${timestamp}.mp4';
      final frontPath = '${tempDir.path}/video_front_${timestamp}.mp4';

      log('═══════════════════════════════════════════════');
      log('START VIDEO RECORDING');
      log('Timestamp: $timestamp');
      log('Back camera path: $backPath');
      if (_canUseFrontCamera()) {
        log('Front camera path: $frontPath');
      }
      
      // Start back camera recording (REQUIRED)
      log('► Starting BACK camera recording (required)...');
      try {
        await _backCameraController.startVideoRecording();
        if (_backCameraController.value.isRecordingVideo) {
          log('✓ Back camera recording started successfully');
        } else {
          log('✗ Back camera startVideoRecording() called but controller not recording');
          log('  Video recording status: ${_backCameraController.value.isRecordingVideo}');
          return (
            frontPath: null,
            backPath: null,
            error: 'Back camera recording failed - controller not in recording state'
          );
        }
      } catch (e) {
        log('✗ EXCEPTION starting back camera: $e');
        log('  Stack: ${e.runtimeType}');
        return (
          frontPath: null,
          backPath: null,
          error: 'Back camera recording failed: $e'
        );
      }

      // Try front camera if device supports it
      _isFrontRecording = false;
      if (_canUseFrontCamera()) {
        log('► Attempting FRONT camera recording (optional)...');
        try {
          await _frontCameraController.startVideoRecording();
          if (_frontCameraController.value.isRecordingVideo) {
            _isFrontRecording = true;
            log('✓ Front camera recording started');
          } else {
            log('⚠ Front camera call succeeded but not in recording state');
          }
        } catch (e) {
          log('⚠ Front camera recording failed (device may not support dual): $e');
          log('  Continuing with BACK CAMERA ONLY');
        }
      }

      _isRecording = true;
      
      log('═══════════════════════════════════════════════');
      log('✓ RECORDING STARTED');
      log('  Back: ✓ (with audio)');
      log('  Front: ${_isFrontRecording ? '✓' : '✗ (not available)'}');
      log('═══════════════════════════════════════════════');
      
      return (frontPath: frontPath, backPath: backPath, error: null);
    } catch (e) {
      log('✗ CRITICAL ERROR in startDualVideoRecording: $e');
      _isRecording = false;
      return (
        frontPath: null,
        backPath: null,
        error: 'Recording initialization failed: $e'
      );
    }
  }

  /// Stop recording from both cameras
  /// Back camera is REQUIRED to succeed, front is optional
  Future<({XFile? front, XFile? back, String? error})> stopDualVideoRecording() async {
    log('═══════════════════════════════════════════════');
    log('STOP VIDEO RECORDING');
    
    if (!_isRecording) {
      final error = 'Not currently recording';
      log('✗ $error');
      return (front: null, back: null, error: error);
    }

    XFile? backVideo;
    XFile? frontVideo;
    String? error;

    try {
      // Stop back camera (REQUIRED)
      log('► Stopping BACK camera...');
      if (_backCameraController.value.isRecordingVideo) {
        try {
          backVideo = await _backCameraController.stopVideoRecording();
          log('✓ Back camera stopped');
          log('  File: ${backVideo.path}');
          log('  Size: ${backVideo.name}');
        } catch (e) {
          log('✗ ERROR stopping back camera: $e');
          error = 'Failed to stop back camera: $e';
          _isRecording = false;
          return (front: null, back: null, error: error);
        }
      } else {
        log('✗ Back camera not in recording state');
        error = 'Back camera recording ended unexpectedly';
        _isRecording = false;
        return (front: null, back: null, error: error);
      }

      // Stop front camera (OPTIONAL)
      if (_isFrontRecording && _frontCameraController.value.isRecordingVideo) {
        log('► Stopping FRONT camera...');
        try {
          frontVideo = await _frontCameraController.stopVideoRecording();
          log('✓ Front camera stopped');
          log('  File: ${frontVideo.path}');
        } catch (e) {
          log('⚠ Front camera stop failed (continuing without front): $e');
          // Front camera failure doesn't fail the entire operation
        }
      }

      _isRecording = false;
      _isFrontRecording = false;

      log('═══════════════════════════════════════════════');
      log('✓ RECORDING STOPPED SUCCESSFULLY');
      log('  Back: ✓ (${backVideo?.path})');
      log('  Front: ${frontVideo != null ? '✓' : '✗ (not available)'}');
      log('═══════════════════════════════════════════════');

      return (front: frontVideo, back: backVideo, error: null);
    } catch (e) {
      log('✗ CRITICAL ERROR in stopDualVideoRecording: $e');
      _isRecording = false;
      _isFrontRecording = false;
      return (
        front: null,
        back: null,
        error: 'Stop recording failed: $e'
      );
    }
  }

  bool get mounted => true; // Placeholder for lifecycle check

  void dispose() {
    try {
      if (_isRecording) {
        stopDualVideoRecording();
      }
      if (_isFrontInitialized) {
        _frontCameraController.dispose();
      }
      if (_isBackInitialized) {
        _backCameraController.dispose();
      }
      log('✓ Camera service disposed');
    } catch (e) {
      log('✗ ERROR disposing camera service: $e');
    }
  }
}