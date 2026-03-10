import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_service.dart';
import 'evidence_service.dart';
import 'user_service.dart';

/// Integration service that orchestrates backend operations for SOS flow
class BackendIntegrationService {
  final EmergencyService _emergencyService = EmergencyService();
  final EvidenceService _evidenceService = EvidenceService();
  final BackendUserService _userService = BackendUserService();

  /// Complete SOS flow: Create emergency case and prepare for evidence upload
  /// Automatically registers user if not already registered
  Future<String?> handleSOSTrigger({
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('🚨 Handling SOS trigger...');

      // ═══════════════════════════════════════════════════════════════
      // STEP 1: Get phone number from SharedPreferences
      // ═══════════════════════════════════════════════════════════════
      debugPrint('📱 Step 1: Getting phone number...');
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');
      
      if (phoneNumber == null) {
        debugPrint('❌ No phone number found in SharedPreferences');
        return null;
      }
      debugPrint('✅ Phone number: $phoneNumber');

      // ═══════════════════════════════════════════════════════════════
      // STEP 2: Get or create user by phone number
      // ═══════════════════════════════════════════════════════════════
      debugPrint('👤 Step 2: Getting or creating user...');
      String? userId = await _userService.getOrCreateUser(phoneNumber);
      
      if (userId == null) {
        debugPrint('❌ Failed to get or create user');
        return null;
      }
      debugPrint('✅ User ID obtained: $userId');

      // ═══════════════════════════════════════════════════════════════
      // STEP 3: Create emergency case
      // ═══════════════════════════════════════════════════════════════
      debugPrint('🚨 Step 3: Creating emergency case...');
      final emergencyCase = await _emergencyService.startEmergency(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
      );

      if (emergencyCase != null) {
        debugPrint('✅ Emergency case created: ${emergencyCase.id}');
        return emergencyCase.id;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error handling SOS trigger: $e');
      return null;
    }
  }

  /// Upload recorded evidence after recording completes
  Future<bool> uploadRecordedEvidence({
    String? videoPath,
    String? audioPath,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get active case_id
      final caseId = await _emergencyService.getSavedCaseId();
      
      if (caseId == null) {
        debugPrint('⚠️ No active case_id found. Cannot upload evidence.');
        return false;
      }

      // Validate files exist
      if (videoPath != null) {
        final videoValid = await _evidenceService.validateFile(videoPath);
        if (!videoValid) {
          debugPrint('⚠️ Video file validation failed');
          videoPath = null;
        }
      }

      if (audioPath != null) {
        final audioValid = await _evidenceService.validateFile(audioPath);
        if (!audioValid) {
          debugPrint('⚠️ Audio file validation failed');
          audioPath = null;
        }
      }

      if (videoPath == null && audioPath == null) {
        debugPrint('❌ No valid files to upload');
        return false;
      }

      // Upload evidence
      final response = await _evidenceService.uploadEvidence(
        caseId: caseId,
        videoFilePath: videoPath,
        audioFilePath: audioPath,
        latitude: latitude,
        longitude: longitude,
      );

      if (response != null) {
        debugPrint('✅ Evidence uploaded successfully');
        debugPrint('  Files uploaded: ${response.uploadedFiles.length}');
        for (final file in response.uploadedFiles) {
          debugPrint('    - ${file.fileType}: ${file.fileUrl}');
        }
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error uploading evidence: $e');
      return false;
    }
  }

  /// Register user with backend (call after Firebase authentication)
  Future<String?> registerUser({
    required String name,
    required String phone,
    required String email,
  }) async {
    final user = await _userService.registerUser(
      name: name,
      phone: phone,
      email: email,
    );

    return user?.id;
  }

  /// Auto-register current logged-in user with backend
  /// Fetches user data from Firestore and registers with backend
  /// If user already exists in backend, nothing happens
  Future<String?> autoRegisterCurrentUser() async {
    final user = await _userService.autoRegisterCurrentUser();
    return user?.id;
  }

  /// Get current user_id
  Future<String?> getUserId() async {
    return await _userService.getSavedUserId();
  }

  /// Get current case_id
  Future<String?> getCaseId() async {
    return await _emergencyService.getSavedCaseId();
  }

  /// Close emergency case
  Future<bool> closeEmergency() async {
    final caseId = await _emergencyService.getSavedCaseId();
    
    if (caseId == null) return false;

    final success = await _emergencyService.updateCaseStatus(
      caseId: caseId,
      status: 'closed',
    );

    if (success) {
      await _emergencyService.clearCaseId();
    }

    return success;
  }

  /// Resolve emergency case
  Future<bool> resolveEmergency() async {
    final caseId = await _emergencyService.getSavedCaseId();
    
    if (caseId == null) return false;

    return await _emergencyService.updateCaseStatus(
      caseId: caseId,
      status: 'resolved',
    );
  }
}
