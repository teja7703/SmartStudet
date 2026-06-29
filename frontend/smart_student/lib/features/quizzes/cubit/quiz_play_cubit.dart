import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../repositories/quiz_repository.dart';
import 'quiz_play_state.dart';

class QuizPlayCubit extends Cubit<QuizPlayState> {
  final QuizRepository _repository;
  Timer? _timer;

  QuizPlayCubit({required QuizModel quiz, required QuizRepository repository})
    : _repository = repository,
      super(QuizPlayState.initial(quiz)) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != QuizPlayStatus.playing) return;
      final remaining = state.secondsRemaining - 1;
      if (remaining <= 0) {
        emit(state.copyWith(secondsRemaining: 0));
        submit();
      } else {
        emit(state.copyWith(secondsRemaining: remaining));
      }
    });
  }

  void selectOption(String option) {
    if (state.status != QuizPlayStatus.playing) return;
    final updated = Map<int, String>.from(state.answers);
    updated[state.currentIndex] = option;
    emit(state.copyWith(answers: updated));
  }

  void next() {
    if (state.isLastQuestion) return;
    emit(state.copyWith(currentIndex: state.currentIndex + 1));
  }

  void previous() {
    if (state.isFirstQuestion) return;
    emit(state.copyWith(currentIndex: state.currentIndex - 1));
  }

  void jumpTo(int index) {
    if (index < 0 || index >= state.quiz.totalQuestions) return;
    emit(state.copyWith(currentIndex: index));
  }

  Future<void> submit() async {
    if (state.status == QuizPlayStatus.finished) return;
    _timer?.cancel();

    final quiz = state.quiz;
    final answers = <AnswerRecord>[];
    int correct = 0;
    int pointsEarned = 0;

    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final selected = state.answers[i];
      final record = AnswerRecord(
        question: q.question,
        options: q.options,
        correctAnswer: q.correctAnswer,
        selectedAnswer: selected,
        explanation: q.explanation,
      );
      if (record.isCorrect) {
        correct += 1;
        pointsEarned += q.points;
      }
      answers.add(record);
    }

    final timeTaken = quiz.durationSeconds - state.secondsRemaining;

    final result = QuizResultModel(
      quizId: quiz.id,
      title: quiz.title,
      subject: quiz.subject,
      classLevel: quiz.classLevel,
      total: quiz.totalQuestions,
      correct: correct,
      pointsEarned: pointsEarned,
      totalPoints: quiz.totalPoints,
      timeTakenSeconds: timeTaken < 0 ? 0 : timeTaken,
      date: DateTime.now(),
      answers: answers,
    );

    emit(state.copyWith(status: QuizPlayStatus.finished, result: result));

    try {
      await _repository.saveResult(result);
    } catch (_) {
      // History persistence is best-effort; ignore failures.
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
