import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/models.dart';
import '../core/config/app_config.dart';

class DeviceService {
  final ApiService _apiService;

  DeviceService(this._apiService);

  Future<Device> registerDevice() async {
    final response = await _apiService.post('/devices/register', data: {
      'deviceName': AppConfig.deviceName,
      'platform': AppConfig.platform,
      'deviceUniqueId': AppConfig.deviceUniqueId,
    });
    return Device.fromJson(response.data);
  }

  Future<List<Device>> getDevices() async {
    final response = await _apiService.get('/devices');
    return (response.data as List)
        .map((json) => Device.fromJson(json))
        .toList();
  }

  Future<void> deleteDevice(String deviceId) async {
    await _apiService.delete('/devices/$deviceId');
  }
}

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DeviceService(apiService);
});

final devicesProvider = FutureProvider<List<Device>>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.getDevices();
});

final currentDeviceProvider = FutureProvider<Device>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return deviceService.registerDevice();
});
