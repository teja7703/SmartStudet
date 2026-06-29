import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';

class QuizRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  QuizRepository({
    required ApiClient apiClient,
    required StorageService storageService,
  })  : _apiClient = apiClient,
        _storageService = storageService;

  /// Fetches raw questions (the question bank) from the backend.
  Future<List<QuestionModel>> getQuestions({
    String? classLevel,
    String? category,
    String? difficulty,
    int page = 1,
    int limit = 500,
  }) async {
    final response = await _apiClient.get(
      '/api/quizzes',
      queryParameters: {
        if (classLevel != null && classLevel.isNotEmpty)
          'classLevel': classLevel,
        if (category != null && category.isNotEmpty) 'category': category,
        if (difficulty != null && difficulty.isNotEmpty)
          'difficulty': difficulty,
        'page': page,
        'limit': limit,
      },
    );

    final List data = response.data['data'] ?? [];
    return data.map((e) => QuestionModel.fromJson(e)).toList();
  }

  /// Builds the full quiz catalog dynamically: a list of quizzes per class
  /// level, where each quiz groups the questions of one subject.
  Future<Map<String, List<QuizModel>>> getCatalog() async {
    final questions = await getQuestions(limit: 1000);
    return _groupIntoCatalog(questions);
  }

  Map<String, List<QuizModel>> _groupIntoCatalog(
    List<QuestionModel> questions,
  ) {
    final byClass = <String, Map<String, List<QuestionModel>>>{};

    for (final q in questions) {
      final classKey = q.classLevel.isEmpty ? 'General' : q.classLevel;
      final subjectKey = q.category.isEmpty ? 'General' : q.category;
      byClass
          .putIfAbsent(classKey, () => {})
          .putIfAbsent(subjectKey, () => [])
          .add(q);
    }

    final catalog = <String, List<QuizModel>>{};
    for (final classEntry in byClass.entries) {
      final quizzes = classEntry.value.entries
          .map(
            (subjectEntry) => QuizModel(
              id: '${classEntry.key}-${subjectEntry.key}',
              title: '${subjectEntry.key} Quiz',
              subject: subjectEntry.key,
              classLevel: classEntry.key,
              questions: subjectEntry.value,
            ),
          )
          .toList()
        ..sort((a, b) => a.subject.compareTo(b.subject));
      catalog[classEntry.key] = quizzes;
    }
    return catalog;
  }

  /// Quiz history for the signed-in user. Fetched from the backend (source of
  /// truth, scoped by Firebase UID) and mirrored into the local cache; falls
  /// back to the cache when offline.
  Future<List<QuizResultModel>> getHistory() async {
    try {
      final response = await _apiClient.get('/api/progress/quiz-results');
      final List data = response.data['data'] ?? [];
      final results = data
          .map((e) => QuizResultModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      await _storageService.setQuizHistory(
        results.map((r) => r.toJson()).toList(),
      );
      return results;
    } catch (_) {
      final raw = await _storageService.getQuizHistory();
      return raw.map((e) => QuizResultModel.fromJson(e)).toList();
    }
  }

  Future<void> saveResult(QuizResultModel result) async {
    // Cache locally first so it survives even if the network call fails.
    await _storageService.addQuizResult(result.toJson());
    await _apiClient.post(
      '/api/progress/quiz-results',
      data: result.toJson(),
    );
  }

  Future<void> clearHistory() async {
    await _storageService.clearQuizHistory();
    try {
      await _apiClient.delete('/api/progress/quiz-results');
    } catch (_) {
      // Best-effort; the local cache is already cleared.
    }
  }
}
