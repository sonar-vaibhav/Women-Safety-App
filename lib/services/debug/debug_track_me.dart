import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class DebugTrackMe {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug function to check Track Me setup
  static Future<void> debugTrackMeSetup() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('phoneNumber');

      developer.log('=== DEBUG TRACK ME SETUP ===');
      developer.log('Current user phone: $currentUserPhone');

      if (currentUserPhone == null) {
        developer.log('❌ ERROR: Phone number not found in SharedPreferences');
        return;
      }

      // Check current user's document
      final userDoc = await _firestore.collection('users').doc(currentUserPhone).get();
      
      if (!userDoc.exists) {
        developer.log('❌ ERROR: User document does not exist');
        return;
      }

      final userData = userDoc.data() ?? {};
      developer.log('✅ User document exists');

      // Check emergency_contacts
      final emergencyContacts = userData['emergency_contacts'] as List<dynamic>? ?? [];
      developer.log('Emergency contacts (${emergencyContacts.length}):');
      for (var contact in emergencyContacts) {
        developer.log('  - ${contact['name']}: ${contact['number']}');
      }

      // Check emergency_contact_of
      final emergencyContactOf = userData['emergency_contact_of'] as List<dynamic>? ?? [];
      developer.log('Emergency contact of (${emergencyContactOf.length}):');
      for (var phone in emergencyContactOf) {
        developer.log('  - $phone');
      }

      // Check for active Track Me alerts
      final alertsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserPhone)
          .collection('alerts')
          .where('isActive', isEqualTo: true)
          .where('type', isEqualTo: 'trackMe')
          .get();

      developer.log('Active Track Me alerts: ${alertsSnapshot.docs.length}');
      for (var doc in alertsSnapshot.docs) {
        final alert = doc.data();
        final alertedContacts = alert['alerted_contacts'] as List<dynamic>? ?? [];
        developer.log('  Alert ${doc.id}:');
        developer.log('    Alerted contacts: ${alertedContacts.length}');
        for (var contact in alertedContacts) {
          developer.log('      - ${contact['contact_name']}: ${contact['contact_number']}');
        }
      }

      // Check if contacts have alerts for current user
      developer.log('Checking contacts for alerts...');
      for (var contactPhone in emergencyContactOf) {
        final contactAlertsSnapshot = await _firestore
            .collection('users')
            .doc(contactPhone.toString())
            .collection('alerts')
            .where('isActive', isEqualTo: true)
            .where('type', isEqualTo: 'trackMe')
            .get();

        developer.log('Contact $contactPhone has ${contactAlertsSnapshot.docs.length} active alerts');
        
        for (var doc in contactAlertsSnapshot.docs) {
          final alert = doc.data();
          final alertedContacts = alert['alerted_contacts'] as List<dynamic>? ?? [];
          
          // Check if current user is in alerted contacts
          final isCurrentUserAlerted = alertedContacts.any((contact) {
            return contact['contact_number'] == currentUserPhone;
          });

          developer.log('  Alert ${doc.id}: Current user alerted? $isCurrentUserAlerted');
          if (!isCurrentUserAlerted) {
            developer.log('    Alerted contacts:');
            for (var contact in alertedContacts) {
              developer.log('      - ${contact['contact_number']} (expected: $currentUserPhone)');
            }
          }
        }
      }

      developer.log('=== END DEBUG ===');
    } catch (e) {
      developer.log('❌ ERROR in debug: $e');
    }
  }
}
