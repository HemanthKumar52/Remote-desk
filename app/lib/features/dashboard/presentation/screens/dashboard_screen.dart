import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/services.dart';
import '../../../../models/models.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Register device on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentDeviceProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final currentDeviceAsync = ref.watch(currentDeviceProvider);
    final activeSessionsAsync = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncDesk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(devicesProvider);
              ref.invalidate(activeSessionsProvider);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  authState.valueOrNull?.user?.email ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(devicesProvider);
          ref.invalidate(activeSessionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Device Card
              currentDeviceAsync.when(
                data: (device) => _CurrentDeviceCard(device: device),
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.qr_code,
                      title: 'Host Session',
                      subtitle: 'Generate code',
                      color: AppTheme.primaryColor,
                      onTap: () => context.push('/pairing/generate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.connect_without_contact,
                      title: 'Connect',
                      subtitle: 'Enter code',
                      color: AppTheme.secondaryColor,
                      onTap: () => context.push('/pairing/connect'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // Active Sessions
              Text(
                'Active Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: 12),
              activeSessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.link_off,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No active sessions',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
                  }
                  return Column(
                    children: sessions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionCard(session: entry.value),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 400 + (entry.key * 100)),
                        duration: 400.ms,
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
              const SizedBox(height: 24),

              // My Devices
              Text(
                'My Devices',
                style: Theme.of(context).textTheme.titleLarge,
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 12),
              devicesAsync.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No devices registered',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: devices.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DeviceCard(device: entry.value),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 600 + (entry.key * 100)),
                        duration: 400.ms,
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingCard(),
                error: (e, _) => _ErrorCard(message: e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentDeviceCard extends StatelessWidget {
  final Device device;

  const _CurrentDeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  device.platformIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'This Device',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.deviceName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    device.platform.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final Session session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDevice = ref.watch(currentDeviceProvider).valueOrNull;
    final isHost = currentDevice?.id == session.hostDeviceId;

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.screen_share,
            color: AppTheme.successColor,
          ),
        ),
        title: Text(
          isHost
              ? 'Hosting: ${session.clientDevice?.deviceName ?? 'Waiting...'}'
              : 'Connected to: ${session.hostDevice?.deviceName ?? 'Unknown'}',
        ),
        subtitle: Text(
          'Started ${_formatTime(session.startedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                context.push('/session/${session.id}?host=$isHost');
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.errorColor),
              onPressed: () async {
                final sessionService = ref.read(sessionServiceProvider);
                await sessionService.endSession(session.id);
                ref.invalidate(activeSessionsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _DeviceCard extends ConsumerWidget {
  final Device device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDevice = ref.watch(currentDeviceProvider).valueOrNull;
    final isCurrentDevice = currentDevice?.id == device.id;

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (isCurrentDevice ? AppTheme.primaryColor : Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              device.platformIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(device.deviceName),
            if (isCurrentDevice) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'This device',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${device.platform.toUpperCase()} • Last active ${_formatTime(device.lastActive)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: device.isOnline
            ? Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
              )
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
