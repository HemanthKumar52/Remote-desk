import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../services/webrtc_service.dart';

class RemoteInputOverlay extends StatefulWidget {
  final WebRTCService webrtcService;
  final Size videoSize;
  final bool enabled;

  const RemoteInputOverlay({
    super.key,
    required this.webrtcService,
    required this.videoSize,
    this.enabled = true,
  });

  @override
  State<RemoteInputOverlay> createState() => _RemoteInputOverlayState();
}

class _RemoteInputOverlayState extends State<RemoteInputOverlay> {
  Offset? _lastPosition;
  bool _isDragging = false;

  void _normalizeAndSend(String action, Offset position, {int? button}) {
    if (!widget.enabled) return;

    // Normalize coordinates to 0-1 range
    final normalizedX = position.dx / widget.videoSize.width;
    final normalizedY = position.dy / widget.videoSize.height;

    widget.webrtcService.sendMouseEvent(
      action,
      normalizedX,
      normalizedY,
      button: button,
    );
  }

  void _onPointerHover(PointerHoverEvent event) {
    _normalizeAndSend('move', event.localPosition);
  }

  void _onPointerDown(PointerDownEvent event) {
    _lastPosition = event.localPosition;
    _isDragging = true;

    int button = 0;
    if (event.buttons & kSecondaryButton != 0) {
      button = 2; // Right button
    } else if (event.buttons & kMiddleMouseButton != 0) {
      button = 1; // Middle button
    }

    _normalizeAndSend('down', event.localPosition, button: button);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDragging) {
      _normalizeAndSend('move', event.localPosition);
    }
    _lastPosition = event.localPosition;
  }

  void _onPointerUp(PointerUpEvent event) {
    _isDragging = false;
    _normalizeAndSend('up', event.localPosition);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (!widget.enabled) return;

      final normalizedX = event.localPosition.dx / widget.videoSize.width;
      final normalizedY = event.localPosition.dy / widget.videoSize.height;

      // Send scroll event
      widget.webrtcService.sendMouseEvent(
        'scroll',
        normalizedX,
        normalizedY,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: _onPointerHover,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        cursor: widget.enabled ? SystemMouseCursors.none : SystemMouseCursors.basic,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}

class RemoteKeyboardHandler extends StatefulWidget {
  final WebRTCService webrtcService;
  final Widget child;
  final bool enabled;

  const RemoteKeyboardHandler({
    super.key,
    required this.webrtcService,
    required this.child,
    this.enabled = true,
  });

  @override
  State<RemoteKeyboardHandler> createState() => _RemoteKeyboardHandlerState();
}

class _RemoteKeyboardHandlerState extends State<RemoteKeyboardHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    final keyCode = event.logicalKey.keyId;
    final modifiers = <String>[];

    if (HardwareKeyboard.instance.isControlPressed) {
      modifiers.add('ctrl');
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      modifiers.add('shift');
    }
    if (HardwareKeyboard.instance.isAltPressed) {
      modifiers.add('alt');
    }
    if (HardwareKeyboard.instance.isMetaPressed) {
      modifiers.add('meta');
    }

    String action;
    if (event is KeyDownEvent) {
      action = 'down';
    } else if (event is KeyUpEvent) {
      action = 'up';
    } else if (event is KeyRepeatEvent) {
      action = 'repeat';
    } else {
      return KeyEventResult.ignored;
    }

    widget.webrtcService.sendKeyboardEvent(action, keyCode, modifiers: modifiers);

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
