import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'backend_integration_service.dart';

/// Helper class for testing backend integration
class BackendTestHelper {
  final BackendIntegrationService _service = BackendIntegrationService();

  /// Test complete flow: register user, create case, upload evidence
  Future<void> testCompleteFlow({
    required String name,
    required String phone,
    required String email,
    String? videoPath,
    String? audioPath,
  }) async {
    debugPrint('🧪 Starting backend integration test...\n');

    // Step 1: Register user
    debugPrint('Step 1: Registering user...');
    final userId = await _service.registerUser(
      name: name,
      phone: phone,
      email: email,
    );

    if (userId == null) {
      debugPrint('❌ Test failed: User registration failed\n');
      return;
    }
    debugPrint('✅ User registered: $userId\n');

    // Step 2: Get location
    debugPrint('Step 2: Getting location...');
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
      debugPrint('✅ Location: ${position.latitude}, ${position.longitude}\n');
    } catch (e) {
      debugPrint('⚠️ Using default location (location permission denied)\n');
      position = Position(
        latitude: 19.9975,
        longitude: 73.7898,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    // Step 3: Create emergency case
    debugPrint('Step 3: Creating emergency case...');
    final caseId = await _service.handleSOSTrigger(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (caseId == null) {
      debugPrint('❌ Test failed: Emergency case creation failed\n');
      return;
    }
    debugPrint('✅ Emergency case created: $caseId\n');

    // Step 4: Upload evidence (if files provided)
    if (videoPath != null || audioPath != null) {
      debugPrint('Step 4: Uploading evidence...');
      final uploaded = await _service.uploadRecordedEvidence(
        videoPath: videoPath,
        audioPath: audioPath,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (uploaded) {
        debugPrint('✅ Evidence uploaded successfully\n');
      } else {
        debugPrint('❌ Evidence upload failed\n');
      }
    } else {
      debugPrint('Step 4: Skipped (no files provided)\n');
    }

    // Step 5: Close case
    debugPrint('Step 5: Closing emergency case...');
    final closed = await _service.closeEmergency();
    if (closed) {
      debugPrint('✅ Emergency case closed\n');
    } else {
      debugPrint('⚠️ Failed to close case\n');
    }

    debugPrint('🎉 Test completed!\n');
  }

  /// Test user registration only
  Future<String?> testUserRegistration({
    required String name,
    required String phone,
    required String email,
  }) async {
    debugPrint('🧪 Testing user registration...');
    
    final userId = await _service.registerUser(
      name: name,
      phone: phone,
      email: email,
    );

    if (userId != null) {
      debugPrint('✅ User registered: $userId');
    } else {
      debugPrint('❌ User registration failed');
    }

    return userId;
  }

  /// Test emergency case creation only
  Future<String?> testEmergencyCreation() async {
    debugPrint('🧪 Testing emergency case creation...');

    // Check if user is registered
    final userId = await _service.getUserId();
    if (userId == null) {
      debugPrint('❌ No user registered. Register first.');
      return null;
    }

    // Get location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('⚠️ Using default location');
      position = Position(
        latitude: 19.9975,
        longitude: 73.7898,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    final caseId = await _service.handleSOSTrigger(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (caseId != null) {
      debugPrint('✅ Emergency case created: $caseId');
    } else {
      debugPrint('❌ Emergency case creation failed');
    }

    return caseId;
  }

  /// Test evidence upload only
  Future<bool> testEvidenceUpload({
    required String videoPath,
    required String audioPath,
  }) async {
    debugPrint('🧪 Testing evidence upload...');

    // Check if case exists
    final caseId = await _service.getCaseId();
    if (caseId == null) {
      debugPrint('❌ No active case. Create emergency first.');
      return false;
    }

    // Get location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      position = Position(
        latitude: 19.9975,
        longitude: 73.7898,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    final success = await _service.uploadRecordedEvidence(
      videoPath: videoPath,
      audioPath: audioPath,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (success) {
      debugPrint('✅ Evidence uploaded successfully');
    } else {
      debugPrint('❌ Evidence upload failed');
    }

    return success;
  }

  /// Get current status
  Future<void> printStatus() async {
    debugPrint('\n📊 Backend Integration Status:');
    
    final userId = await _service.getUserId();
    debugPrint('  User ID: ${userId ?? "Not registered"}');
    
    final caseId = await _service.getCaseId();
    debugPrint('  Active Case ID: ${caseId ?? "No active case"}');
    
    debugPrint('');
  }
}
