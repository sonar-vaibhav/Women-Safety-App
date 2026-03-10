import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shake_detector/shake_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../../utils/logging/logger.dart';
import '../../backend/backend_integration_service.dart';
import '../../sos/unified_sos_service.dart';

/// Background service for shake detection
/// CRITICAL: Class must be annotated to be accessible from native code
@pragma('vm:entry-point')
class ShakeBackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize and configure the background service
  static Future<void> initialize() async {
    try {
      // First, create notification channel
      await _createNotificationChannel();
      
      logger.i('Configuring background service...');
      
      // Then configure the background service
      await _service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false, // Don't auto-start, we'll start manually
          isForegroundMode: true,
          notificationChannelId: 'safeguardher_shake_service',
          initialNotificationTitle: 'SafeGuardHer Protection Active',
          initialNotificationContent: 'Shake your phone 3 times for emergency',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
      
      logger.i('✅ Background service configured successfully');
    } catch (e) {
      logger.e('❌ Error initializing background service: $e');
      rethrow;
    }
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'safeguardher_shake_service', // id (must match service config)
        'Background Protection', // name
        description: 'Keeps shake detection active in background',
        importance: Importance.low, // Low importance to avoid annoying users
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      logger.i('✅ Notification channel created: safeguardher_shake_service');
    } catch (e) {
      logger.e('❌ Error creating notification channel: $e');
      rethrow;
    }
  }

  /// Start the background service
  static Future<void> startService() async {
    try {
      final isRunning = await _service.isRunning();
      if (!isRunning) {
        logger.i('Starting shake background service...');
        await _service.startService();
        logger.i('✅ Shake background service started successfully');
      } else {
        logger.i('Shake background service already running');
      }
    } catch (e) {
      logger.e('❌ Error starting background service: $e');
      // Don't rethrow - app should continue even if background service fails
    }
  }

  /// Stop the background service
  static Future<void> stopService() async {
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke('stopService');
        logger.i('✅ Shake background service stopped');
      }
    } catch (e) {
      logger.e('❌ Error stopping background service: $e');
    }
  }

  /// Check if service is running
  static Future<bool> isServiceRunning() async {
    return await _service.isRunning();
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  /// Main service entry point - runs in background
  /// CRITICAL: Must have @pragma annotation to be accessible from native code
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Ensure Flutter bindings are initialized
    DartPluginRegistrant.ensureInitialized();

    int shakeCount = 0;
    Timer? resetTimer;
    bool isProcessingAlert = false;

    logger.i('Background shake service started');

    // Update notification every 30 seconds to show service is alive
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });

      Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (await service.isForegroundService()) {
          final now = DateTime.now();
          service.setForegroundNotificationInfo(
            title: 'SafeGuardHer Protection Active',
            content: 'Shake 3 times for emergency • Last check: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          );
        }
      });
    }

    // Initialize shake detector
    ShakeDetector.autoStart(
      onShake: () async {
        if (isProcessingAlert) {
          logger.d('Alert already being processed, ignoring shake');
          return;
        }

        shakeCount++;
        logger.d('Shake detected! Count: $shakeCount/3');

        // Update notification to show shake count
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Shake Detected! ($shakeCount/3)',
            content: shakeCount >= 3 
                ? 'Triggering SOS Alert...' 
                : 'Shake ${3 - shakeCount} more time(s) for SOS',
          );
        }

        // Reset shake count after 3 seconds if not enough shakes
        resetTimer?.cancel();
        resetTimer = Timer(const Duration(seconds: 3), () {
          if (shakeCount < 3) {
            logger.d('Shake count reset');
            shakeCount = 0;
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: 'SafeGuardHer Protection Active',
                content: 'Shake 3 times for emergency',
              );
            }
          }
        });

        // Trigger SOS if 3 shakes detected
        if (shakeCount >= 3) {
          isProcessingAlert = true;
          resetTimer?.cancel();
          
          logger.i('🚨 3 shakes detected! Triggering SOS...');
          
          try {
            await _triggerSOS(service);
            logger.i('✅ SOS triggered successfully');
          } catch (e) {
            logger.e('❌ Error triggering SOS: $e');
          } finally {
            // Reset after 10 seconds to prevent multiple triggers
            await Future.delayed(const Duration(seconds: 10));
            shakeCount = 0;
            isProcessingAlert = false;
            
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: 'SafeGuardHer Protection Active',
                content: 'Shake 3 times for emergency',
              );
            }
          }
        }
      },
      shakeThresholdGravity: 2.7,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
    );

    logger.i('Shake detector initialized in background');
  }

  /// Trigger SOS alert - sends location and alerts contacts
  static Future<void> _triggerSOS(ServiceInstance service) async {
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
        
        // Update notification with success
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: '🚨 SOS Alert Sent!',
            content: 'Emergency contacts notified • Recording in progress',
          );
        }

        // Send local notification
        await _sendLocalNotification(
          'SOS Alert Activated',
          'Your emergency contacts have been notified. Recording 30-second video.',
        );
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

  /// Send local notification to user
  static Future<void> _sendLocalNotification(String title, String body) async {
    // This will be handled by flutter_local_notifications
    // For now, just log it
    logger.i('Notification: $title - $body');
  }
}
