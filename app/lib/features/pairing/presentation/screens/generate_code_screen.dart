import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/services.dart';
import '../../../../models/models.dart';
import '../../../../core/theme/app_theme.dart';

class GenerateCodeScreen extends ConsumerStatefulWidget {
  const GenerateCodeScreen({super.key});

  @override
  ConsumerState<GenerateCodeScreen> createState() => _GenerateCodeScreenState();
}

class _GenerateCodeScreenState extends ConsumerState<GenerateCodeScreen> {
  PairCode? _pairCode;
  bool _isLoading = true;
  String? _error;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentDevice = await ref.read(currentDeviceProvider.future);
      final pairingService = ref.read(pairingServiceProvider);
      final pairCode = await pairingService.generateCode(currentDevice.id);

      setState(() {
        _pairCode = pairCode;
        _isLoading = false;
        _remainingTime = pairCode.timeRemaining;
      });

      _startCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pairCode == null) {
        timer.cancel();
        return;
      }

      final remaining = _pairCode!.timeRemaining;
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
        });
      } else {
        setState(() {
          _remainingTime = remaining;
        });
      }
    });
  }

  void _copyCode() {
    if (_pairCode != null) {
      Clipboard.setData(ClipboardData(text: _pairCode!.code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text('Generating pairing code...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Error generating code',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _generateCode,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    final isExpired = _remainingTime.isNegative || _remainingTime == Duration.zero;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.screen_share_rounded,
          size: 80,
          color: AppTheme.primaryColor,
        ).animate().fadeIn(duration: 600.ms).scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
        ),
        const SizedBox(height: 32),
        Text(
          'Your Pairing Code',
          style: Theme.of(context).textTheme.headlineMedium,
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 8),
        Text(
          'Share this code with the device you want to control this computer',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
        const SizedBox(height: 32),

        // Code Display
        GestureDetector(
          onTap: isExpired ? null : _copyCode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.grey.withValues(alpha: 0.2)
                  : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpired
                    ? Colors.grey.withValues(alpha: 0.3)
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatCode(_pairCode!.code),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: isExpired ? Colors.grey : null,
                  ),
                ),
                if (!isExpired) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.copy,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
        ),
        const SizedBox(height: 24),

        // Countdown
        if (isExpired)
          Column(
            children: [
              const Icon(
                Icons.timer_off,
                size: 32,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Code expired',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generateCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate New Code'),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms)
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                color: _remainingTime.inSeconds <= 60
                    ? AppTheme.warningColor
                    : AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Expires in ${_formatDuration(_remainingTime)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _remainingTime.inSeconds <= 60
                      ? AppTheme.warningColor
                      : null,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

        const SizedBox(height: 48),

        // Instructions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InstructionStep(
                  number: '1',
                  text: 'Share this code with the person who wants to connect',
                ),
                _InstructionStep(
                  number: '2',
                  text: 'They enter the code in SyncDesk on their device',
                ),
                _InstructionStep(
                  number: '3',
                  text: 'Your screen will be shared and they can control it',
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  String _formatCode(String code) {
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    }
    return code;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
