import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'socket_service.dart';

enum VoiceChatState {
  disconnected,
  connecting,
  connected,
  muted,
}

class VoiceChatService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localAudioStream;
  MediaStream? _remoteAudioStream;

  VoiceChatState _state = VoiceChatState.disconnected;
  VoiceChatState get state => _state;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = true;
  bool get isSpeakerOn => _isSpeakerOn;

  double _inputLevel = 0;
  double get inputLevel => _inputLevel;

  VoiceChatService(this._socketService, this._sessionId);

  Future<void> startVoiceChat(String deviceId) async {
    if (_state != VoiceChatState.disconnected) return;

    _state = VoiceChatState.connecting;
    notifyListeners();

    try {
      // Get audio stream
      _localAudioStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      // Create peer connection for voice
      await _createVoicePeerConnection();

      // Add audio track
      for (final track in _localAudioStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localAudioStream!);
      }

      // Setup socket handlers
      _setupVoiceSocketHandlers();

      // Join voice chat
      _socketService.emit('voice-chat-join', {
        'sessionId': _sessionId,
        'deviceId': deviceId,
      });

      _state = VoiceChatState.connected;
      notifyListeners();

      // Start monitoring audio levels
      _startAudioLevelMonitoring();
    } catch (e) {
      print('Error starting voice chat: $e');
      _state = VoiceChatState.disconnected;
      notifyListeners();
    }
  }

  Future<void> _createVoicePeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteAudioStream = event.streams[0];
        notifyListeners();
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _socketService.emit('voice-ice-candidate', {
          'sessionId': _sessionId,
          'candidate': candidate.toMap(),
        });
      }
    };
  }

  void _setupVoiceSocketHandlers() {
    _socketService.on('voice-offer', (data) async {
      final sdp = RTCSessionDescription(
        data['sdp']['sdp'],
        data['sdp']['type'],
      );
      await _peerConnection!.setRemoteDescription(sdp);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _socketService.emit('voice-answer', {
        'sessionId': _sessionId,
        'sdp': answer.toMap(),
      });
    });

    _socketService.on('voice-answer', (data) async {
      final sdp = RTCSessionDescription(
        data['sdp']['sdp'],
        data['sdp']['type'],
      );
      await _peerConnection!.setRemoteDescription(sdp);
    });

    _socketService.on('voice-ice-candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    });

    _socketService.on('voice-peer-muted', (data) {
      // Handle remote peer mute status
      notifyListeners();
    });
  }

  void _startAudioLevelMonitoring() {
    // Monitor audio input levels for visual feedback
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state == VoiceChatState.disconnected) {
        timer.cancel();
        return;
      }
      // In a real implementation, this would analyze the audio stream
      // For now, we'll simulate audio levels
      _inputLevel = _isMuted ? 0 : 0.5;
      notifyListeners();
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;

    if (_localAudioStream != null) {
      for (final track in _localAudioStream!.getAudioTracks()) {
        track.enabled = !_isMuted;
      }
    }

    _socketService.emit('voice-mute-toggle', {
      'sessionId': _sessionId,
      'isMuted': _isMuted,
    });

    _state = _isMuted ? VoiceChatState.muted : VoiceChatState.connected;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;

    if (_remoteAudioStream != null) {
      for (final track in _remoteAudioStream!.getAudioTracks()) {
        track.enabled = _isSpeakerOn;
      }
    }

    notifyListeners();
  }

  Future<void> endVoiceChat() async {
    _socketService.emit('voice-chat-leave', {
      'sessionId': _sessionId,
    });

    _localAudioStream?.getTracks().forEach((track) => track.stop());
    _localAudioStream?.dispose();
    _remoteAudioStream?.dispose();
    _peerConnection?.close();

    _localAudioStream = null;
    _remoteAudioStream = null;
    _peerConnection = null;

    _state = VoiceChatState.disconnected;
    notifyListeners();
  }

  @override
  void dispose() {
    endVoiceChat();
    super.dispose();
  }
}
