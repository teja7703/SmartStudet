/// A single answered (or skipped) question within a quiz attempt.
class AnswerRecord {
  final String questionId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String? selectedAnswer;
  final String explanation;

  // Telugu translations (optional). `optionsTe` is parallel to `options`.
  final String questionTe;
  final List<String> optionsTe;
  final String explanationTe;

  const AnswerRecord({
    this.questionId = '',
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.explanation,
    this.questionTe = '',
    this.optionsTe = const [],
    this.explanationTe = '',
  });

  bool get isAnswered => selectedAnswer != null && selectedAnswer!.isNotEmpty;

  bool get isCorrect => isAnswered && selectedAnswer == correctAnswer;

  /// Telugu translation for a given English [option], matched by position.
  String teForOption(String option) {
    final i = options.indexOf(option);
    if (i < 0 || i >= optionsTe.length) return '';
    return optionsTe[i];
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'selectedAnswer': selectedAnswer,
        'explanation': explanation,
        'questionTe': questionTe,
        'optionsTe': optionsTe,
        'explanationTe': explanationTe,
      };

  factory AnswerRecord.fromJson(Map<String, dynamic> json) {
    return AnswerRecord(
      questionId: json['questionId']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: List<String>.from(json['options'] ?? const []),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      selectedAnswer: json['selectedAnswer']?.toString(),
      explanation: json['explanation']?.toString() ?? '',
      questionTe: json['questionTe']?.toString() ?? '',
      optionsTe: List<String>.from(json['optionsTe'] ?? const []),
      explanationTe: json['explanationTe']?.toString() ?? '',
    );
  }
}

/// The result of a completed quiz attempt. Persisted to local history.
class QuizResultModel {
  final String quizId;
  final String title;
  final String subject;
  final String classLevel;
  final String language;
  final int total;
  final int correct;
  final int pointsEarned;
  final int totalPoints;
  final int timeTakenSeconds;
  final DateTime date;
  final List<AnswerRecord> answers;

  const QuizResultModel({
    required this.quizId,
    required this.title,
    required this.subject,
    required this.classLevel,
    this.language = 'English',
    required this.total,
    required this.correct,
    required this.pointsEarned,
    required this.totalPoints,
    required this.timeTakenSeconds,
    required this.date,
    required this.answers,
  });

  int get attempted => answers.where((a) => a.isAnswered).length;

  int get wrong => attempted - correct;

  int get skipped => total - attempted;

  int get percentage =>
      total > 0 ? (correct / total * 100).round() : 0;

  Map<String, dynamic> toJson() => {
        'quizId': quizId,
        'title': title,
        'subject': subject,
        'classLevel': classLevel,
        'language': language,
        'total': total,
        'correct': correct,
        'pointsEarned': pointsEarned,
        'totalPoints': totalPoints,
        'timeTakenSeconds': timeTakenSeconds,
        'date': date.toIso8601String(),
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quizId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      classLevel: json['classLevel']?.toString() ?? '',
      language: json['language']?.toString().isNotEmpty == true
          ? json['language'].toString()
          : 'English',
      total: (json['total'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      answers: (json['answers'] as List? ?? const [])
          .map((e) => AnswerRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
