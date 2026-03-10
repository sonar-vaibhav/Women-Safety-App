import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ManualAlertCheckService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Manually check for Track Me alerts from emergency contacts
  static Future<Map<String, dynamic>?> checkForTrackMeAlerts(
      BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('phoneNumber');

      if (currentUserPhone == null) {
        developer.log('Phone number not found');
        _showSnackBar(context, '❌ User not logged in', Colors.red);
        return null;
      }

      developer.log('Checking for alerts for: $currentUserPhone');

      // Get current user's emergency contacts
      final userDoc =
          await _firestore.collection('users').doc(currentUserPhone).get();
      final userData = userDoc.data() ?? {};
      final emergencyContacts =
          userData['emergency_contacts'] as List<dynamic>? ?? [];

      if (emergencyContacts.isEmpty) {
        developer.log('No emergency contacts found');
        _showSnackBar(
            context, 'ℹ️ No emergency contacts added', Colors.blue);
        return null;
      }

      developer.log('Checking ${emergencyContacts.length} contacts for alerts');

      // Check each contact's alerts
      for (final contact in emergencyContacts) {
        final contactPhone = contact['emergency_contact_number'] ?? '';
        if (contactPhone.isEmpty) continue;

        final alert = await _checkContactAlerts(contactPhone, currentUserPhone);
        if (alert != null) {
          return alert;
        }
      }

      _showSnackBar(context, 'ℹ️ No active alerts found', Colors.blue);
      return null;
    } catch (e) {
      developer.log('Error checking for alerts: $e');
      _showSnackBar(context, '❌ Error checking alerts: $e', Colors.red);
      return null;
    }
  }

  /// Check a specific contact's alerts
  static Future<Map<String, dynamic>?> _checkContactAlerts(
      String contactPhone, String currentUserPhone) async {
    try {
      developer.log('Checking alerts from contact: $contactPhone');

      final snapshot = await _firestore
          .collection('users')
          .doc(contactPhone)
          .collection('alerts')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: 'trackMe')
          .get();

      developer.log('Found ${snapshot.docs.length} active alerts from $contactPhone');

      for (final doc in snapshot.docs) {
        final alert = doc.data();
        final alertedContacts = alert['alerted_contacts'] as List<dynamic>? ?? [];

        developer.log('Alert ${doc.id} has ${alertedContacts.length} alerted contacts');

        // Check if current user is in alerted contacts
        final isCurrentUserAlerted = alertedContacts.any((contact) {
          final contactNumber = contact['contact_number'] ?? '';
          developer.log('  Comparing: $currentUserPhone == $contactNumber');
          return contactNumber == currentUserPhone;
        });

        if (isCurrentUserAlerted) {
          developer.log('✅ Found alert from $contactPhone for $currentUserPhone');

          // Get the person who CREATED the alert (contactPhone) - their name and profile pic
          String contactName = 'Unknown';
          String contactProfilePic = 'assets/placeholders/default_profile_pic.png';
          
          // Get from the person who created the alert's Firestore document
          final contactDoc =
              await _firestore.collection('users').doc(contactPhone).get();
          if (contactDoc.exists) {
            final contactData = contactDoc.data() ?? {};
            developer.log('Contact data: $contactData');
            
            // Check all possible name fields
            contactName = contactData['name'] ?? 
                         contactData['fullName'] ?? 
                         contactData['userName'] ?? 
                         contactData['email']?.toString().split('@')[0] ??
                         'Unknown';
            
            developer.log('Found contact name: $contactName');
          } else {
            developer.log('Contact document does not exist for: $contactPhone');
          }

          developer.log('Final contact name: $contactName');

          return {
            'alertId': doc.id,
            'contactPhone': contactPhone,
            'contactName': contactName,
            'contactProfilePic': contactProfilePic,
            'alert': alert,
          };
        } else {
          developer.log('❌ Current user $currentUserPhone not in alerted contacts');
        }
      }

      return null;
    } catch (e) {
      developer.log('Error checking contact alerts: $e');
      return null;
    }
  }

  /// Show snackbar message
  static void _showSnackBar(
      BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
