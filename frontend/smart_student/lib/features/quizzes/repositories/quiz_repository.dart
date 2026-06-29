import 'dart:math';

import '../../../core/network/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../models/subject_quiz_stats.dart';

class QuizRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  /// Number of questions that make up a single quiz attempt.
  static const int quizSize = 10;

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
    String? language,
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
        if (language != null && language.isNotEmpty) 'language': language,
        'page': page,
        'limit': limit,
      },
    );

    final List data = response.data['data'] ?? [];
    return data.map((e) => QuestionModel.fromJson(e)).toList();
  }

  /// Builds the subject list (each a full question pool) for one class and the
  /// chosen [language].
  ///
  /// English-subject rule: the "English" subject is always returned in English
  /// regardless of [language]. For every other subject the chosen language is
  /// used, falling back to English questions when none exist in that language
  /// (so the screen is never empty when only English content has been seeded).
  Future<List<QuizModel>> getSubjects({
    required String classLevel,
    required String language,
  }) async {
    final questions = await getQuestions(classLevel: classLevel, limit: 1000);

    final bySubject = <String, List<QuestionModel>>{};
    for (final q in questions) {
      final subject = q.category.isEmpty ? 'General' : q.category;
      bySubject.putIfAbsent(subject, () => []).add(q);
    }

    final quizzes = <QuizModel>[];
    bySubject.forEach((subject, pool) {
      final effectiveLang = _effectiveLanguage(subject, language);

      var selected =
          pool.where((q) => q.language == effectiveLang).toList();
      if (selected.isEmpty) {
        selected = pool.where((q) => q.language == 'English').toList();
      }
      if (selected.isEmpty) selected = pool;

      quizzes.add(QuizModel(
        id: '$classLevel-$subject',
        title: '$subject Quiz',
        subject: subject,
        classLevel: classLevel,
        language: effectiveLang,
        questions: selected,
      ));
    });

    quizzes.sort((a, b) => a.subject.compareTo(b.subject));
    return quizzes;
  }

  /// Per-subject quiz stats for the signed-in user (completed question ids,
  /// best/avg score, last attempt). Empty map when offline.
  Future<Map<String, SubjectQuizStats>> getQuizStats({
    required String classLevel,
    required String language,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/progress/quiz-stats',
        queryParameters: {'classLevel': classLevel, 'language': language},
      );
      final data =
          (response.data['data'] as Map?)?.cast<String, dynamic>() ?? {};
      return data.map(
        (key, value) => MapEntry(
          key,
          SubjectQuizStats.fromJson(Map<String, dynamic>.from(value)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  /// Composes a fresh quiz attempt from a subject [pool]: excludes questions the
  /// user already completed (unless [practiceAgain]), shuffles question order
  /// and the options of each question.
  QuizModel buildAttempt(
    QuizModel pool, {
    Set<String> completedIds = const {},
    bool practiceAgain = false,
    int size = quizSize,
  }) {
    final rng = Random();
    final all = [...pool.questions];

    List<QuestionModel> available;
    if (practiceAgain) {
      available = all;
    } else {
      available = all.where((q) => !completedIds.contains(q.id)).toList();
      // Everything done already → recycle the whole pool so a quiz can still
      // start (the screen will have offered "Practice Again").
      if (available.isEmpty) available = all;
    }

    available.shuffle(rng);
    final picked = available.take(size).map((q) {
      final options = [...q.options]..shuffle(rng);
      return q.copyWith(options: options);
    }).toList();

    return pool.copyWith(
      id: '${pool.id}-${DateTime.now().millisecondsSinceEpoch}',
      questions: picked,
    );
  }

  String _effectiveLanguage(String subject, String chosen) {
    if (subject.toLowerCase() == 'english') return 'English';
    return chosen;
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
