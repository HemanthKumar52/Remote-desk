import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration
  await AppConfig.initialize();

  runApp(
    const ProviderScope(
      child: SyncDeskApp(),
    ),
  );
}

class SyncDeskApp extends ConsumerWidget {
  const SyncDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SyncDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
