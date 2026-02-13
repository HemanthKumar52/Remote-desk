import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/models.dart';

class SessionService {
  final ApiService _apiService;

  SessionService(this._apiService);

  Future<Session> getSession(String sessionId) async {
    final response = await _apiService.get('/sessions/$sessionId');
    return Session.fromJson(response.data);
  }

  Future<List<Session>> getActiveSessions() async {
    final response = await _apiService.get('/sessions/active');
    return (response.data as List)
        .map((json) => Session.fromJson(json))
        .toList();
  }

  Future<List<Session>> getSessionHistory({int limit = 10}) async {
    final response = await _apiService.get(
      '/sessions/history',
      queryParameters: {'limit': limit},
    );
    return (response.data as List)
        .map((json) => Session.fromJson(json))
        .toList();
  }

  Future<void> endSession(String sessionId) async {
    await _apiService.delete('/sessions/$sessionId');
  }
}

final sessionServiceProvider = Provider<SessionService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SessionService(apiService);
});

final activeSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getActiveSessions();
});

final sessionHistoryProvider = FutureProvider<List<Session>>((ref) async {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getSessionHistory();
});
