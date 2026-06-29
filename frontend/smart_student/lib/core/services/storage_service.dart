import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Local key/value cache.
///
/// IMPORTANT: every per-user value (quiz history, recent activity, SmartGPT
/// chats, bookmarks, read progress) is stored under a key that is **namespaced
/// by the active Firebase UID**, so two accounts on the same device never see
/// each other's cached data. The backend remains the source of truth; these
/// keys are an offline cache only.
///
/// Call [setActiveUser] right after a user is resolved (login / app start) and
/// [clearActiveUserCache] on logout.
class StorageService {
  SharedPreferences? _prefs;

  /// The Firebase UID the cache is currently scoped to. Empty when nobody is
  /// signed in.
  String _activeUid = '';

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  void setActiveUser(String? uid) {
    _activeUid = (uid ?? '').trim();
  }

  String get activeUid => _activeUid;

  /// Returns [baseKey] namespaced by the active user, e.g.
  /// `quiz_history__<uid>`. Falls back to an `__anon` namespace when signed out.
  String _scoped(String baseKey) {
    final uid = _activeUid.isEmpty ? '__anon' : _activeUid;
    return '${baseKey}__$uid';
  }

  // ---- Session user (the "who is logged in" pointer) --------------------
  // Kept global; replaced on each login and removed on logout.

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

  // ---- Bookmarks (per user) ---------------------------------------------

  Future<Set<String>> getBookmarkedStories() async {
    final p = await prefs;
    return p.getStringList(_scoped(AppConstants.bookmarksKey))?.toSet() ?? {};
  }

  Future<void> toggleBookmark(String storyId) async {
    final p = await prefs;
    final bookmarks = await getBookmarkedStories();
    if (bookmarks.contains(storyId)) {
      bookmarks.remove(storyId);
    } else {
      bookmarks.add(storyId);
    }
    await p.setStringList(
      _scoped(AppConstants.bookmarksKey),
      bookmarks.toList(),
    );
  }

  Future<bool> isBookmarked(String storyId) async {
    final bookmarks = await getBookmarkedStories();
    return bookmarks.contains(storyId);
  }

  // ---- Read progress (per user, per story) ------------------------------

  Future<void> saveReadProgress(String storyId, double progress) async {
    final p = await prefs;
    final key = '${_scoped(AppConstants.readProgressKey)}_$storyId';
    await p.setDouble(key, progress);
  }

  Future<double> getReadProgress(String storyId) async {
    final p = await prefs;
    final key = '${_scoped(AppConstants.readProgressKey)}_$storyId';
    return p.getDouble(key) ?? 0.0;
  }

  // ---- Quiz history (per user) ------------------------------------------

  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.quizHistoryKey)) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> addQuizResult(Map<String, dynamic> result) async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.quizHistoryKey)) ?? [];
    raw.insert(0, jsonEncode(result));
    final trimmed = raw.take(50).toList();
    await p.setStringList(_scoped(AppConstants.quizHistoryKey), trimmed);
  }

  /// Replaces the cached quiz history (used when syncing from the backend).
  Future<void> setQuizHistory(List<Map<String, dynamic>> results) async {
    final p = await prefs;
    final raw = results.take(50).map(jsonEncode).toList();
    await p.setStringList(_scoped(AppConstants.quizHistoryKey), raw);
  }

  Future<void> clearQuizHistory() async {
    final p = await prefs;
    await p.remove(_scoped(AppConstants.quizHistoryKey));
  }

  // ---- Recent activity (per user) ---------------------------------------

  Future<void> recordActivity({
    required String type,
    required String id,
    required String title,
    String subtitle = '',
  }) async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.activityKey)) ?? [];
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
    await p.setStringList(_scoped(AppConstants.activityKey), trimmed);
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.activityKey)) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearActivity() async {
    final p = await prefs;
    await p.remove(_scoped(AppConstants.activityKey));
  }

  // ---- SmartGPT chat history (per user) ---------------------------------

  Future<List<Map<String, dynamic>>> getSmartGptConversations() async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.smartGptHistoryKey)) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> saveSmartGptConversation(
    Map<String, dynamic> conversation,
  ) async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.smartGptHistoryKey)) ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => e['id'] != conversation['id'])
        .toList();
    list.insert(0, conversation);
    final trimmed = list.take(50).map(jsonEncode).toList();
    await p.setStringList(_scoped(AppConstants.smartGptHistoryKey), trimmed);
  }

  /// Replaces the cached conversations (used when syncing from the backend).
  Future<void> setSmartGptConversations(
    List<Map<String, dynamic>> conversations,
  ) async {
    final p = await prefs;
    final raw = conversations.take(50).map(jsonEncode).toList();
    await p.setStringList(_scoped(AppConstants.smartGptHistoryKey), raw);
  }

  Future<void> deleteSmartGptConversation(String id) async {
    final p = await prefs;
    final raw = p.getStringList(_scoped(AppConstants.smartGptHistoryKey)) ?? [];
    final list = raw
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .where((e) => e['id'] != id)
        .map(jsonEncode)
        .toList();
    await p.setStringList(_scoped(AppConstants.smartGptHistoryKey), list);
  }

  Future<void> clearSmartGptHistory() async {
    final p = await prefs;
    await p.remove(_scoped(AppConstants.smartGptHistoryKey));
  }

  // ---- Logout cleanup ---------------------------------------------------

  /// Removes the session pointer plus every cached value belonging to the
  /// currently active user. Call this on logout so the next account starts
  /// completely clean.
  Future<void> clearActiveUserCache() async {
    final p = await prefs;
    await p.remove(AppConstants.userKey);
    await p.remove(_scoped(AppConstants.bookmarksKey));
    await p.remove(_scoped(AppConstants.quizHistoryKey));
    await p.remove(_scoped(AppConstants.activityKey));
    await p.remove(_scoped(AppConstants.smartGptHistoryKey));

    // Read-progress is one key per story — remove every key in this user's
    // read-progress namespace.
    final readPrefix = _scoped(AppConstants.readProgressKey);
    for (final key in p.getKeys()) {
      if (key.startsWith(readPrefix)) {
        await p.remove(key);
      }
    }
  }
}
