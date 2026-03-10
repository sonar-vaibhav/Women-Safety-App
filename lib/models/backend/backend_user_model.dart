/// Backend user model matching Django users_user table
class BackendUser {
  final String id; // UUID
  final String name;
  final String phone;
  final String email;
  final String? deviceId;
  final DateTime createdAt;

  BackendUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.deviceId,
    required this.createdAt,
  });

  factory BackendUser.fromJson(Map<String, dynamic> json) {
    return BackendUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      deviceId: json['device_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      if (deviceId != null) 'device_id': deviceId,
    };
  }
}
