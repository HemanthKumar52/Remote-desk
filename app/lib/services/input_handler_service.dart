import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InputEvent {
  final String type; // 'mouse' or 'keyboard'
  final String action;
  final Map<String, dynamic> data;

  InputEvent({
    required this.type,
    required this.action,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'action': action,
      'data': data,
    };
  }

  factory InputEvent.fromJson(Map<String, dynamic> json) {
    return InputEvent(
      type: json['type'] as String,
      action: json['action'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}

class InputHandlerService {
  static const MethodChannel _channel = MethodChannel('com.syncdesk/input');

  // Mouse event actions
  static const String mouseMove = 'move';
  static const String mouseDown = 'down';
  static const String mouseUp = 'up';
  static const String mouseClick = 'click';
  static const String mouseDoubleClick = 'doubleClick';
  static const String mouseScroll = 'scroll';

  // Keyboard event actions
  static const String keyDown = 'down';
  static const String keyUp = 'up';
  static const String keyPress = 'press';

  // Create mouse move event
  static InputEvent createMouseMove(double x, double y) {
    return InputEvent(
      type: 'mouse',
      action: mouseMove,
      data: {'x': x, 'y': y},
    );
  }

  // Create mouse click event
  static InputEvent createMouseClick(double x, double y, {int button = 0}) {
    return InputEvent(
      type: 'mouse',
      action: mouseClick,
      data: {'x': x, 'y': y, 'button': button},
    );
  }

  // Create mouse down event
  static InputEvent createMouseDown(double x, double y, {int button = 0}) {
    return InputEvent(
      type: 'mouse',
      action: mouseDown,
      data: {'x': x, 'y': y, 'button': button},
    );
  }

  // Create mouse up event
  static InputEvent createMouseUp(double x, double y, {int button = 0}) {
    return InputEvent(
      type: 'mouse',
      action: mouseUp,
      data: {'x': x, 'y': y, 'button': button},
    );
  }

  // Create mouse scroll event
  static InputEvent createMouseScroll(double x, double y, double deltaX, double deltaY) {
    return InputEvent(
      type: 'mouse',
      action: mouseScroll,
      data: {'x': x, 'y': y, 'deltaX': deltaX, 'deltaY': deltaY},
    );
  }

  // Create keyboard event
  static InputEvent createKeyEvent(String action, int keyCode, {List<String>? modifiers}) {
    return InputEvent(
      type: 'keyboard',
      action: action,
      data: {
        'keyCode': keyCode,
        'modifiers': modifiers ?? [],
      },
    );
  }

  // Simulate input on host side (platform-specific)
  Future<void> simulateInput(InputEvent event) async {
    try {
      await _channel.invokeMethod('simulateInput', event.toJson());
    } on PlatformException catch (e) {
      debugPrint('Failed to simulate input: ${e.message}');
    }
  }

  // Simulate mouse move
  Future<void> simulateMouseMove(double x, double y) async {
    await simulateInput(createMouseMove(x, y));
  }

  // Simulate mouse click
  Future<void> simulateMouseClick(double x, double y, {int button = 0}) async {
    await simulateInput(createMouseClick(x, y, button: button));
  }

  // Simulate key press
  Future<void> simulateKeyPress(int keyCode, {List<String>? modifiers}) async {
    await simulateInput(createKeyEvent(keyPress, keyCode, modifiers: modifiers));
  }
}

// Extension to convert pointer events to normalized coordinates
extension PointerEventNormalizer on Offset {
  Map<String, double> toNormalized(Size screenSize) {
    return {
      'x': dx / screenSize.width,
      'y': dy / screenSize.height,
    };
  }
}
