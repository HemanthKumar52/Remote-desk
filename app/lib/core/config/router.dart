import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/pairing/presentation/screens/generate_code_screen.dart';
import '../../features/pairing/presentation/screens/enter_code_screen.dart';
import '../../features/remote_session/presentation/screens/remote_session_screen.dart';
import '../../services/auth_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/pairing/generate',
        builder: (context, state) => const GenerateCodeScreen(),
      ),
      GoRoute(
        path: '/pairing/connect',
        builder: (context, state) => const EnterCodeScreen(),
      ),
      GoRoute(
        path: '/session/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final isHost = state.uri.queryParameters['host'] == 'true';
          return RemoteSessionScreen(
            sessionId: sessionId,
            isHost: isHost,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
