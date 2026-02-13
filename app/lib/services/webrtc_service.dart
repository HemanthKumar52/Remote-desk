import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

enum WebRTCConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

class WebRTCService extends ChangeNotifier {
  final SocketService _socketService;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  RTCDataChannel? _dataChannel;

  String? _sessionId;
  bool _isHost = false;

  WebRTCConnectionState _connectionState = WebRTCConnectionState.disconnected;
  WebRTCConnectionState get connectionState => _connectionState;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  final _remoteStreamController = StreamController<MediaStream>.broadcast();
  Stream<MediaStream> get onRemoteStream => _remoteStreamController.stream;

  final _inputEventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onInputEvent => _inputEventController.stream;

  WebRTCService(this._socketService);

  Future<void> initialize(String sessionId, String deviceId, bool isHost) async {
    _sessionId = sessionId;
    _isHost = isHost;
    _connectionState = WebRTCConnectionState.connecting;
    notifyListeners();

    // Connect socket
    await _socketService.connect(deviceId);

    // Setup socket event handlers
    _setupSocketHandlers();

    // Create peer connection
    await _createPeerConnection();

    // Join session
    _socketService.joinSession(sessionId, deviceId, isHost ? 'host' : 'client');

    // If host, start capturing screen and create offer
    if (isHost) {
      await _startScreenCapture();
      await _createOffer();
    }
  }

  void _setupSocketHandlers() {
    _socketService.on('peer-joined', (data) async {
      print('Peer joined: $data');
      if (_isHost && _peerConnection != null) {
        // Recreate offer when a peer joins
        await _createOffer();
      }
    });

    _socketService.on('offer', (data) async {
      print('Received offer');
      if (!_isHost) {
        await _handleOffer(data['sdp']);
      }
    });

    _socketService.on('answer', (data) async {
      print('Received answer');
      if (_isHost) {
        await _handleAnswer(data['sdp']);
      }
    });

    _socketService.on('ice-candidate', (data) async {
      print('Received ICE candidate');
      await _handleIceCandidate(data['candidate']);
    });

    _socketService.on('input-event', (data) {
      if (_isHost) {
        _inputEventController.add(Map<String, dynamic>.from(data['event']));
      }
    });

    _socketService.on('session-ended', (_) {
      dispose();
    });
  }

  Future<void> _createPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && _sessionId != null) {
        _socketService.sendIceCandidate(_sessionId!, candidate.toMap());
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _connectionState = WebRTCConnectionState.connected;
        notifyListeners();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _connectionState = WebRTCConnectionState.failed;
        notifyListeners();
      }
    };

    _peerConnection!.onTrack = (event) {
      print('Remote track received');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
        notifyListeners();
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };

    // Create data channel for input events (if host)
    if (_isHost) {
      _dataChannel = await _peerConnection!.createDataChannel(
        'input',
        RTCDataChannelInit()..ordered = true,
      );
      _setupDataChannel();
    }
  }

  void _setupDataChannel() {
    _dataChannel?.onMessage = (message) {
      // Handle incoming data channel messages
      print('Data channel message: ${message.text}');
    };
  }

  Future<void> _startScreenCapture() async {
    try {
      final mediaConstraints = {
        'audio': false,
        'video': {
          'mandatory': {
            'minWidth': 1280,
            'minHeight': 720,
            'minFrameRate': 30,
          },
        },
      };

      // For desktop, use getDisplayMedia
      _localStream = await navigator.mediaDevices.getDisplayMedia(mediaConstraints);

      // Add tracks to peer connection
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      notifyListeners();
    } catch (e) {
      print('Error starting screen capture: $e');
      _connectionState = WebRTCConnectionState.failed;
      notifyListeners();
    }
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null || _sessionId == null) return;

    try {
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': true,
        'offerToReceiveAudio': false,
      });

      await _peerConnection!.setLocalDescription(offer);

      _socketService.sendOffer(_sessionId!, offer.toMap());
    } catch (e) {
      print('Error creating offer: $e');
    }
  }

  Future<void> _handleOffer(dynamic sdpData) async {
    if (_peerConnection == null || _sessionId == null) return;

    try {
      final sdp = RTCSessionDescription(
        sdpData['sdp'] as String,
        sdpData['type'] as String,
      );

      await _peerConnection!.setRemoteDescription(sdp);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socketService.sendAnswer(_sessionId!, answer.toMap());
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  Future<void> _handleAnswer(dynamic sdpData) async {
    if (_peerConnection == null) return;

    try {
      final sdp = RTCSessionDescription(
        sdpData['sdp'] as String,
        sdpData['type'] as String,
      );

      await _peerConnection!.setRemoteDescription(sdp);
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  Future<void> _handleIceCandidate(dynamic candidateData) async {
    if (_peerConnection == null) return;

    try {
      final candidate = RTCIceCandidate(
        candidateData['candidate'] as String,
        candidateData['sdpMid'] as String?,
        candidateData['sdpMLineIndex'] as int?,
      );

      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  void sendMouseEvent(String action, double x, double y, {int? button}) {
    if (_sessionId == null) return;

    _socketService.sendInputEvent(_sessionId!, {
      'type': 'mouse',
      'action': action,
      'data': {
        'x': x,
        'y': y,
        'button': button,
      },
    });
  }

  void sendKeyboardEvent(String action, int keyCode, {List<String>? modifiers}) {
    if (_sessionId == null) return;

    _socketService.sendInputEvent(_sessionId!, {
      'type': 'keyboard',
      'action': action,
      'data': {
        'keyCode': keyCode,
        'modifiers': modifiers ?? [],
      },
    });
  }

  void endSession() {
    if (_sessionId != null) {
      _socketService.endSession(_sessionId!);
    }
    dispose();
  }

  @override
  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _dataChannel?.close();
    _peerConnection?.close();

    _socketService.disconnect();

    _remoteStreamController.close();
    _inputEventController.close();

    _connectionState = WebRTCConnectionState.disconnected;
    super.dispose();
  }
}

final webrtcServiceProvider = ChangeNotifierProvider.autoDispose<WebRTCService>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return WebRTCService(socketService);
});
