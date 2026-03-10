import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/logging/logger.dart';
import 'backend_integration_service.dart';

/// Helper service for uploading recordings after SOS trigger
/// This should be called after camera/audio recording completes
class RecordingUploadHelper {
  final BackendIntegrationService _backendService = BackendIntegrationService();

  /// Upload video and audio recordings to backend
  /// Call this after recording stops
  Future<bool> uploadRecordings({
    String? videoFilePath,
    String? audioFilePath,
  }) async {
    try {
      logger.i('📤 Starting recording upload...');

      // Check if we have any files to upload
      if (videoFilePath == null && audioFilePath == null) {
        logger.w('⚠️ No recordings to upload');
        return false;
      }

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        logger.w('Could not get current location, using last known');
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          logger.e('❌ No location available for upload');
          return false;
        }
      }

      // Upload to backend
      final success = await _backendService.uploadRecordedEvidence(
        videoPath: videoFilePath,
        audioPath: audioFilePath,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (success) {
        logger.i('✅ Recordings uploaded successfully');
        if (videoFilePath != null) logger.i('   Video: $videoFilePath');
        if (audioFilePath != null) logger.i('   Audio: $audioFilePath');
        logger.i('   Location: ${position.latitude}, ${position.longitude}');
      } else {
        logger.e('❌ Recording upload failed');
      }

      return success;
    } catch (e) {
      logger.e('❌ Error uploading recordings: $e');
      return false;
    }
  }

  /// Upload video only
  Future<bool> uploadVideo(String videoFilePath) async {
    return await uploadRecordings(videoFilePath: videoFilePath);
  }

  /// Upload audio only
  Future<bool> uploadAudio(String audioFilePath) async {
    return await uploadRecordings(audioFilePath: audioFilePath);
  }

  /// Check if there's an active case to upload to
  Future<bool> hasActiveCase() async {
    final caseId = await _backendService.getCaseId();
    return caseId != null;
  }

  /// Get the current active case ID
  Future<String?> getActiveCaseId() async {
    return await _backendService.getCaseId();
  }
}
