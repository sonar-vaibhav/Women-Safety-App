import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class FixEmergencyContactOf {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fix emergency_contact_of field for current user and their contacts
  static Future<void> fixBidirectionalRelationship() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final currentUserPhone = prefs.getString('phoneNumber');

      if (currentUserPhone == null) {
        developer.log('❌ Phone number not found');
        return;
      }

      developer.log('=== FIXING BIDIRECTIONAL RELATIONSHIP ===');
      developer.log('Current user: $currentUserPhone');

      // Get current user's document
      final userDoc = await _firestore.collection('users').doc(currentUserPhone).get();
      
      if (!userDoc.exists) {
        developer.log('❌ User document does not exist');
        return;
      }

      final userData = userDoc.data() ?? {};
      final emergencyContacts = userData['emergency_contacts'] as List<dynamic>? ?? [];

      developer.log('Found ${emergencyContacts.length} emergency contacts');

      // For each emergency contact, add current user to their emergency_contact_of
      for (var contact in emergencyContacts) {
        final contactNumber = contact['emergency_contact_number'] ?? 
                             contact['contact_number'] ?? '';
        
        if (contactNumber.isEmpty) continue;

        developer.log('Processing contact: $contactNumber');

        try {
          final contactDocRef = _firestore.collection('users').doc(contactNumber);
          final contactDoc = await contactDocRef.get();

          if (!contactDoc.exists) {
            developer.log('  ⚠️ Contact document does not exist, creating...');
            await contactDocRef.set({
              'phone': contactNumber,
              'emergency_contact_of': [currentUserPhone],
            }, SetOptions(merge: true));
            developer.log('  ✅ Created contact document with emergency_contact_of');
          } else {
            // Update existing document
            final contactData = contactDoc.data() ?? {};
            final emergencyContactOf = contactData['emergency_contact_of'] as List<dynamic>? ?? [];
            
            if (!emergencyContactOf.contains(currentUserPhone)) {
              await contactDocRef.update({
                'emergency_contact_of': FieldValue.arrayUnion([currentUserPhone]),
              });
              developer.log('  ✅ Added $currentUserPhone to emergency_contact_of');
            } else {
              developer.log('  ℹ️ Already in emergency_contact_of');
            }
          }

          // Also check if contact has current user in their emergency_contacts
          // If yes, add contact to current user's emergency_contact_of
          if (contactDoc.exists) {
            final contactData = contactDoc.data() ?? {};
            final contactEmergencyContacts = contactData['emergency_contacts'] as List<dynamic>? ?? [];
            
            final hasCurrentUser = contactEmergencyContacts.any((c) {
              final num = c['emergency_contact_number'] ?? c['contact_number'] ?? '';
              return num == currentUserPhone;
            });

            if (hasCurrentUser) {
              developer.log('  ℹ️ Contact has current user in their emergency_contacts');
              
              // Add contact to current user's emergency_contact_of
              final currentUserData = userDoc.data() ?? {};
              final currentUserEmergencyContactOf = currentUserData['emergency_contact_of'] as List<dynamic>? ?? [];
              
              if (!currentUserEmergencyContactOf.contains(contactNumber)) {
                await _firestore.collection('users').doc(currentUserPhone).update({
                  'emergency_contact_of': FieldValue.arrayUnion([contactNumber]),
                });
                developer.log('  ✅ Added $contactNumber to current user emergency_contact_of');
              }
            }
          }
        } catch (e) {
          developer.log('  ❌ Error processing contact $contactNumber: $e');
        }
      }

      developer.log('=== FIX COMPLETE ===');
      developer.log('✅ Bidirectional relationship fixed!');
      
      // Verify the fix
      await _verifyFix(currentUserPhone);
      
    } catch (e) {
      developer.log('❌ Error fixing relationship: $e');
    }
  }

  /// Verify the fix worked
  static Future<void> _verifyFix(String currentUserPhone) async {
    try {
      developer.log('=== VERIFYING FIX ===');
      
      final userDoc = await _firestore.collection('users').doc(currentUserPhone).get();
      final userData = userDoc.data() ?? {};
      
      final emergencyContactOf = userData['emergency_contact_of'] as List<dynamic>? ?? [];
      developer.log('Current user emergency_contact_of: $emergencyContactOf');
      
      if (emergencyContactOf.isEmpty) {
        developer.log('⚠️ emergency_contact_of is still empty');
      } else {
        developer.log('✅ emergency_contact_of has ${emergencyContactOf.length} entries');
      }
      
    } catch (e) {
      developer.log('❌ Error verifying: $e');
    }
  }
}
