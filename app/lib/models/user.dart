class User {
  final String id;
  final String email;
  final DateTime createdAt;
  final int deviceCount;

  User({
    required this.id,
    required this.email,
    required this.createdAt,
    this.deviceCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deviceCount: json['_count']?['devices'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
