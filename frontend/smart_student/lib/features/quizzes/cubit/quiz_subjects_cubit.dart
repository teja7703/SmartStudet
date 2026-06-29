import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/quiz_model.dart';
import '../models/subject_quiz_info.dart';
import '../models/subject_quiz_stats.dart';
import '../repositories/quiz_repository.dart';
import 'quiz_subjects_state.dart';

/// Loads the subjects (with per-user progress) for a single class + language,
/// and composes fresh quiz attempts on demand.
class QuizSubjectsCubit extends Cubit<QuizSubjectsState> {
  final QuizRepository _repository;
  final String classLevel;
  final String language;

  QuizSubjectsCubit({
    required QuizRepository repository,
    required this.classLevel,
    required this.language,
  })  : _repository = repository,
        super(const QuizSubjectsLoading());

  Future<void> load() async {
    emit(const QuizSubjectsLoading());
    try {
      final pools = await _repository.getSubjects(
        classLevel: classLevel,
        language: language,
      );
      if (pools.isEmpty) {
        emit(const QuizSubjectsEmpty());
        return;
      }
      final stats = await _repository.getQuizStats(
        classLevel: classLevel,
        language: language,
      );
      final subjects = pools
          .map((pool) => SubjectQuizInfo(
                pool: pool,
                stats: stats[pool.subject] ?? const SubjectQuizStats(),
              ))
          .toList();
      emit(QuizSubjectsLoaded(subjects));
    } catch (e) {
      emit(QuizSubjectsError(e.toString()));
    }
  }

  /// Builds the next quiz attempt for [info]. When [practiceAgain] is true the
  /// completed-question filter is ignored so the user can redo the whole pool.
  QuizModel buildAttempt(SubjectQuizInfo info, {bool practiceAgain = false}) {
    return _repository.buildAttempt(
      info.pool,
      completedIds: info.stats.completedQuestionIds,
      practiceAgain: practiceAgain,
    );
  }
}
