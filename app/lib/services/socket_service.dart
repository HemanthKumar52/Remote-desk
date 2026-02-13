import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';

class SocketService {
  io.Socket? _socket;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Map<String, List<Function(dynamic)>> _eventHandlers = {};

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect(String deviceId) async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      throw Exception('No auth token available');
    }

    _socket = io.io(
      '${AppConfig.socketUrl}/signaling',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .setQuery({'deviceId': deviceId})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected');
      _notifyHandlers('connected', null);
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      _notifyHandlers('disconnected', null);
    });

    _socket!.onError((error) {
      print('Socket error: $error');
      _notifyHandlers('error', error);
    });

    // Set up event forwarding
    _setupEventForwarding();
  }

  void _setupEventForwarding() {
    final events = [
      'peer-joined',
      'peer-left',
      'peer-disconnected',
      'offer',
      'answer',
      'ice-candidate',
      'input-event',
      'file-transfer-request',
      'file-transfer-accept',
      'file-chunk',
      'session-ended',
    ];

    for (final event in events) {
      _socket!.on(event, (data) => _notifyHandlers(event, data));
    }
  }

  void _notifyHandlers(String event, dynamic data) {
    final handlers = _eventHandlers[event];
    if (handlers != null) {
      for (final handler in handlers) {
        handler(data);
      }
    }
  }

  void on(String event, Function(dynamic) handler) {
    _eventHandlers.putIfAbsent(event, () => []);
    _eventHandlers[event]!.add(handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _eventHandlers[event]?.remove(handler);
    } else {
      _eventHandlers.remove(event);
    }
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  Future<Map<String, dynamic>?> emitWithAck(String event, dynamic data) async {
    if (_socket == null) return null;

    final completer = <String, dynamic>{};
    _socket!.emitWithAck(event, data, ack: (response) {
      if (response is Map) {
        completer.addAll(Map<String, dynamic>.from(response));
      }
    });

    // Wait a bit for the response
    await Future.delayed(const Duration(milliseconds: 100));
    return completer.isEmpty ? null : completer;
  }

  void joinSession(String sessionId, String deviceId, String role) {
    emit('join-session', {
      'sessionId': sessionId,
      'deviceId': deviceId,
      'role': role,
    });
  }

  void leaveSession(String sessionId) {
    emit('leave-session', {'sessionId': sessionId});
  }

  void sendOffer(String sessionId, dynamic sdp) {
    emit('offer', {'sessionId': sessionId, 'data': sdp});
  }

  void sendAnswer(String sessionId, dynamic sdp) {
    emit('answer', {'sessionId': sessionId, 'data': sdp});
  }

  void sendIceCandidate(String sessionId, dynamic candidate) {
    emit('ice-candidate', {'sessionId': sessionId, 'candidate': candidate});
  }

  void sendInputEvent(String sessionId, Map<String, dynamic> event) {
    emit('input-event', {'sessionId': sessionId, 'event': event});
  }

  void endSession(String sessionId) {
    emit('session-ended', {'sessionId': sessionId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _eventHandlers.clear();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
