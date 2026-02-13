class Device {
  final String id;
  final String userId;
  final String deviceName;
  final String platform;
  final String deviceUniqueId;
  final DateTime lastActive;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.platform,
    required this.deviceUniqueId,
    required this.lastActive,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      userId: json['userId'] as String,
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
      deviceUniqueId: json['deviceUniqueId'] as String,
      lastActive: DateTime.parse(json['lastActive'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceName': deviceName,
      'platform': platform,
      'deviceUniqueId': deviceUniqueId,
      'lastActive': lastActive.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get platformIcon {
    switch (platform) {
      case 'windows':
        return '🪟';
      case 'macos':
        return '🍎';
      case 'linux':
        return '🐧';
      case 'android':
        return '🤖';
      case 'ios':
        return '📱';
      default:
        return '💻';
    }
  }

  bool get isOnline {
    return DateTime.now().difference(lastActive).inMinutes < 5;
  }
}
