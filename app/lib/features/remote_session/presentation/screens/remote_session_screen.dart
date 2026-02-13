import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/app_config.dart';

class RemoteSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final bool isHost;

  const RemoteSessionScreen({
    super.key,
    required this.sessionId,
    required this.isHost,
  });

  @override
  ConsumerState<RemoteSessionScreen> createState() => _RemoteSessionScreenState();
}

class _RemoteSessionScreenState extends ConsumerState<RemoteSessionScreen> {
  late final WebRTCService _webrtcService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isInitialized = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  StreamSubscription? _remoteStreamSubscription;
  StreamSubscription? _inputEventSubscription;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _webrtcService = ref.read(webrtcServiceProvider);

    // Listen for remote stream
    _remoteStreamSubscription = _webrtcService.onRemoteStream.listen((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    // Listen for input events (if host)
    if (widget.isHost) {
      _inputEventSubscription = _webrtcService.onInputEvent.listen(_handleInputEvent);
    }

    // Initialize WebRTC
    await _webrtcService.initialize(
      widget.sessionId,
      AppConfig.deviceUniqueId,
      widget.isHost,
    );

    // Set local stream if host
    if (widget.isHost && _webrtcService.localStream != null) {
      _localRenderer.srcObject = _webrtcService.localStream;
    }

    setState(() => _isInitialized = true);

    _startHideControlsTimer();
  }

  void _handleInputEvent(Map<String, dynamic> event) {
    // Handle input events on the host side
    // This would typically call platform-specific code to simulate input
    print('Input event received: $event');
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onInteraction() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _webrtcService.endSession();
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _remoteStreamSubscription?.cancel();
    _inputEventSubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final webrtcState = ref.watch(webrtcServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onInteraction,
        onPanUpdate: _onInteraction,
        child: Stack(
          children: [
            // Video View
            _buildVideoView(webrtcState),

            // Controls Overlay
            if (_showControls) _buildControlsOverlay(webrtcState),

            // Connection Status
            if (webrtcState.connectionState != WebRTCConnectionState.connected)
              _buildConnectionStatus(webrtcState),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView(WebRTCService webrtcState) {
    if (widget.isHost) {
      // Host shows their own screen being shared
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.screen_share,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              'Sharing your screen',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your screen is being shared with the connected device',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // Client shows the remote screen
      return _remoteRenderer.srcObject != null
          ? RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'Waiting for screen...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
    }
  }

  Widget _buildControlsOverlay(WebRTCService webrtcState) {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: const [0.0, 0.15, 0.85, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.go('/dashboard'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isHost ? 'Hosting Session' : 'Remote Session',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              _ConnectionIndicator(
                                state: webrtcState.connectionState,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getConnectionStatusText(webrtcState.connectionState),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullscreen,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: Icons.call_end,
                      label: 'End',
                      color: AppTheme.errorColor,
                      onPressed: _endSession,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(WebRTCService webrtcState) {
    IconData icon;
    String message;
    Color color;

    switch (webrtcState.connectionState) {
      case WebRTCConnectionState.connecting:
        icon = Icons.sync;
        message = 'Connecting...';
        color = AppTheme.warningColor;
        break;
      case WebRTCConnectionState.failed:
        icon = Icons.error_outline;
        message = 'Connection failed';
        color = AppTheme.errorColor;
        break;
      case WebRTCConnectionState.disconnected:
        icon = Icons.cloud_off;
        message = 'Disconnected';
        color = Colors.grey;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (webrtcState.connectionState == WebRTCConnectionState.connecting)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                message,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getConnectionStatusText(WebRTCConnectionState state) {
    switch (state) {
      case WebRTCConnectionState.connecting:
        return 'Connecting...';
      case WebRTCConnectionState.connected:
        return 'Connected';
      case WebRTCConnectionState.failed:
        return 'Failed';
      case WebRTCConnectionState.disconnected:
        return 'Disconnected';
    }
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final WebRTCConnectionState state;

  const _ConnectionIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (state) {
      case WebRTCConnectionState.connected:
        color = AppTheme.successColor;
        break;
      case WebRTCConnectionState.connecting:
        color = AppTheme.warningColor;
        break;
      case WebRTCConnectionState.failed:
        color = AppTheme.errorColor;
        break;
      case WebRTCConnectionState.disconnected:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 28),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
