/// Per-subject quiz progress for the signed-in user, returned by
/// `GET /api/progress/quiz-stats` (scoped by Firebase UID).
class SubjectQuizStats {
  /// Ids of questions the user has already answered (so they aren't repeated).
  final Set<String> completedQuestionIds;
  final int attempts;
  final int bestScore; // percentage
  final int avgScore; // percentage
  final DateTime? lastAttempt;

  const SubjectQuizStats({
    this.completedQuestionIds = const {},
    this.attempts = 0,
    this.bestScore = 0,
    this.avgScore = 0,
    this.lastAttempt,
  });

  factory SubjectQuizStats.fromJson(Map<String, dynamic> json) {
    return SubjectQuizStats(
      completedQuestionIds: ((json['completedQuestionIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      bestScore: (json['bestScore'] as num?)?.toInt() ?? 0,
      avgScore: (json['avgScore'] as num?)?.toInt() ?? 0,
      lastAttempt: DateTime.tryParse(json['lastAttempt']?.toString() ?? ''),
    );
  }
}
