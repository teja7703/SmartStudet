import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../quizzes/models/quiz_result_model.dart';
import '../models/progress_stats.dart';

/// Loads the signed-in user's progress from the backend (the source of truth,
/// scoped by Firebase UID) and records activity. Falls back to the local cache
/// when the network is unavailable so the screen still shows something offline.
class ProgressRepository {
  final ApiClient _apiClient;
  final StorageService _storage;

  ProgressRepository({
    required ApiClient apiClient,
    required StorageService storage,
  })  : _apiClient = apiClient,
        _storage = storage;

  Future<ProgressStats> getProgress() async {
    try {
      final response = await _apiClient.get('/api/progress');
      final data = response.data['data'] as Map<String, dynamic>;
      return _fromBackend(data);
    } catch (_) {
      // Offline / error → derive from whatever this user has cached locally.
      return _computeLocal();
    }
  }

  /// Records a visited material/story both on the backend (per user) and in the
  /// local cache mirror.
  Future<void> recordActivity({
    required String type,
    required String id,
    required String title,
    String subtitle = '',
  }) async {
    await _storage.recordActivity(
      type: type,
      id: id,
      title: title,
      subtitle: subtitle,
    );
    try {
      await _apiClient.post(
        '/api/activity',
        data: {
          'type': type,
          'refId': id,
          'title': title,
          'subtitle': subtitle,
        },
      );
    } catch (_) {
      // Best-effort; the local mirror already captured it.
    }
  }

  ProgressStats _fromBackend(Map<String, dynamic> data) {
    final recentRaw = (data['recent'] as List? ?? const []);
    final recent = recentRaw.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ActivityItem(
        type: m['type']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        subtitle: m['subtitle']?.toString() ?? '',
        route: m['route']?.toString() ?? '',
        date:
            DateTime.tryParse(m['date']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();

    return ProgressStats(
      quizzesCompleted: (data['quizzesCompleted'] as num?)?.toInt() ?? 0,
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
      avgScore: (data['avgScore'] as num?)?.toInt() ?? 0,
      bestScore: (data['bestScore'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      materialsViewed: (data['materialsViewed'] as num?)?.toInt() ?? 0,
      storiesRead: (data['storiesRead'] as num?)?.toInt() ?? 0,
      recent: recent,
    );
  }

  Future<ProgressStats> _computeLocal() async {
    try {
      final historyRaw = await _storage.getQuizHistory();
      final activityRaw = await _storage.getRecentActivity();

      final history =
          historyRaw.map((e) => QuizResultModel.fromJson(e)).toList();

      final quizzesCompleted = history.length;
      final pointsEarned =
          history.fold<int>(0, (sum, r) => sum + r.pointsEarned);
      final avgScore = quizzesCompleted == 0
          ? 0
          : (history.fold<int>(0, (sum, r) => sum + r.percentage) /
                  quizzesCompleted)
              .round();
      final bestScore = history.fold<int>(
        0,
        (best, r) => r.percentage > best ? r.percentage : best,
      );

      var materialsViewed = 0;
      var storiesRead = 0;
      for (final a in activityRaw) {
        if (a['type'] == 'material') materialsViewed++;
        if (a['type'] == 'story') storiesRead++;
      }

      final recent = _buildRecent(history, activityRaw);
      final streak = _computeStreak(history, activityRaw);

      return ProgressStats(
        quizzesCompleted: quizzesCompleted,
        pointsEarned: pointsEarned,
        avgScore: avgScore,
        bestScore: bestScore,
        streak: streak,
        materialsViewed: materialsViewed,
        storiesRead: storiesRead,
        recent: recent,
      );
    } catch (_) {
      return const ProgressStats();
    }
  }

  List<ActivityItem> _buildRecent(
    List<QuizResultModel> history,
    List<Map<String, dynamic>> activity,
  ) {
    final items = <ActivityItem>[];
    for (final r in history) {
      items.add(ActivityItem(
        type: 'quiz',
        title: '${r.subject} Quiz',
        subtitle: '${r.percentage}% • ${r.correct}/${r.total} correct',
        route: '/quizzes/history',
        date: r.date,
      ));
    }
    for (final a in activity) {
      final type = a['type']?.toString() ?? '';
      if (type != 'material' && type != 'story') continue;
      final id = a['id']?.toString() ?? '';
      items.add(ActivityItem(
        type: type,
        title: a['title']?.toString() ?? '',
        subtitle: a['subtitle']?.toString() ?? '',
        route: type == 'story' ? '/stories/$id' : '/study-materials',
        date: DateTime.tryParse(a['ts']?.toString() ?? '') ?? DateTime.now(),
      ));
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(8).toList();
  }

  int _computeStreak(
    List<QuizResultModel> history,
    List<Map<String, dynamic>> activity,
  ) {
    final days = <DateTime>{};
    void add(DateTime d) => days.add(DateTime(d.year, d.month, d.day));
    for (final r in history) {
      add(r.date);
    }
    for (final a in activity) {
      final ts = DateTime.tryParse(a['ts']?.toString() ?? '');
      if (ts != null) add(ts);
    }
    if (days.isEmpty) return 0;

    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
