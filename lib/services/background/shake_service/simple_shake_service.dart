import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake_detector/shake_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/logging/logger.dart';
import '../../backend/backend_integration_service.dart';
import '../../sos/unified_sos_service.dart';
import '../../backend/backend_integration_service.dart';

/// Simple shake deteced version without background service complexity
class SimpleShakeService {
  static int _shakeCount = 0;
  static Timer? _resetTimer;
  static bool _isProcessingAlert = false;
  static bool _isInitialized = false;

  /// Initialize shake detection
  static void initialize() {
    if (_isInitialized) {
      logger.d('Shake service already initialized');
      return;
    }

    logger.i('Initializing simple shake detection service');

    ShakeDetector.autoStart(
      onShake: () async {
        await _handleShake();
      },
      shakeThresholdGravity: 2.7,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
    );

    _isInitialized = true;
    logger.i('✅ Shake detection initialized');
  }

  /// Handle shake event
  static Future<void> _handleShake() async {
    if (_isProcessingAlert) {
      logger.d('Alert already being processed, ignoring shake');
      return;
    }

    _shakeCount++;
    logger.d('Shake detected! Count: $_shakeCount/3');

    // Reset shake count after 3 seconds if not enough shakes
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (_shakeCount < 3) {
        logger.d('Shake count reset');
        _shakeCount = 0;
      }
    });

    // Trigger SOS if 3 shakes detected
    if (_shakeCount >= 3) {
      _isProcessingAlert = true;
      _resetTimer?.cancel();
      
      logger.i('🚨 3 shakes detected! Triggering SOS...');
      
      try {
        await _triggerSOS();
        logger.i('✅ SOS triggered successfully');
      } catch (e) {
        logger.e('❌ Error triggering SOS: $e');
      } finally {
        // Reset after 10 seconds to prevent multiple triggers
        await Future.delayed(const Duration(seconds: 10));
        _shakeCount = 0;
        _isProcessingAlert = false;
      }
    }
  }

  /// Trigger SOS alert - sends location and alerts contacts
  static Future<void> _triggerSOS() async {
    try {
      // Get user phone number
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) {
        logger.e('Phone number not found in preferences');
        return;
      }

      logger.d('Triggering SOS for user: $phoneNumber');

      // Get emergency contacts from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (!userDoc.exists) {
        logger.e('User document not found');
        return;
      }

      final userData = userDoc.data()!;
      final emergencyContacts = userData['emergency_contacts'] as List<dynamic>? ?? [];

      // ═══════════════════════════════════════════════════════════════
      // USE UNIFIED SOS SERVICE - Same as panic button
      // ═══════════════════════════════════════════════════════════════
      final sosService = UnifiedSOSService();
      
      final alertId = await sosService.triggerSOS(
        phoneNumber: phoneNumber,
        emergencyContacts: emergencyContacts,
        startRecording: true, // Start 30-second video recording
      );

      if (alertId != null) {
        logger.i('✅ SOS triggered successfully from shake detection');
      } else {
        logger.e('❌ Failed to trigger SOS');
      }

    } catch (e) {
      logger.e('Error in _triggerSOS: $e');
      rethrow;
    }
  }

  /// Generate 4-digit alphanumeric safety code
  static String _generateSafetyCode() {
    const String chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String code = '';
    final random = Random();
    
    for (int i = 0; i < 4; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    
    return code;
  }

  /// Stop shake detection
  static void dispose() {
    _isInitialized = false;
    logger.i('Shake detection stopped');
  }
}
