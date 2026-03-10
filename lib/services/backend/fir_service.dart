import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/backend/fir_model.dart';
import 'api_service.dart';

/// Service for FIR (First Information Report) generation and management
class FIRService {
  final ApiService _apiService = ApiService();

  /// Generate FIR from case evidence
  Future<FIRGenerateResponse?> generateFIR({
    required String caseId,
    required String audioTranscript,
    required String videoDescription,
  }) async {
    try {
      debugPrint('📝 Generating FIR for case: $caseId');
      
      final Map<String, String> requestData = {
        'case_id': caseId,
        'audio_transcript': audioTranscript,
        'video_description': videoDescription,
      };
      
      debugPrint('📤 Request data: $requestData');
      
      final response = await _apiService.post(
        ApiConfig.generateFIR,
        data: requestData,
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final firResponse = FIRGenerateResponse.fromJson(response.data);
        debugPrint('✅ FIR generated successfully');
        debugPrint('   FIR length: ${firResponse.firText.length} characters');
        return firResponse;
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error generating FIR: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Save FIR to database
  Future<FIRSaveResponse?> saveFIR({
    required String caseId,
    required String firText,
  }) async {
    try {
      debugPrint('💾 Saving FIR for case: $caseId');
      
      final Map<String, String> requestData = {
        'case_id': caseId,
        'fir_text': firText,
      };
      
      debugPrint('📤 Request data: {case_id: $caseId, fir_text: ${firText.length} chars}');
      
      final response = await _apiService.post(
        ApiConfig.saveFIR,
        data: requestData,
      );

      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final saveResponse = FIRSaveResponse.fromJson(response.data);
        debugPrint('✅ FIR saved successfully');
        debugPrint('   FIR ID: ${saveResponse.firId}');
        return saveResponse;
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error saving FIR: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Get FIR for a case
  Future<FIR?> getFIR(String caseId) async {
    try {
      debugPrint('📄 Fetching FIR for case: $caseId');
      
      final response = await _apiService.get('${ApiConfig.getFIR}/$caseId');

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final fir = FIR.fromJson(response.data);
        debugPrint('✅ FIR retrieved successfully');
        debugPrint('   FIR ID: ${fir.id}');
        debugPrint('   Created: ${fir.createdAt}');
        return fir;
      }
      
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error fetching FIR: ${e.message}');
      debugPrint('❌ Response: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return null;
    }
  }
}
