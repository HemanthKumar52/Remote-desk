import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'socket_service.dart';

class ClipboardItem {
  final String id;
  final String content;
  final String type; // text, image, file
  final String sourceDeviceId;
  final DateTime timestamp;
  final bool isPinned;

  ClipboardItem({
    required this.id,
    required this.content,
    required this.type,
    required this.sourceDeviceId,
    required this.timestamp,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type,
    'sourceDeviceId': sourceDeviceId,
    'timestamp': timestamp.toIso8601String(),
    'isPinned': isPinned,
  };

  factory ClipboardItem.fromJson(Map<String, dynamic> json) => ClipboardItem(
    id: json['id'],
    content: json['content'],
    type: json['type'],
    sourceDeviceId: json['sourceDeviceId'],
    timestamp: DateTime.parse(json['timestamp']),
    isPinned: json['isPinned'] ?? false,
  );
}

class ClipboardSyncService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;
  final String _deviceId;

  final List<ClipboardItem> _history = [];
  List<ClipboardItem> get history => List.unmodifiable(_history);

  String? _lastClipboardContent;
  Timer? _clipboardMonitor;
  bool _isSyncEnabled = true;
  bool get isSyncEnabled => _isSyncEnabled;

  static const int maxHistorySize = 50;

  ClipboardSyncService(this._socketService, this._sessionId, this._deviceId) {
    _setupSocketHandlers();
    _startClipboardMonitoring();
  }

  void _setupSocketHandlers() {
    _socketService.on('clipboard-sync', (data) {
      final item = ClipboardItem.fromJson(data);

      // Don't add our own clipboard items
      if (item.sourceDeviceId == _deviceId) return;

      _addToHistory(item);

      // Auto-paste to local clipboard if sync is enabled
      if (_isSyncEnabled && item.type == 'text') {
        Clipboard.setData(ClipboardData(text: item.content));
        _lastClipboardContent = item.content;
      }

      notifyListeners();
    });

    _socketService.on('clipboard-history', (data) {
      final items = (data as List)
          .map((json) => ClipboardItem.fromJson(json))
          .toList();
      _history.clear();
      _history.addAll(items);
      notifyListeners();
    });
  }

  void _startClipboardMonitoring() {
    _clipboardMonitor = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _checkClipboard(),
    );
  }

  Future<void> _checkClipboard() async {
    if (!_isSyncEnabled) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final content = data?.text;

      if (content != null && content != _lastClipboardContent && content.isNotEmpty) {
        _lastClipboardContent = content;
        _sendClipboardContent(content);
      }
    } catch (e) {
      // Clipboard access may fail on some platforms
    }
  }

  void _sendClipboardContent(String content) {
    final item = ClipboardItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: 'text',
      sourceDeviceId: _deviceId,
      timestamp: DateTime.now(),
    );

    _addToHistory(item);

    _socketService.emit('clipboard-sync', {
      'sessionId': _sessionId,
      ...item.toJson(),
    });

    notifyListeners();
  }

  void _addToHistory(ClipboardItem item) {
    // Remove duplicate if exists
    _history.removeWhere((i) => i.content == item.content && !i.isPinned);

    // Add to beginning
    _history.insert(0, item);

    // Keep only last maxHistorySize items (excluding pinned)
    final pinnedItems = _history.where((i) => i.isPinned).toList();
    final unpinnedItems = _history.where((i) => !i.isPinned).toList();

    if (unpinnedItems.length > maxHistorySize) {
      unpinnedItems.removeRange(maxHistorySize, unpinnedItems.length);
    }

    _history.clear();
    _history.addAll([...pinnedItems, ...unpinnedItems]);
  }

  void pasteFromHistory(ClipboardItem item) {
    Clipboard.setData(ClipboardData(text: item.content));
    _lastClipboardContent = item.content;

    // Send to sync
    _socketService.emit('clipboard-sync', {
      'sessionId': _sessionId,
      ...item.toJson(),
    });
  }

  void togglePin(String itemId) {
    final index = _history.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = _history[index];
      _history[index] = ClipboardItem(
        id: item.id,
        content: item.content,
        type: item.type,
        sourceDeviceId: item.sourceDeviceId,
        timestamp: item.timestamp,
        isPinned: !item.isPinned,
      );
      notifyListeners();
    }
  }

  void deleteFromHistory(String itemId) {
    _history.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void clearHistory() {
    _history.removeWhere((i) => !i.isPinned);
    notifyListeners();
  }

  void toggleSync() {
    _isSyncEnabled = !_isSyncEnabled;
    notifyListeners();
  }

  void requestHistory() {
    _socketService.emit('get-clipboard-history', {
      'sessionId': _sessionId,
    });
  }

  @override
  void dispose() {
    _clipboardMonitor?.cancel();
    super.dispose();
  }
}
