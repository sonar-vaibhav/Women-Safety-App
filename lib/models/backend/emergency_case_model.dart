/// Backend emergency case model matching Django emergency_case table
class EmergencyCase {
  final String id; // UUID
  final String userId;
  final double latitude;
  final double longitude;
  final String status; // active, resolved, closed
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyCase({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyCase.fromJson(Map<String, dynamic> json) {
    return EmergencyCase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
