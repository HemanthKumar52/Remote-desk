import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/models.dart';

class PairingService {
  final ApiService _apiService;

  PairingService(this._apiService);

  Future<PairCode> generateCode(String deviceId) async {
    final response = await _apiService.post('/pairing/generate', data: {
      'deviceId': deviceId,
    });
    return PairCode.fromJson(response.data);
  }

  Future<Map<String, dynamic>> connect(String code, String clientDeviceId) async {
    final response = await _apiService.post('/pairing/connect', data: {
      'code': code,
      'clientDeviceId': clientDeviceId,
    });
    return response.data;
  }
}

final pairingServiceProvider = Provider<PairingService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PairingService(apiService);
});
