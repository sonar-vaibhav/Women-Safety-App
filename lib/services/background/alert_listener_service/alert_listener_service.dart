import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:developer' as developer;

class AlertListenerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Timer? _pollingTimer;
  static Set<String> _shownAlertIds = {}; // Track shown alerts to avoid duplicates

  /// Start polling for Track Me alerts every 3 seconds
  static Future<void> startPollingForAlerts() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('phoneNumber');

      if (currentUserPhone == null) {
        developer.log('Phone number not found');
        return;
      }

      developer.log('Starting polling for alerts for: $currentUserPhone');

      // Poll every 3 seconds
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _checkForNewAlerts(currentUserPhone);
      });

      // Also check immediately
      await _checkForNewAlerts(currentUserPhone);
    } catch (e) {
      developer.log('Error starting alert polling: $e');
    }
  }

  /// Check for new Track Me alerts from emergency contacts
  static Future<void> _checkForNewAlerts(String currentUserPhone) async {
    try {
      // Get list of contacts who added this user
      final userDoc = await _firestore.collection('users').doc(currentUserPhone).get();
      final userData = userDoc.data() ?? {};
      final emergencyContactOf = userData['emergency_contact_of'] as List<dynamic>? ?? [];

      developer.log('Checking alerts for $currentUserPhone. Emergency contacts: $emergencyContactOf');

      if (emergencyContactOf.isEmpty) {
        developer.log('No emergency contacts found for $currentUserPhone');
        return;
      }

      // Check each contact's alerts
      for (final contactPhone in emergencyContactOf) {
        await _checkContactAlerts(contactPhone.toString(), currentUserPhone);
      }
    } catch (e) {
      developer.log('Error checking for alerts: $e');
    }
  }

  /// Check a specific contact's alerts
  static Future<void> _checkContactAlerts(
      String contactPhone, String currentUserPhone) async {
    try {
      developer.log('Checking alerts from contact: $contactPhone for user: $currentUserPhone');

      final snapshot = await _firestore
          .collection('users')
          .doc(contactPhone)
          .collection('alerts')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: 'trackMe')
          .get();

      developer.log('Found ${snapshot.docs.length} active trackMe alerts from $contactPhone');

      for (final doc in snapshot.docs) {
        final alertId = doc.id;

        // Skip if already shown
        if (_shownAlertIds.contains(alertId)) {
          developer.log('Alert $alertId already shown, skipping');
          continue;
        }

        final alert = doc.data();
        final alertedContacts = alert['alerted_contacts'] as List<dynamic>? ?? [];

        developer.log('Alert $alertId has ${alertedContacts.length} alerted contacts');

        // Check if current user is in alerted contacts
        final isCurrentUserAlerted = alertedContacts.any((contact) {
          final contactNumber = contact['contact_number'] ?? '';
          developer.log('Checking if $currentUserPhone matches $contactNumber');
          return contactNumber == currentUserPhone;
        });

        if (isCurrentUserAlerted) {
          developer.log('✅ New Track Me alert detected from $contactPhone for $currentUserPhone');
          _shownAlertIds.add(alertId); // Mark as shown
          await _showTrackMeNotification(contactPhone, alert, alertId);
        } else {
          developer.log('❌ Current user $currentUserPhone not in alerted contacts');
        }
      }
    } catch (e) {
      developer.log('Error checking contact alerts: $e');
    }
  }

  /// Show local notification for Track Me alert
  static Future<void> _showTrackMeNotification(
      String contactPhone, Map<String, dynamic> alert, String alertId) async {
    try {
      // Get contact name from alert
      final alertedContacts = alert['alerted_contacts'] as List<dynamic>? ?? [];
      String contactName = 'Unknown';

      for (final contact in alertedContacts) {
        if (contact['contact_number'] == contactPhone) {
          contactName = contact['contact_name'] ?? 'Unknown';
          break;
        }
      }

      // Get duration
      final trackMeLimit = alert['track_me_limit'] ?? '1';
      String duration = '1 hour';
      if (trackMeLimit == '8') duration = '8 hours';
      if (trackMeLimit == 'always') duration = 'unlimited';

      // Show notification
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'track_me_channel',
        'Track Me Alerts',
        channelDescription: 'Notifications for Track Me alerts',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        alertId.hashCode,
        '📍 Location Sharing Started',
        '$contactName is sharing their location for $duration. Tap to view.',
        notificationDetails,
        payload: 'trackMe:$contactPhone:$alertId',
      );

      developer.log('✅ Notification shown for $contactName');
    } catch (e) {
      developer.log('Error showing notification: $e');
    }
  }

  /// Stop polling for alerts
  static Future<void> stopPollingForAlerts() async {
    _pollingTimer?.cancel();
    _shownAlertIds.clear();
    developer.log('Stopped polling for alerts');
  }

  /// Reset shown alerts (useful for testing)
  static void resetShownAlerts() {
    _shownAlertIds.clear();
    developer.log('Reset shown alerts');
  }
}
