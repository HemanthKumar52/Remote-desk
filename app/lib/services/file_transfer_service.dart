import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'socket_service.dart';

enum FileTransferState {
  idle,
  requesting,
  sending,
  receiving,
  completed,
  failed,
}

class FileTransferProgress {
  final String fileName;
  final int fileSize;
  final int transferredBytes;
  final FileTransferState state;
  final String? error;

  FileTransferProgress({
    required this.fileName,
    required this.fileSize,
    required this.transferredBytes,
    required this.state,
    this.error,
  });

  double get progress => fileSize > 0 ? transferredBytes / fileSize : 0;
  bool get isComplete => state == FileTransferState.completed;
  bool get isFailed => state == FileTransferState.failed;
}

class FileTransferService extends ChangeNotifier {
  final SocketService _socketService;
  final String _sessionId;

  FileTransferState _state = FileTransferState.idle;
  String? _currentFileName;
  int _currentFileSize = 0;
  int _transferredBytes = 0;
  String? _error;

  final List<Uint8List> _receivedChunks = [];
  int _expectedChunks = 0;
  int _receivedChunkCount = 0;

  static const int chunkSize = 64 * 1024; // 64KB chunks

  FileTransferService(this._socketService, this._sessionId) {
    _setupEventHandlers();
  }

  FileTransferProgress get progress => FileTransferProgress(
    fileName: _currentFileName ?? '',
    fileSize: _currentFileSize,
    transferredBytes: _transferredBytes,
    state: _state,
    error: _error,
  );

  void _setupEventHandlers() {
    _socketService.on('file-transfer-request', _onFileTransferRequest);
    _socketService.on('file-transfer-accept', _onFileTransferAccept);
    _socketService.on('file-chunk', _onFileChunk);
  }

  void _onFileTransferRequest(dynamic data) {
    _currentFileName = data['fileName'] as String;
    _currentFileSize = data['fileSize'] as int;
    _state = FileTransferState.requesting;
    notifyListeners();
  }

  void _onFileTransferAccept(dynamic data) {
    // Start sending the file
    _state = FileTransferState.sending;
    notifyListeners();
  }

  void _onFileChunk(dynamic data) {
    if (_state != FileTransferState.receiving) {
      _state = FileTransferState.receiving;
    }

    final chunkIndex = data['chunkIndex'] as int;
    final totalChunks = data['totalChunks'] as int;
    final chunkData = base64Decode(data['data'] as String);

    if (_expectedChunks == 0) {
      _expectedChunks = totalChunks;
      _receivedChunks.clear();
      for (int i = 0; i < totalChunks; i++) {
        _receivedChunks.add(Uint8List(0));
      }
    }

    _receivedChunks[chunkIndex] = chunkData;
    _receivedChunkCount++;
    _transferredBytes = _receivedChunkCount * chunkSize;

    notifyListeners();

    if (_receivedChunkCount == _expectedChunks) {
      _completeReceive();
    }
  }

  Future<void> _completeReceive() async {
    try {
      final bytes = _receivedChunks.expand((chunk) => chunk).toList();
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_currentFileName');
      await file.writeAsBytes(bytes);

      _state = FileTransferState.completed;
      notifyListeners();
    } catch (e) {
      _state = FileTransferState.failed;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendFile(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileSize = await file.length();
      final bytes = await file.readAsBytes();

      _currentFileName = fileName;
      _currentFileSize = fileSize;
      _transferredBytes = 0;
      _state = FileTransferState.requesting;
      notifyListeners();

      // Request file transfer
      _socketService.emit('file-transfer-request', {
        'sessionId': _sessionId,
        'fileName': fileName,
        'fileSize': fileSize,
      });

      // Wait for acceptance (in real implementation, would wait for response)
      await Future.delayed(const Duration(milliseconds: 500));

      _state = FileTransferState.sending;
      notifyListeners();

      // Split file into chunks
      final totalChunks = (bytes.length / chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final start = i * chunkSize;
        final end = (start + chunkSize > bytes.length) ? bytes.length : start + chunkSize;
        final chunk = bytes.sublist(start, end);

        _socketService.emit('file-chunk', {
          'sessionId': _sessionId,
          'fileName': fileName,
          'fileSize': fileSize,
          'chunkIndex': i,
          'totalChunks': totalChunks,
          'data': base64Encode(chunk),
        });

        _transferredBytes = end;
        notifyListeners();

        // Small delay to prevent overwhelming
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _state = FileTransferState.completed;
      notifyListeners();
    } catch (e) {
      _state = FileTransferState.failed;
      _error = e.toString();
      notifyListeners();
    }
  }

  void acceptTransfer() {
    _state = FileTransferState.receiving;
    _receivedChunks.clear();
    _receivedChunkCount = 0;
    _expectedChunks = 0;
    _transferredBytes = 0;

    _socketService.emit('file-transfer-accept', {
      'sessionId': _sessionId,
      'fileName': _currentFileName,
    });

    notifyListeners();
  }

  void rejectTransfer() {
    _state = FileTransferState.idle;
    _currentFileName = null;
    _currentFileSize = 0;
    notifyListeners();
  }

  void reset() {
    _state = FileTransferState.idle;
    _currentFileName = null;
    _currentFileSize = 0;
    _transferredBytes = 0;
    _error = null;
    _receivedChunks.clear();
    _receivedChunkCount = 0;
    _expectedChunks = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.off('file-transfer-request');
    _socketService.off('file-transfer-accept');
    _socketService.off('file-chunk');
    super.dispose();
  }
}
