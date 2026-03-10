/// FIR (First Information Report) model
class FIR {
  final int id;
  final String caseId;
  final String firText;
  final DateTime createdAt;
  final DateTime updatedAt;

  FIR({
    required this.id,
    required this.caseId,
    required this.firText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FIR.fromJson(Map<String, dynamic> json) {
    return FIR(
      id: json['id'] as int,
      caseId: json['case_id'] as String,
      firText: json['fir_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'fir_text': firText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}