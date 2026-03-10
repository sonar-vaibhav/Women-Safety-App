import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/backend/evidence_model.dart';
import 'api_service.dart';

/// Service for uploading video and audio evidence to backend
class EvidenceService {
  final ApiService _apiService = ApiService();

  /// Upload video and/or audio evidence
  Future<EvidenceUploadResponse?> uploadEvidence({
    required String caseId,
    String? videoFilePath,
    String? audioFilePath,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (videoFilePath == null && audioFilePath == null) {
        debugPrint('⚠️ No files to upload');
        return null;
      }

      debugPrint('📤 Uploading evidence...');
      debugPrint('  Case ID: $caseId');
      if (videoFilePath != null) debugPrint('  Video: $videoFilePath');
      if (audioFilePath != null) debugPrint('  Audio: $audioFilePath');

      // Create multipart form data
      final formData = FormData.fromMap({
        'case_id': caseId,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        if (videoFilePath != null)
          'video_file': await MultipartFile.fromFile(
            videoFilePath,
            filename: videoFilePath.split('/').last,
          ),
        if (audioFilePath != null)
          'audio_file': await MultipartFile.fromFile(
            audioFilePath,
            filename: audioFilePath.split('/').last,
          ),
      });

      // Upload with progress tracking
      final response = await _apiService.uploadMultipart(
        ApiConfig.uploadEvidence,
        formData,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(0);
          debugPrint('📊 Upload progress: $progress%');
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final uploadResponse = EvidenceUploadResponse.fromJson(response.data);
        debugPrint('✅ Evidence uploaded successfully');
        debugPrint('  Uploaded files: ${uploadResponse.uploadedFiles.length}');
        return uploadResponse;
      }

      return null;
    } on DioException catch (e) {
      debugPrint('❌ Error uploading evidence: ${e.message}');
      if (e.response != null) {
        debugPrint('Response: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return null;
    }
  }

  /// Get all evidence for a case
  Future<List<Evidence>> getEvidence(String caseId) async {
    try {
      final response = await _apiService.get('${ApiConfig.getEvidence}/$caseId');

      if (response.statusCode == 200) {
        final List<dynamic> evidenceList = response.data as List;
        return evidenceList
            .map((json) => Evidence.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint('❌ Error fetching evidence: ${e.message}');
      return [];
    }
  }

  /// Validate file exists before upload
  Future<bool> validateFile(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();
      
      if (!exists) {
        debugPrint('❌ File does not exist: $filePath');
        return false;
      }

      final size = await file.length();
      debugPrint('✓ File validated: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error validating file: $e');
      return false;
    }
  }
}
