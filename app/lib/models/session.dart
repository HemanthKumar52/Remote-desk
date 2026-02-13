import 'device.dart';

class Session {
  final String id;
  final String hostDeviceId;
  final String? clientDeviceId;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Device? hostDevice;
  final Device? clientDevice;

  Session({
    required this.id,
    required this.hostDeviceId,
    this.clientDeviceId,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.hostDevice,
    this.clientDevice,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      hostDeviceId: json['hostDeviceId'] as String,
      clientDeviceId: json['clientDeviceId'] as String?,
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      hostDevice: json['hostDevice'] != null
          ? Device.fromJson(json['hostDevice'] as Map<String, dynamic>)
          : null,
      clientDevice: json['clientDevice'] != null
          ? Device.fromJson(json['clientDevice'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isEnded => status == 'ended';
}
