import 'package:equatable/equatable.dart';
import '../models/subject_quiz_info.dart';

abstract class QuizSubjectsState extends Equatable {
  const QuizSubjectsState();

  @override
  List<Object?> get props => [];
}

class QuizSubjectsLoading extends QuizSubjectsState {
  const QuizSubjectsLoading();
}

class QuizSubjectsEmpty extends QuizSubjectsState {
  const QuizSubjectsEmpty();
}

class QuizSubjectsError extends QuizSubjectsState {
  final String message;

  const QuizSubjectsError(this.message);

  @override
  List<Object?> get props => [message];
}

class QuizSubjectsLoaded extends QuizSubjectsState {
  final List<SubjectQuizInfo> subjects;

  const QuizSubjectsLoaded(this.subjects);

  @override
  List<Object?> get props => [subjects];
}
