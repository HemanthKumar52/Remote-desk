import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionBookmark {
  final String id;
  final String sessionId;
  final String title;
  final String? description;
  final DateTime timestamp;
  final Uint8List? thumbnail; // Screenshot thumbnail
  final Map<String, dynamic>? metadata;
  final List<String> tags;

  SessionBookmark({
    required this.id,
    required this.sessionId,
    required this.title,
    this.description,
    required this.timestamp,
    this.thumbnail,
    this.metadata,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'thumbnail': thumbnail != null ? base64Encode(thumbnail!) : null,
    'metadata': metadata,
    'tags': tags,
  };

  factory SessionBookmark.fromJson(Map<String, dynamic> json) => SessionBookmark(
    id: json['id'],
    sessionId: json['sessionId'],
    title: json['title'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    thumbnail: json['thumbnail'] != null ? base64Decode(json['thumbnail']) : null,
    metadata: json['metadata'],
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class SessionBookmarksService extends ChangeNotifier {
  static const String _storageKey = 'session_bookmarks';

  final List<SessionBookmark> _bookmarks = [];
  List<SessionBookmark> get bookmarks => List.unmodifiable(_bookmarks);

  SessionBookmarksService() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      _bookmarks.clear();
      _bookmarks.addAll(
        jsonList.map((json) => SessionBookmark.fromJson(json)).toList(),
      );
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<SessionBookmark> createBookmark({
    required String sessionId,
    required String title,
    String? description,
    Uint8List? thumbnail,
    Map<String, dynamic>? metadata,
    List<String> tags = const [],
  }) async {
    final bookmark = SessionBookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      thumbnail: thumbnail,
      metadata: metadata,
      tags: tags,
    );

    _bookmarks.insert(0, bookmark);
    await _saveBookmarks();
    notifyListeners();

    return bookmark;
  }

  Future<void> updateBookmark(SessionBookmark bookmark) async {
    final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark;
      await _saveBookmarks();
      notifyListeners();
    }
  }

  Future<void> deleteBookmark(String id) async {
    _bookmarks.removeWhere((b) => b.id == id);
    await _saveBookmarks();
    notifyListeners();
  }

  List<SessionBookmark> getBookmarksForSession(String sessionId) {
    return _bookmarks.where((b) => b.sessionId == sessionId).toList();
  }

  List<SessionBookmark> searchBookmarks(String query) {
    final lowerQuery = query.toLowerCase();
    return _bookmarks.where((b) {
      return b.title.toLowerCase().contains(lowerQuery) ||
          (b.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          b.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<SessionBookmark> getBookmarksByTag(String tag) {
    return _bookmarks.where((b) => b.tags.contains(tag)).toList();
  }

  Set<String> getAllTags() {
    return _bookmarks.expand((b) => b.tags).toSet();
  }

  Future<void> clearAllBookmarks() async {
    _bookmarks.clear();
    await _saveBookmarks();
    notifyListeners();
  }

  Future<String> exportBookmarks() async {
    return jsonEncode(_bookmarks.map((b) => b.toJson()).toList());
  }

  Future<void> importBookmarks(String jsonData) async {
    final List<dynamic> jsonList = jsonDecode(jsonData);
    final imported = jsonList.map((json) => SessionBookmark.fromJson(json)).toList();

    for (final bookmark in imported) {
      if (!_bookmarks.any((b) => b.id == bookmark.id)) {
        _bookmarks.add(bookmark);
      }
    }

    await _saveBookmarks();
    notifyListeners();
  }
}
