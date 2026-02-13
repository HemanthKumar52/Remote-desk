import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../services/services.dart';
import '../../../../core/theme/app_theme.dart';

class EnterCodeScreen extends ConsumerStatefulWidget {
  const EnterCodeScreen({super.key});

  @override
  ConsumerState<EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends ConsumerState<EnterCodeScreen> {
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  bool get _isCodeComplete => _code.length == 6;

  Future<void> _connect() async {
    if (!_isCodeComplete) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentDevice = await ref.read(currentDeviceProvider.future);
      final pairingService = ref.read(pairingServiceProvider);
      final result = await pairingService.connect(_code, currentDevice.id);

      if (mounted) {
        final sessionId = result['sessionId'] as String;
        context.go('/session/$sessionId?host=false');
      }
    } catch (e) {
      setState(() {
        _error = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('404') || message.contains('invalid')) {
      return 'Invalid pairing code';
    }
    if (message.contains('expired')) {
      return 'Pairing code has expired';
    }
    if (message.contains('used')) {
      return 'Pairing code has already been used';
    }
    return 'Failed to connect. Please try again.';
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Handle paste
    if (value.length > 1) {
      final code = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < code.length && i < 6; i++) {
        _codeControllers[i].text = code[i];
      }
      if (code.length >= 6) {
        _focusNodes[5].requestFocus();
      }
    }

    setState(() {});

    if (_isCodeComplete) {
      _connect();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace &&
          _codeControllers[index].text.isEmpty &&
          index > 0) {
        _focusNodes[index - 1].requestFocus();
        _codeControllers[index - 1].clear();
      }
    }
  }

  void _clearCode() {
    for (final controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.connect_without_contact_rounded,
                  size: 80,
                  color: AppTheme.secondaryColor,
                ).animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                ),
                const SizedBox(height: 32),
                Text(
                  'Enter Pairing Code',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code from the host device',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                const SizedBox(height: 48),

                // Code Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == 2 ? 16 : 0,
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 64,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _onKeyPressed(index, event),
                          child: TextField(
                            controller: _codeControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: _error != null
                                  ? AppTheme.errorColor.withValues(alpha: 0.1)
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: _error != null
                                    ? const BorderSide(color: AppTheme.errorColor, width: 2)
                                    : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: _error != null
                                    ? const BorderSide(color: AppTheme.errorColor, width: 2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _error != null ? AppTheme.errorColor : AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _onCodeChanged(index, value),
                          ),
                        ),
                      ),
                    );
                  }),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 24),

                // Error Message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).shake(),

                const SizedBox(height: 24),

                // Loading or Connect Button
                if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Connecting...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms)
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isCodeComplete ? _connect : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                          child: const Text('Connect'),
                        ),
                      ),
                      if (_code.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _clearCode,
                          child: const Text('Clear'),
                        ),
                      ],
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
                              'How to get a code',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ask the person whose computer you want to control to:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        _InstructionStep(
                          number: '1',
                          text: 'Open SyncDesk on their computer',
                        ),
                        _InstructionStep(
                          number: '2',
                          text: 'Click "Host Session" to generate a code',
                        ),
                        _InstructionStep(
                          number: '3',
                          text: 'Share the 6-digit code with you',
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
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
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
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
