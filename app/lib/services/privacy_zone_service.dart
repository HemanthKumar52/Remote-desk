import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'socket_service.dart';

enum PrivacyZoneType {
  blur,
  blackout,
  pixelate,
}

class PrivacyZone {
  final String id;
  final Rect bounds; // Normalized coordinates (0-1)
  final PrivacyZoneType type;
  final double intensity; // 0-1
  final bool isTemporary;
  final String? label;

  PrivacyZone({
    required this.id,
    required this.bounds,
    this.type = PrivacyZoneType.blur,
    this.intensity = 0.8,
    this.isTemporary = false,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'bounds': {
      'left': bounds.left,
      'top': bounds.top,
      'right': bounds.right,
      'bottom': bounds.bottom,
    },
    'type': type.name,
    'intensity': intensity,
    'isTemporary': isTemporary,
    'label': label,
  };

  factory PrivacyZone.fromJson(Map<String, dynamic> json) => PrivacyZone(
    id: json['id'],
    bounds: Rect.fromLTRB(
      json['bounds']['left'],
      json['bounds']['top'],
      json['bounds']['right'],
      json['bounds']['bottom'],
    ),
    type: PrivacyZoneType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => PrivacyZoneType.blur,
    ),
    intensity: json['intensity'] ?? 0.8,
    isTemporary: json['isTemporary'] ?? false,
    label: json['label'],
  );

  PrivacyZone copyWith({
    String? id,
    Rect? bounds,
    PrivacyZoneType? type,
    double? intensity,
    bool? isTemporary,
    String? label,
  }) => PrivacyZone(
    id: id ?? this.id,
    bounds: bounds ?? this.bounds,
    type: type ?? this.type,
    intensity: intensity ?? this.intensity,
    isTemporary: isTemporary ?? this.isTemporary,
    label: label ?? this.label,
  );
}

class PrivacyZoneService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;

  final List<PrivacyZone> _zones = [];
  List<PrivacyZone> get zones => List.unmodifiable(_zones);

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  // Predefined zones for common privacy needs
  static const Map<String, Rect> presetZones = {
    'taskbar': Rect.fromLTRB(0, 0.95, 1, 1),
    'systemTray': Rect.fromLTRB(0.8, 0.95, 1, 1),
    'dock': Rect.fromLTRB(0, 0.9, 1, 1),
  };

  PrivacyZoneService(this._socketService, this._sessionId) {
    _setupSocketHandlers();
  }

  void _setupSocketHandlers() {
    _socketService.on('privacy-zone-added', (data) {
      final zone = PrivacyZone.fromJson(data);
      _zones.add(zone);
      notifyListeners();
    });

    _socketService.on('privacy-zone-removed', (data) {
      _zones.removeWhere((z) => z.id == data['id']);
      notifyListeners();
    });

    _socketService.on('privacy-zone-updated', (data) {
      final index = _zones.indexWhere((z) => z.id == data['id']);
      if (index != -1) {
        _zones[index] = PrivacyZone.fromJson(data);
        notifyListeners();
      }
    });

    _socketService.on('privacy-zones-sync', (data) {
      _zones.clear();
      for (final zoneData in data['zones']) {
        _zones.add(PrivacyZone.fromJson(zoneData));
      }
      notifyListeners();
    });
  }

  void addZone(PrivacyZone zone) {
    _zones.add(zone);

    _socketService.emit('privacy-zone-add', {
      'sessionId': _sessionId,
      ...zone.toJson(),
    });

    notifyListeners();
  }

  void removeZone(String zoneId) {
    _zones.removeWhere((z) => z.id == zoneId);

    _socketService.emit('privacy-zone-remove', {
      'sessionId': _sessionId,
      'id': zoneId,
    });

    notifyListeners();
  }

  void updateZone(PrivacyZone zone) {
    final index = _zones.indexWhere((z) => z.id == zone.id);
    if (index != -1) {
      _zones[index] = zone;

      _socketService.emit('privacy-zone-update', {
        'sessionId': _sessionId,
        ...zone.toJson(),
      });

      notifyListeners();
    }
  }

  void addPresetZone(String presetName, {PrivacyZoneType type = PrivacyZoneType.blur}) {
    final bounds = presetZones[presetName];
    if (bounds != null) {
      addZone(PrivacyZone(
        id: '${presetName}_${DateTime.now().millisecondsSinceEpoch}',
        bounds: bounds,
        type: type,
        label: presetName,
      ));
    }
  }

  void clearTemporaryZones() {
    final tempZones = _zones.where((z) => z.isTemporary).toList();
    for (final zone in tempZones) {
      removeZone(zone.id);
    }
  }

  void clearAllZones() {
    final zoneIds = _zones.map((z) => z.id).toList();
    for (final id in zoneIds) {
      removeZone(id);
    }
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;

    _socketService.emit('privacy-zones-toggle', {
      'sessionId': _sessionId,
      'enabled': _isEnabled,
    });

    notifyListeners();
  }

  void requestSync() {
    _socketService.emit('privacy-zones-request', {
      'sessionId': _sessionId,
    });
  }

  // Check if a point is within any privacy zone
  bool isPointInZone(double x, double y) {
    if (!_isEnabled) return false;

    return _zones.any((zone) => zone.bounds.contains(Offset(x, y)));
  }

  // Get zones that contain a point
  List<PrivacyZone> getZonesAtPoint(double x, double y) {
    if (!_isEnabled) return [];

    return _zones.where((zone) => zone.bounds.contains(Offset(x, y))).toList();
  }
}
