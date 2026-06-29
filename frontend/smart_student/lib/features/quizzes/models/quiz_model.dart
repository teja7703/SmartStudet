import 'question_model.dart';

/// A quiz session built dynamically from a set of questions that share the
/// same class level and subject (category). The backend stores a question
/// bank; quizzes are composed on the client by grouping those questions.
class QuizModel {
  final String id;
  final String title;
  final String subject;
  final String classLevel;
  final String language;
  final List<QuestionModel> questions;

  const QuizModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.classLevel,
    this.language = 'English',
    required this.questions,
  });

  int get totalQuestions => questions.length;

  int get totalPoints =>
      questions.fold(0, (sum, q) => sum + q.points);

  /// 30 seconds per question.
  int get durationSeconds => questions.length * 30;

  String get difficultyLabel {
    if (questions.isEmpty) return 'Mixed';
    final set = questions.map((q) => q.difficulty).toSet();
    if (set.length == 1) return set.first;
    return 'Mixed';
  }

  QuizModel copyWith({
    String? id,
    String? title,
    String? language,
    List<QuestionModel>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject,
      classLevel: classLevel,
      language: language ?? this.language,
      questions: questions ?? this.questions,
    );
  }
}
