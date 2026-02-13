import 'package:flutter/foundation.dart';
import 'socket_service.dart';

enum QuickCommandType {
  keyboard,
  system,
  application,
  custom,
}

class QuickCommand {
  final String id;
  final String name;
  final String description;
  final String icon;
  final QuickCommandType type;
  final Map<String, dynamic> action;
  final String? shortcut; // Keyboard shortcut to trigger
  final bool isBuiltIn;
  final int usageCount;

  QuickCommand({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.action,
    this.shortcut,
    this.isBuiltIn = false,
    this.usageCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'type': type.name,
    'action': action,
    'shortcut': shortcut,
    'isBuiltIn': isBuiltIn,
    'usageCount': usageCount,
  };

  factory QuickCommand.fromJson(Map<String, dynamic> json) => QuickCommand(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'],
    type: QuickCommandType.values.firstWhere((t) => t.name == json['type']),
    action: json['action'],
    shortcut: json['shortcut'],
    isBuiltIn: json['isBuiltIn'] ?? false,
    usageCount: json['usageCount'] ?? 0,
  );
}

class QuickCommandsService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;

  final List<QuickCommand> _commands = [];
  List<QuickCommand> get commands => List.unmodifiable(_commands);

  final List<QuickCommand> _recentCommands = [];
  List<QuickCommand> get recentCommands => List.unmodifiable(_recentCommands);

  QuickCommandsService(this._socketService, this._sessionId) {
    _initBuiltInCommands();
    _setupSocketHandlers();
  }

  void _initBuiltInCommands() {
    _commands.addAll([
      // Keyboard shortcuts
      QuickCommand(
        id: 'ctrl_alt_del',
        name: 'Ctrl+Alt+Delete',
        description: 'Send Ctrl+Alt+Delete to remote',
        icon: 'keyboard',
        type: QuickCommandType.keyboard,
        action: {'keys': ['ctrl', 'alt', 'delete']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'alt_tab',
        name: 'Alt+Tab',
        description: 'Switch windows on remote',
        icon: 'swap_horiz',
        type: QuickCommandType.keyboard,
        action: {'keys': ['alt', 'tab']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'win_d',
        name: 'Show Desktop',
        description: 'Minimize all windows (Win+D)',
        icon: 'desktop_windows',
        type: QuickCommandType.keyboard,
        action: {'keys': ['meta', 'd']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'win_l',
        name: 'Lock Screen',
        description: 'Lock the remote computer (Win+L)',
        icon: 'lock',
        type: QuickCommandType.keyboard,
        action: {'keys': ['meta', 'l']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'ctrl_shift_esc',
        name: 'Task Manager',
        description: 'Open Task Manager',
        icon: 'assessment',
        type: QuickCommandType.keyboard,
        action: {'keys': ['ctrl', 'shift', 'escape']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'print_screen',
        name: 'Screenshot',
        description: 'Take screenshot on remote',
        icon: 'screenshot',
        type: QuickCommandType.keyboard,
        action: {'keys': ['print_screen']},
        isBuiltIn: true,
      ),

      // System commands
      QuickCommand(
        id: 'open_run',
        name: 'Run Dialog',
        description: 'Open Run dialog (Win+R)',
        icon: 'terminal',
        type: QuickCommandType.system,
        action: {'keys': ['meta', 'r']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'open_explorer',
        name: 'File Explorer',
        description: 'Open File Explorer',
        icon: 'folder',
        type: QuickCommandType.system,
        action: {'keys': ['meta', 'e']},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'open_settings',
        name: 'Settings',
        description: 'Open System Settings',
        icon: 'settings',
        type: QuickCommandType.system,
        action: {'keys': ['meta', 'i']},
        isBuiltIn: true,
      ),

      // Application commands
      QuickCommand(
        id: 'open_browser',
        name: 'Open Browser',
        description: 'Launch default web browser',
        icon: 'language',
        type: QuickCommandType.application,
        action: {'launch': 'browser'},
        isBuiltIn: true,
      ),
      QuickCommand(
        id: 'open_notepad',
        name: 'Open Notepad',
        description: 'Launch Notepad',
        icon: 'edit_note',
        type: QuickCommandType.application,
        action: {'launch': 'notepad'},
        isBuiltIn: true,
      ),
    ]);
  }

  void _setupSocketHandlers() {
    _socketService.on('command-executed', (data) {
      // Handle command execution confirmation
      notifyListeners();
    });

    _socketService.on('command-result', (data) {
      // Handle command result
      notifyListeners();
    });
  }

  Future<void> executeCommand(QuickCommand command) async {
    // Track usage
    _addToRecent(command);

    // Send command to remote
    _socketService.emit('execute-quick-command', {
      'sessionId': _sessionId,
      'command': command.toJson(),
    });
  }

  void _addToRecent(QuickCommand command) {
    _recentCommands.removeWhere((c) => c.id == command.id);
    _recentCommands.insert(0, command);

    if (_recentCommands.length > 10) {
      _recentCommands.removeLast();
    }

    notifyListeners();
  }

  void addCustomCommand(QuickCommand command) {
    _commands.add(command);
    notifyListeners();
  }

  void removeCommand(String id) {
    _commands.removeWhere((c) => c.id == id && !c.isBuiltIn);
    notifyListeners();
  }

  List<QuickCommand> searchCommands(String query) {
    final lowerQuery = query.toLowerCase();
    return _commands.where((c) {
      return c.name.toLowerCase().contains(lowerQuery) ||
          c.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<QuickCommand> getCommandsByType(QuickCommandType type) {
    return _commands.where((c) => c.type == type).toList();
  }

  // Send specific key combination
  void sendKeys(List<String> keys) {
    _socketService.emit('send-keys', {
      'sessionId': _sessionId,
      'keys': keys,
    });
  }

  // Send text input
  void sendText(String text) {
    _socketService.emit('send-text', {
      'sessionId': _sessionId,
      'text': text,
    });
  }
}
