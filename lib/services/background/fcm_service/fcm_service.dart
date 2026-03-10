import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and save token to Firestore
  static Future<void> initializeFCM() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('User granted permission: ${settings.authorizationStatus}');

      // Get and save FCM token
      await _saveFCMToken();

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        developer.log('FCM Token refreshed: $newToken');
        _saveFCMToken();
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Received foreground message: ${message.notification?.title}');
      });

      // Handle background message tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Message opened app: ${message.notification?.title}');
      });

      developer.log('FCM initialized successfully');
    } catch (e) {
      developer.log('Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Firestore
  static Future<void> _saveFCMToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) {
        developer.log('Phone number not found in preferences');
        return;
      }

      final token = await _firebaseMessaging.getToken();

      if (token == null) {
        developer.log('FCM token is null');
        return;
      }

      developer.log('Saving FCM token: $token for user: $phoneNumber');

      // Get user document
      final userDocRef = _firestore.collection('users').doc(phoneNumber);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        developer.log('User document does not exist');
        return;
      }

      // Add token to fcmTokens array (avoid duplicates)
      await userDocRef.update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

      developer.log('FCM token saved successfully');
    } catch (e) {
      developer.log('Error saving FCM token: $e');
    }
  }

  /// Remove FCM token on logout
  static Future<void> removeFCMToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(phoneNumber).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      developer.log('FCM token removed successfully');
    } catch (e) {
      developer.log('Error removing FCM token: $e');
    }
  }
}
