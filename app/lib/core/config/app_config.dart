import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class AppConfig {
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';

  static late String deviceUniqueId;
  static late String deviceName;
  static late String platform;

  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  static Future<void> initialize() async {
    await _initializeDeviceInfo();
  }

  static Future<void> _initializeDeviceInfo() async {
    // Try to get existing device ID
    String? existingId = await _storage.read(key: 'device_unique_id');

    if (existingId != null) {
      deviceUniqueId = existingId;
    } else {
      // Generate new device ID
      deviceUniqueId = _uuid.v4();
      await _storage.write(key: 'device_unique_id', value: deviceUniqueId);
    }

    // Get device info
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      deviceName = info.computerName;
      platform = 'windows';
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      deviceName = info.computerName;
      platform = 'macos';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      deviceName = info.prettyName;
      platform = 'linux';
    } else if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      deviceName = info.model;
      platform = 'android';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      deviceName = info.name;
      platform = 'ios';
    } else {
      deviceName = 'Unknown Device';
      platform = 'unknown';
    }
  }
}
