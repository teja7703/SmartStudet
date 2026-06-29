class QuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String category;
  final String classLevel;
  final String language;
  final String difficulty;
  final int points;

  // Telugu translations (optional). `optionsTe` is parallel to `options`.
  final String questionTe;
  final List<String> optionsTe;
  final String explanationTe;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.category,
    required this.classLevel,
    required this.language,
    required this.difficulty,
    required this.points,
    this.questionTe = '',
    this.optionsTe = const [],
    this.explanationTe = '',
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['_id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: List<String>.from(json['options'] ?? const []),
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      classLevel: json['classLevel']?.toString() ?? '',
      // Legacy questions have no language; treat them as English.
      language: (json['language']?.toString().isNotEmpty ?? false)
          ? json['language'].toString()
          : 'English',
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      points: (json['points'] is num) ? (json['points'] as num).toInt() : 10,
      questionTe: json['questionTe']?.toString() ?? '',
      optionsTe: List<String>.from(json['optionsTe'] ?? const []),
      explanationTe: json['explanationTe']?.toString() ?? '',
    );
  }

  /// Returns a copy with options (and their parallel Telugu) reordered, used
  /// to randomize answer order while keeping translations aligned.
  QuestionModel copyWith({
    List<String>? options,
    List<String>? optionsTe,
  }) {
    return QuestionModel(
      id: id,
      question: question,
      options: options ?? this.options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      category: category,
      classLevel: classLevel,
      language: language,
      difficulty: difficulty,
      points: points,
      questionTe: questionTe,
      optionsTe: optionsTe ?? this.optionsTe,
      explanationTe: explanationTe,
    );
  }

  /// Telugu translation for a given English [option], matched by position.
  String teForOption(String option) {
    final i = options.indexOf(option);
    if (i < 0 || i >= optionsTe.length) return '';
    return optionsTe[i];
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'category': category,
        'classLevel': classLevel,
        'language': language,
        'difficulty': difficulty,
        'points': points,
        'questionTe': questionTe,
        'optionsTe': optionsTe,
        'explanationTe': explanationTe,
      };
}
