import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../models/models.dart';

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        await _loadUser();
      } else {
        state = AsyncValue.data(AuthState());
      }
    } catch (e) {
      state = AsyncValue.data(AuthState());
    }
  }

  Future<void> _loadUser() async {
    try {
      final response = await _apiService.get('/users/me');
      final user = User.fromJson(response.data);
      state = AsyncValue.data(AuthState(isAuthenticated: true, user: user));
    } catch (e) {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      state = AsyncValue.data(AuthState());
    }
  }

  Future<void> register(String email, String password) async {
    state = AsyncValue.data(state.valueOrNull?.copyWith(isLoading: true) ?? AuthState(isLoading: true));

    try {
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
      });

      final tokens = AuthTokens.fromJson(response.data);
      await _saveTokens(tokens);
      await _loadUser();
    } catch (e) {
      state = AsyncValue.data(state.valueOrNull?.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      ) ?? AuthState(error: _getErrorMessage(e)));
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = AsyncValue.data(state.valueOrNull?.copyWith(isLoading: true) ?? AuthState(isLoading: true));

    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final tokens = AuthTokens.fromJson(response.data);
      await _saveTokens(tokens);
      await _loadUser();
    } catch (e) {
      state = AsyncValue.data(state.valueOrNull?.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      ) ?? AuthState(error: _getErrorMessage(e)));
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    state = AsyncValue.data(AuthState());
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _storage.write(key: 'access_token', value: tokens.accessToken);
    await _storage.write(key: 'refresh_token', value: tokens.refreshToken);
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('409')) {
      return 'Email already registered';
    }
    if (error.toString().contains('401')) {
      return 'Invalid credentials';
    }
    return 'An error occurred. Please try again.';
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
