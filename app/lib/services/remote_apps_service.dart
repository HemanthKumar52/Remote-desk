import 'package:flutter/foundation.dart';
import 'socket_service.dart';

class RemoteApp {
  final String id;
  final String name;
  final String path;
  final String? iconBase64;
  final String? category;
  final bool isPinned;
  final int launchCount;
  final DateTime? lastLaunched;

  RemoteApp({
    required this.id,
    required this.name,
    required this.path,
    this.iconBase64,
    this.category,
    this.isPinned = false,
    this.launchCount = 0,
    this.lastLaunched,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'iconBase64': iconBase64,
    'category': category,
    'isPinned': isPinned,
    'launchCount': launchCount,
    'lastLaunched': lastLaunched?.toIso8601String(),
  };

  factory RemoteApp.fromJson(Map<String, dynamic> json) => RemoteApp(
    id: json['id'],
    name: json['name'],
    path: json['path'],
    iconBase64: json['iconBase64'],
    category: json['category'],
    isPinned: json['isPinned'] ?? false,
    launchCount: json['launchCount'] ?? 0,
    lastLaunched: json['lastLaunched'] != null
        ? DateTime.parse(json['lastLaunched'])
        : null,
  );

  RemoteApp copyWith({
    String? id,
    String? name,
    String? path,
    String? iconBase64,
    String? category,
    bool? isPinned,
    int? launchCount,
    DateTime? lastLaunched,
  }) => RemoteApp(
    id: id ?? this.id,
    name: name ?? this.name,
    path: path ?? this.path,
    iconBase64: iconBase64 ?? this.iconBase64,
    category: category ?? this.category,
    isPinned: isPinned ?? this.isPinned,
    launchCount: launchCount ?? this.launchCount,
    lastLaunched: lastLaunched ?? this.lastLaunched,
  );
}

class RemoteAppsService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;

  final List<RemoteApp> _apps = [];
  List<RemoteApp> get apps => List.unmodifiable(_apps);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  RemoteAppsService(this._socketService, this._sessionId) {
    _setupSocketHandlers();
  }

  void _setupSocketHandlers() {
    _socketService.on('apps-list', (data) {
      _apps.clear();
      for (final appData in data['apps']) {
        _apps.add(RemoteApp.fromJson(appData));
      }
      _isLoading = false;
      notifyListeners();
    });

    _socketService.on('app-launched', (data) {
      final index = _apps.indexWhere((a) => a.id == data['appId']);
      if (index != -1) {
        final app = _apps[index];
        _apps[index] = app.copyWith(
          launchCount: app.launchCount + 1,
          lastLaunched: DateTime.now(),
        );
        notifyListeners();
      }
    });

    _socketService.on('app-launch-error', (data) {
      _error = data['error'];
      notifyListeners();
    });
  }

  void requestAppsList() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _socketService.emit('get-apps-list', {
      'sessionId': _sessionId,
    });
  }

  Future<void> launchApp(RemoteApp app) async {
    _error = null;

    _socketService.emit('launch-app', {
      'sessionId': _sessionId,
      'appId': app.id,
      'path': app.path,
    });
  }

  void togglePin(String appId) {
    final index = _apps.indexWhere((a) => a.id == appId);
    if (index != -1) {
      final app = _apps[index];
      _apps[index] = app.copyWith(isPinned: !app.isPinned);
      notifyListeners();
    }
  }

  List<RemoteApp> get pinnedApps => _apps.where((a) => a.isPinned).toList();

  List<RemoteApp> get recentApps {
    final sorted = _apps.where((a) => a.lastLaunched != null).toList()
      ..sort((a, b) => b.lastLaunched!.compareTo(a.lastLaunched!));
    return sorted.take(10).toList();
  }

  List<RemoteApp> get frequentApps {
    final sorted = _apps.where((a) => a.launchCount > 0).toList()
      ..sort((a, b) => b.launchCount.compareTo(a.launchCount));
    return sorted.take(10).toList();
  }

  List<String> get categories {
    return _apps
        .where((a) => a.category != null)
        .map((a) => a.category!)
        .toSet()
        .toList();
  }

  List<RemoteApp> getAppsByCategory(String category) {
    return _apps.where((a) => a.category == category).toList();
  }

  List<RemoteApp> searchApps(String query) {
    final lowerQuery = query.toLowerCase();
    return _apps.where((a) {
      return a.name.toLowerCase().contains(lowerQuery) ||
          a.path.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  void launchCustomPath(String path) {
    _socketService.emit('launch-custom-path', {
      'sessionId': _sessionId,
      'path': path,
    });
  }

  void openUrl(String url) {
    _socketService.emit('open-url', {
      'sessionId': _sessionId,
      'url': url,
    });
  }
}
