import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/logging/logger.dart';
import '../backend/backend_integration_service.dart';
import '../panic_video_service.dart';

/// Unified SOS Service
/// Handles SOS trigger from both shake detection and panic button
/// Ensures both flows work exactly the same way:
/// 1. Get location
/// 2. Get or create user by phone number
/// 3. Create emergency case in backend (returns case_id)
/// 4. Create alert in Firebase
/// 5. Start 30-second video recording
/// 6. Upload video to backend using case_id
class UnifiedSOSService {
  static final UnifiedSOSService _instance = UnifiedSOSService._internal();
  factory UnifiedSOSService() => _instance;
  UnifiedSOSService._internal();

  final BackendIntegrationService _backendService = BackendIntegrationService();
  final PanicVideoService _videoService = PanicVideoService();

  bool _isProcessing = false;

  /// Main SOS trigger - called from both shake and panic button
  /// Returns the alert ID if successful
  Future<String?> triggerSOS({
    required String phoneNumber,
    required List<dynamic> emergencyContacts,
    bool startRecording = true,
  }) async {
    if (_isProcessing) {
      logger.w('SOS already being processed');
      return null;
    }

    _isProcessing = true;

    try {
      logger.i('🚨 ═══════════════════════════════════════════════════════');
      logger.i('🚨 UNIFIED SOS TRIGGERED');
      logger.i('🚨 ═══════════════════════════════════════════════════════');

      // ═══════════════════════════════════════════════════════════════
      // STEP 1: Get Current Location
      // ═══════════════════════════════════════════════════════════════
      logger.i('📍 Step 1: Getting location...');
      Position? userLocation;
      try {
        userLocation = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        logger.i('✅ Location obtained: ${userLocation.latitude}, ${userLocation.longitude}');
      } catch (e) {
        logger.w('⚠️ Could not get current location, trying last known...');
        userLocation = await Geolocator.getLastKnownPosition();
        if (userLocation == null) {
          logger.e('❌ No location available');
          _isProcessing = false;
          return null;
        }
        logger.i('✅ Using last known location: ${userLocation.latitude}, ${userLocation.longitude}');
      }

      // ═══════════════════════════════════════════════════════════════
      // STEP 2: Get or Create User & Create Emergency Case in Backend
      // ═══════════════════════════════════════════════════════════════
      logger.i('📤 Step 2: Getting or creating user and creating emergency case...');
      String? backendCaseId;
      try {
        backendCaseId = await _backendService.handleSOSTrigger(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
        );

        if (backendCaseId != null) {
          logger.i('✅ Emergency case created: $backendCaseId');
          logger.i('   Location sent: ${userLocation.latitude}, ${userLocation.longitude}');
        } else {
          logger.w('⚠️ Case creation failed (will continue with Firebase)');
        }
      } catch (e) {
        logger.e('❌ Error creating case: $e');
        // Continue with Firebase even if backend fails
      }

      // ═══════════════════════════════════════════════════════════════
      // STEP 3: Create Alert in Firebase
      // ═══════════════════════════════════════════════════════════════
      logger.i('🔥 Step 3: Creating Firebase alert...');
      final safetyCode = _generateSafetyCode();
      final alertId = FirebaseFirestore.instance.collection('alerts').doc().id;

      final alertEntry = {
        'isActive': true,
        'alert_duration': {'alert_start': Timestamp.now()},
        'alerted_contacts': emergencyContacts.map((contact) {
          return {
            'alerted_contact_name': contact['emergency_contact_name'] ?? contact['name'] ?? '',
            'alerted_contact_number': contact['emergency_contact_number'] ?? contact['number'] ?? '',
          };
        }).toList(),
        'type': 'panic',
        'safety_code': safetyCode,
        'user_locations': {
          'user_location_start': GeoPoint(userLocation.latitude, userLocation.longitude),
          'user_location_end': GeoPoint(userLocation.latitude, userLocation.longitude),
        },
        'backend_case_id': backendCaseId, // Link to backend case
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('alerts')
          .doc(alertId)
          .set(alertEntry);

      logger.i('✅ Firebase alert created: $alertId');
      logger.i('   Safety Code: $safetyCode');

      // ═══════════════════════════════════════════════════════════════
      // STEP 4: Start 30-Second Front Camera Video Recording
      // ═══════════════════════════════════════════════════════════════
      if (startRecording) {
        logger.i('🎥 Step 4: Starting 30-second front camera recording...');
        
        // Ensure case_id is available before starting recording
        if (backendCaseId != null) {
          logger.i('✅ Case ID available for video upload: $backendCaseId');
        } else {
          logger.w('⚠️ No backend case_id - video will be saved locally only');
        }
        
        final videoPath = await _videoService.startPanicRecording();
        
        if (videoPath != null) {
          logger.i('✅ Video recording started: $videoPath');
          logger.i('⏱️  Recording will auto-stop after 30 seconds and upload');
        } else {
          logger.w('⚠️ Failed to start video recording (continuing without video)');
        }
      } else {
        logger.i('⏭️  Step 4: Recording skipped (startRecording=false)');
      }

      logger.i('🚨 ═══════════════════════════════════════════════════════');
      logger.i('🚨 SOS COMPLETED SUCCESSFULLY');
      logger.i('🚨 Alert ID: $alertId');
      logger.i('🚨 Safety Code: $safetyCode');
      if (backendCaseId != null) {
        logger.i('🚨 Backend Case ID: $backendCaseId');
      }
      logger.i('🚨 ═══════════════════════════════════════════════════════');

      _isProcessing = false;
      return alertId;

    } catch (e) {
      logger.e('❌ Error in SOS trigger: $e');
      _isProcessing = false;
      return null;
    }
  }



  /// Generate 4-digit alphanumeric safety code
  String _generateSafetyCode() {
    const String chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String code = '';
    final random = Random();
    
    for (int i = 0; i < 4; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    
    return code;
  }

  /// Check if SOS is currently being processed
  bool get isProcessing => _isProcessing;

  /// Cancel ongoing recording
  Future<void> cancelRecording() async {
    if (_videoService.isRecording) {
      await _videoService.cancelRecording();
      logger.i('Recording cancelled');
    }
  }
}
