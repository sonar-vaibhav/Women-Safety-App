/// Backend evidence model matching Django evidence_evidence table
class Evidence {
  final int id;
  final String caseId;
  final String fileType; // video or audio
  final String fileUrl;
  final String originalFilename;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final DateTime createdAt;

  Evidence({
    required this.id,
    required this.caseId,
    required this.fileType,
    required this.fileUrl,
    required this.originalFilename,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.createdAt,
  });

  factory Evidence.fromJson(Map<String, dynamic> json) {
    return Evidence(
      id: json['id'] as int,
      caseId: json['case_id'] as String,
      fileType: json['file_type'] as String,
      fileUrl: json['file_url'] as String,
      originalFilename: json['original_filename'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Response model for evidence upload
class EvidenceUploadResponse {
  final String message;
  final String caseId;
  final List<UploadedFile> uploadedFiles;

  EvidenceUploadResponse({
    required this.message,
    required this.caseId,
    required this.uploadedFiles,
  });

  factory EvidenceUploadResponse.fromJson(Map<String, dynamic> json) {
    return EvidenceUploadResponse(
      message: json['message'] as String,
      caseId: json['case_id'] as String,
      uploadedFiles: (json['uploaded_files'] as List)
          .map((file) => UploadedFile.fromJson(file as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UploadedFile {
  final String fileType;
  final String fileUrl;

  UploadedFile({
    required this.fileType,
    required this.fileUrl,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      fileType: json['file_type'] as String,
      fileUrl: json['file_url'] as String,
    );
  }
}
