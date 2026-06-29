import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../cubit/quiz_play_cubit.dart';
import '../cubit/quiz_play_state.dart';
import '../quiz_ui.dart';

class QuizPlayScreen extends StatelessWidget {
  const QuizPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizPlayCubit, QuizPlayState>(
      listenWhen: (prev, curr) => curr.status == QuizPlayStatus.finished,
      listener: (context, state) {
        if (state.result != null) {
          context.pushReplacement('/quizzes/result', extra: state.result);
        }
      },
      builder: (context, state) {
        final quiz = state.quiz;
        final question = quiz.questions[state.currentIndex];
        final color = QuizUi.subjectColor(quiz.subject);
        final lowTime = state.secondsRemaining <= 10;
        // English subject practices English only; every other subject shows the
        // Telugu translation directly below the English text.
        final bilingual = quiz.subject.toLowerCase() != 'english';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmExit(context);
            if (leave == true && context.mounted) context.pop();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('${QuizUi.classLabel(quiz.classLevel)} • ${quiz.subject}'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () async {
                  final leave = await _confirmExit(context);
                  if (leave == true && context.mounted) context.pop();
                },
              ),
              actions: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (lowTime ? AppColors.accentRed : color)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: lowTime ? AppColors.accentRed : color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          QuizUi.formatDuration(state.secondsRemaining),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: lowTime ? AppColors.accentRed : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                _ProgressHeader(state: state, color: color),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCard(
                          color: color.withValues(alpha: 0.08),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.question,
                                style: AppTextStyles.headlineMedium,
                              ),
                              if (bilingual &&
                                  question.questionTe.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  question.questionTe,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(question.options.length, (i) {
                          final option = question.options[i];
                          final selected = state.selectedForCurrent == option;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              color: selected
                                  ? color.withValues(alpha: 0.12)
                                  : null,
                              onTap: () => context
                                  .read<QuizPlayCubit>()
                                  .selectOption(option),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? color
                                          : AppColors.divider,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      String.fromCharCode(65 + i),
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option,
                                          style: AppTextStyles.bodyLarge,
                                        ),
                                        if (bilingual &&
                                            question
                                                .teForOption(option)
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            question.teForOption(option),
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check_circle_rounded,
                                        color: color, size: 22),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                _NavBar(state: state, color: color),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit quiz?'),
        content: const Text(
          'Your progress in this quiz will be lost. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final QuizPlayState state;
  final Color color;

  const _ProgressHeader({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${state.currentIndex + 1} of ${state.quiz.totalQuestions}',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              Text(
                '${state.answeredCount} answered',
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final QuizPlayState state;
  final Color color;

  const _NavBar({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuizPlayCubit>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (!state.isFirstQuestion) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cubit.previous,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: state.isLastQuestion
                  ? ElevatedButton.icon(
                      onPressed: () => _confirmSubmit(context, cubit),
                      icon: const Icon(Icons.flag_rounded),
                      label: const Text('Submit'),
                    )
                  : ElevatedButton.icon(
                      onPressed: cubit.next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSubmit(BuildContext context, QuizPlayCubit cubit) async {
    final remaining = state.quiz.totalQuestions - state.answeredCount;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit quiz?'),
        content: Text(
          remaining > 0
              ? 'You have $remaining unanswered question(s). Submit anyway?'
              : 'You have answered all questions. Submit your quiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirm == true) cubit.submit();
  }
}
