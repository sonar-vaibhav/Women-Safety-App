import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/api_config.dart';
import '../../models/backend/backend_user_model.dart';
import 'api_service.dart';

/// Service for user registration and management with backend
class BackendUserService {
  final ApiService _apiService = ApiService();

  /// Get or create user by phone number
  /// This is called during SOS trigger to get user_id
  Future<String?> getOrCreateUser(String phoneNumber) async {
    try {
      debugPrint('📱 ========== GET OR CREATE USER ==========');
      debugPrint('📱 Phone number: $phoneNumber');
      
      // Clean phone number
      final String cleanPhone = phoneNumber.toString().trim().replaceAll(' ', '');
      
      if (cleanPhone.isEmpty) {
        debugPrint('❌ ERROR: Phone number is empty!');
        return null;
      }
      
      debugPrint('✅ Validation passed');
      debugPrint('   Clean phone: "$cleanPhone"');
      
      // Build request
      final Map<String, String> requestData = {
        'phone': cleanPhone,
      };
      
      debugPrint('📤 Request data: $requestData');
      
      final response = await _apiService.post(
        ApiConfig.getOrCreateUser,
        data: requestData,
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final userId = response.data['user_id'] as String?;
        
        if (userId != null) {
          debugPrint('✅ User retrieved/created: $userId');
          debugPrint('📱 ========== GET OR CREATE USER COMPLETED ==========');
          return userId;
        } else {
          debugPrint('❌ No user_id in response');
          return null;
        }
      }
      
      debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ ========== DIO EXCEPTION ==========');
      debugPrint('❌ Error message: ${e.message}');
      debugPrint('❌ Error type: ${e.type}');
      debugPrint('❌ Response status: ${e.response?.statusCode}');
      debugPrint('❌ Response data: ${e.response?.data}');
      debugPrint('❌ ====================================');
      return null;
    } catch (e) {
      debugPrint('❌ ========== UNEXPECTED ERROR ==========');
      debugPrint('❌ Error: $e');
      debugPrint('❌ ====================================');
      return null;
    }
  }

  /// Register user with backend after Firebase authentication
  Future<BackendUser?> registerUser({
    required String name,
    required String phone,
    required String email,
  }) async {
    try {
      debugPrint('📝 ========== REGISTER USER CALLED ==========');
      debugPrint('📝 Input parameters:');
      debugPrint('   name: "$name"');
      debugPrint('   phone: "$phone"');
      debugPrint('   email: "$email"');
      
      // Clean and ensure string format - EXACTLY like Postman
      final String cleanName = name.toString().trim();
      final String cleanPhone = phone.toString().trim().replaceAll(' ', '');
      final String cleanEmail = email.toString().trim();
      
      // Validate required fields
      if (cleanName.isEmpty) {
        debugPrint('❌ ERROR: Name is empty!');
        return null;
      }
      if (cleanPhone.isEmpty) {
        debugPrint('❌ ERROR: Phone is empty!');
        return null;
      }
      if (cleanEmail.isEmpty) {
        debugPrint('❌ ERROR: Email is empty!');
        return null;
      }
      
      // Validate phone format (should start with + or digit)
      if (!cleanPhone.startsWith('+') && !RegExp(r'^\d').hasMatch(cleanPhone)) {
        debugPrint('❌ ERROR: Invalid phone format: $cleanPhone');
        return null;
      }
      
      debugPrint('✅ Validation passed');
      debugPrint('   Clean name: "$cleanName"');
      debugPrint('   Clean phone: "$cleanPhone"');
      debugPrint('   Clean email: "$cleanEmail"');
      
      // Build request EXACTLY like Postman format
      final Map<String, String> requestData = {
        'name': cleanName,
        'phone': cleanPhone,
        'email': cleanEmail,
        'device_id': 'android-safesphere-default',
      };
      
      debugPrint('📤 Request data (Postman format): $requestData');
      debugPrint('� FINAL JSON payload: $requestData');
      debugPrint('� Data type: ${requestData.runtimeType}');
      
      final response = await _apiService.post(
        ApiConfig.registerUser,
        data: requestData,
      );

      debugPrint('� Response status: ${response.statusCode}');
      debugPrint('� Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final user = BackendUser.fromJson(response.data);
        
        // Save user_id to SharedPreferences
        await _saveUserId(user.id);
        
        debugPrint('✅ User registered successfully: ${user.id}');
        debugPrint('� ========== REGISTER USER COMPLETED ==========');
        return user;
      }
      
      debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('❌ ========== DIO EXCEPTION ==========');
      debugPrint('❌ Error message: ${e.message}');
      debugPrint('❌ Error type: ${e.type}');
      debugPrint('❌ Request data sent: ${e.requestOptions.data}');
      debugPrint('❌ Request headers: ${e.requestOptions.headers}');
      debugPrint('❌ Response status: ${e.response?.statusCode}');
      debugPrint('❌ Response data: ${e.response?.data}');
      debugPrint('❌ ====================================');
      return null;
    } catch (e) {
      debugPrint('❌ ========== UNEXPECTED ERROR ==========');
      debugPrint('❌ Error: $e');
      debugPrint('❌ ====================================');
      return null;
    }
  }

  /// Get user by ID
  Future<BackendUser?> getUser(String userId) async {
    try {
      final response = await _apiService.get('${ApiConfig.getUser}/$userId');
      
      if (response.statusCode == 200) {
        return BackendUser.fromJson(response.data);
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error fetching user: ${e.message}');
      return null;
    }
  }

  /// Add trusted contact for user
  Future<bool> addTrustedContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    required String contactEmail,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.addTrustedContact,
        data: {
          'user_id': userId,
          'contact_name': contactName,
          'contact_phone': contactPhone,
          'contact_email': contactEmail,
        },
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('❌ Error adding trusted contact: ${e.message}');
      return false;
    }
  }

  /// Save user_id to SharedPreferences
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_user_id', userId);
    debugPrint('💾 Saved backend user_id: $userId');
  }

  /// Get saved user_id from SharedPreferences
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_user_id');
  }

  /// Clear saved user_id
  Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_user_id');
    debugPrint('🗑️ Cleared backend_user_id from SharedPreferences');
  }

  /// Check registration status (for debugging)
  Future<void> checkRegistrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    final userId = prefs.getString('backend_user_id');
    
    debugPrint('📊 ========== REGISTRATION STATUS ==========');
    debugPrint('📱 Phone Number: ${phoneNumber ?? "NOT SET"}');
    debugPrint('🆔 Backend User ID: ${userId ?? "NOT REGISTERED"}');
    debugPrint('� ==========================================');
  }

  /// Auto-register current logged-in user with backend
  /// COMMENTED OUT: Registration disabled for testing video recording only
  Future<BackendUser?> autoRegisterCurrentUser() async {
    try {
      debugPrint('⏭️  ========== AUTO-REGISTRATION DISABLED (COMMENTED OUT) ==========');
      debugPrint('⏭️  Skipping registration - testing video recording only');
      
      /*
      // ORIGINAL REGISTRATION CODE - COMMENTED OUT FOR TESTING
      debugPrint('? ========== AUTO-REGISTRATION STARTEnD ==========');

      // Get phone number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      debugPrint('📱 Phone number from SharedPreferences: $phoneNumber');
      debugPrint('📱 Phone number type: ${phoneNumber.runtimeType}');
      debugPrint('📱 Phone number length: ${phoneNumber?.length}');

      if (phoneNumber == null) {
        debugPrint('❌ No phone number found in SharedPreferences');
        return null;
      }

      // Check if user is already registered (but still proceed to register)
      final existingUserId = await getSavedUserId();
      if (existingUserId != null) {
        debugPrint('ℹ️ Found existing backend_user_id: $existingUserId');
        debugPrint('ℹ️ Will still attempt registration (backend handles duplicates)');
      }

      // Fetch user data from Firestore
      debugPrint('📥 Fetching user data from Firestore...');
      debugPrint('📥 Firestore path: users/$phoneNumber');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      debugPrint('📥 Document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        debugPrint('❌ User document not found in Firestore for: $phoneNumber');
        return null;
      }

      final userData = userDoc.data()!;
      debugPrint('📥 Raw Firestore data: $userData');
      
      // Convert to strings explicitly
      final String name = (userData['name'] ?? 'User').toString().trim();
      final String email = (userData['email'] ?? 'noemail@safesphere.app').toString().trim();
      final String phone = phoneNumber.toString().trim();

      // Validate data before sending
      if (name.isEmpty || name == 'User') {
        debugPrint('⚠️ Warning: Name is empty or default, using phone as name');
      }
      if (email.isEmpty || email == 'noemail@safesphere.app') {
        debugPrint('⚠️ Warning: Email is empty or default');
      }
      if (phone.isEmpty) {
        debugPrint('❌ Error: Phone number is empty');
        return null;
      }

      debugPrint('✅ Fetched and converted user data from Firestore:');
      debugPrint('   📝 Name: "$name" (type: ${name.runtimeType}, length: ${name.length})');
      debugPrint('   📱 Phone: "$phone" (type: ${phone.runtimeType}, length: ${phone.length})');
      debugPrint('   📧 Email: "$email" (type: ${email.runtimeType}, length: ${email.length})');

      // Register with backend (backend handles duplicate check)
      debugPrint('🚀 Calling backend registration API...');
      debugPrint('🚀 Parameters being sent:');
      debugPrint('   name: "$name"');
      debugPrint('   phone: "$phone"');
      debugPrint('   email: "$email"');
      
      final user = await registerUser(
        name: name,
        phone: phone,
        email: email,
      );

      if (user != null) {
        debugPrint('✅ User auto-registered successfully!');
        debugPrint('   🆔 Backend User ID: ${user.id}');
      } else {
        debugPrint('⚠️ Auto-registration returned null');
        debugPrint('   This could mean: user already exists or API error');
      }

      debugPrint('🔄 ========== AUTO-REGISTRATION COMPLETED ==========');
      return user;
      */
      
      return null; // Return null since registration is disabled
    } catch (e, stackTrace) {
      debugPrint('❌ ========== AUTO-REGISTRATION ERROR (COMMENTED OUT) ==========');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }
}
