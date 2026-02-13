class PairCode {
  final String code;
  final DateTime expiresAt;
  final String deviceId;

  PairCode({
    required this.code,
    required this.expiresAt,
    required this.deviceId,
  });

  factory PairCode.fromJson(Map<String, dynamic> json) {
    return PairCode(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      deviceId: json['deviceId'] as String,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}
