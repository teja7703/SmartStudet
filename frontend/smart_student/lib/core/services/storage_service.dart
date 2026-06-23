import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final p = await prefs;
    await p.setString(AppConstants.userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final p = await prefs;
    final data = p.getString(AppConstants.userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearUser() async {
    final p = await prefs;
    await p.remove(AppConstants.userKey);
  }

  Future<Set<String>> getBookmarkedStories() async {
    final p = await prefs;
    return p.getStringList(AppConstants.bookmarksKey)?.toSet() ?? {};
  }

  Future<void> toggleBookmark(String storyId) async {
    final p = await prefs;
    final bookmarks = await getBookmarkedStories();
    if (bookmarks.contains(storyId)) {
      bookmarks.remove(storyId);
    } else {
      bookmarks.add(storyId);
    }
    await p.setStringList(AppConstants.bookmarksKey, bookmarks.toList());
  }

  Future<bool> isBookmarked(String storyId) async {
    final bookmarks = await getBookmarkedStories();
    return bookmarks.contains(storyId);
  }

  Future<void> saveReadProgress(String storyId, double progress) async {
    final p = await prefs;
    final key = '${AppConstants.readProgressKey}_$storyId';
    await p.setDouble(key, progress);
  }

  Future<double> getReadProgress(String storyId) async {
    final p = await prefs;
    final key = '${AppConstants.readProgressKey}_$storyId';
    return p.getDouble(key) ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.quizHistoryKey) ?? [];
    return raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<void> addQuizResult(Map<String, dynamic> result) async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.quizHistoryKey) ?? [];
    raw.insert(0, jsonEncode(result));
    // Keep only the latest 50 attempts.
    final trimmed = raw.take(50).toList();
    await p.setStringList(AppConstants.quizHistoryKey, trimmed);
  }

  Future<void> clearQuizHistory() async {
    final p = await prefs;
    await p.remove(AppConstants.quizHistoryKey);
  }

  /// Records a visited item (study material, story, etc.) for the
  /// "Your Progress" / recent activity section. Newest first, de-duplicated
  /// by type+id, capped at 30 entries.
  Future<void> recordActivity({
    required String type,
    required String id,
    required String title,
    String subtitle = '',
  }) async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.activityKey) ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => !(e['type'] == type && e['id'] == id))
        .toList();
    list.insert(0, {
      'type': type,
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'ts': DateTime.now().toIso8601String(),
    });
    final trimmed = list.take(30).map(jsonEncode).toList();
    await p.setStringList(AppConstants.activityKey, trimmed);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.activityKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearActivity() async {
    final p = await prefs;
    await p.remove(AppConstants.activityKey);
  }

  // ---- SmartGPT chat history --------------------------------------------

  Future<List<Map<String, dynamic>>> getSmartGptConversations() async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.smartGptHistoryKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// Inserts or updates a conversation (matched by id), keeping the newest
  /// first and capping the history at 50 conversations.
  Future<void> saveSmartGptConversation(
    Map<String, dynamic> conversation,
  ) async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.smartGptHistoryKey) ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => e['id'] != conversation['id'])
        .toList();
    list.insert(0, conversation);
    final trimmed = list.take(50).map(jsonEncode).toList();
    await p.setStringList(AppConstants.smartGptHistoryKey, trimmed);
  }

  Future<void> deleteSmartGptConversation(String id) async {
    final p = await prefs;
    final raw = p.getStringList(AppConstants.smartGptHistoryKey) ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => e['id'] != id)
        .map(jsonEncode)
        .toList();
    await p.setStringList(AppConstants.smartGptHistoryKey, list);
  }

  Future<void> clearSmartGptHistory() async {
    final p = await prefs;
    await p.remove(AppConstants.smartGptHistoryKey);
  }
}
