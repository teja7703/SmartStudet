import 'dart:math';

import '../repositories/quiz_repository.dart';
import 'quiz_model.dart';
import 'subject_quiz_stats.dart';

/// Pairs a subject's question [pool] with the user's [stats] and exposes the
/// derived numbers the subject card displays.
class SubjectQuizInfo {
  final QuizModel pool;
  final SubjectQuizStats stats;

  const SubjectQuizInfo({required this.pool, required this.stats});

  String get subject => pool.subject;

  int get totalQuestions => pool.totalQuestions;

  int get completedQuestions {
    final ids = pool.questions.map((q) => q.id).toSet();
    return ids.intersection(stats.completedQuestionIds).length;
  }

  int get remainingQuestions =>
      (totalQuestions - completedQuestions).clamp(0, totalQuestions);

  double get progress =>
      totalQuestions == 0 ? 0 : completedQuestions / totalQuestions;

  bool get isFullyCompleted =>
      totalQuestions > 0 && completedQuestions >= totalQuestions;

  int get totalQuizzes =>
      totalQuestions == 0 ? 0 : (totalQuestions / QuizRepository.quizSize).ceil();

  int get completedQuizzes {
    if (isFullyCompleted) return totalQuizzes;
    return (completedQuestions / QuizRepository.quizSize).floor();
  }

  int get remainingQuizzes =>
      (totalQuizzes - completedQuizzes).clamp(0, totalQuizzes);

  /// Estimated minutes for the next attempt (30s per question).
  int get estimatedMinutes {
    final base = remainingQuestions == 0 ? totalQuestions : remainingQuestions;
    final n = min(base, QuizRepository.quizSize);
    return n == 0 ? 0 : ((n * 30) / 60).ceil();
  }

  String get difficultyLabel => pool.difficultyLabel;
}
