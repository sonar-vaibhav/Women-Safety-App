import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/backend/emergency_case_model.dart';
import 'api_service.dart';

/// Service for managing emergency cases with backend
class EmergencyService {
  final ApiService _apiService = ApiService();

  /// Start a new emergency case
  Future<EmergencyCase?> startEmergency({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('🚨 Starting emergency case...');
      
      final response = await _apiService.post(
        ApiConfig.startEmergency,
        data: {
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final caseId = response.data['case_id'] as String;
        final status = response.data['status'] as String;
        
        // Save case_id to SharedPreferences for evidence upload
        await _saveCaseId(caseId);
        
        debugPrint('✅ Emergency case created: $caseId');
        
        return EmergencyCase(
          id: caseId,
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          status: status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error starting emergency: ${e.message}');
      return null;
    }
  }

  /// Get emergency case details
  Future<EmergencyCase?> getCase(String caseId) async {
    try {
      final response = await _apiService.get('${ApiConfig.getCase}/$caseId');
      
      if (response.statusCode == 200) {
        return EmergencyCase.fromJson(response.data);
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error fetching case: ${e.message}');
      return null;
    }
  }

  /// Update emergency case status
  Future<bool> updateCaseStatus({
    required String caseId,
    required String status, // active, resolved, closed
  }) async {
    try {
      final response = await _apiService.patch(
        '${ApiConfig.updateCaseStatus}/$caseId/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Case status updated to: $status');
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      debugPrint('❌ Error updating case status: ${e.message}');
      return false;
    }
  }

  /// Save case_id to SharedPreferences
  Future<void> _saveCaseId(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_case_id', caseId);
    debugPrint('💾 Saved active case_id: $caseId');
  }

  /// Get saved case_id from SharedPreferences
  Future<String?> getSavedCaseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_case_id');
  }

  /// Clear saved case_id
  Future<void> clearCaseId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_case_id');
  }
}
