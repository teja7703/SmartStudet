import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../cubit/quiz_subjects_cubit.dart';
import '../cubit/quiz_subjects_state.dart';
import '../models/subject_quiz_info.dart';
import '../quiz_ui.dart';

/// Step 3 of the quiz journey: subjects for the chosen class + language, each
/// showing the user's progress.
class QuizSubjectsScreen extends StatelessWidget {
  final String classLevel;
  final String language;

  const QuizSubjectsScreen({
    super.key,
    required this.classLevel,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AcademicConstants.formatLevel(classLevel)} • $language',
        ),
      ),
      body: BlocBuilder<QuizSubjectsCubit, QuizSubjectsState>(
        builder: (context, state) {
          if (state is QuizSubjectsLoading) {
            return const ShimmerLoading();
          }
          if (state is QuizSubjectsError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<QuizSubjectsCubit>().load(),
            );
          }
          if (state is QuizSubjectsEmpty) {
            return EmptyStateWidget(
              icon: Icons.quiz_outlined,
              title: 'No quizzes yet',
              message:
                  'Quizzes for this class will appear here once they are added.',
              onRetry: () => context.read<QuizSubjectsCubit>().load(),
            );
          }
          if (state is QuizSubjectsLoaded) {
            return RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () => context.read<QuizSubjectsCubit>().load(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: state.subjects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) => _SubjectCard(
                  info: state.subjects[index],
                  language: language,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectQuizInfo info;
  final String language;

  const _SubjectCard({required this.info, required this.language});

  void _start(BuildContext context, {bool practiceAgain = false}) {
    final attempt = context
        .read<QuizSubjectsCubit>()
        .buildAttempt(info, practiceAgain: practiceAgain);
    if (attempt.totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available yet.')),
      );
      return;
    }
    context.push('/quizzes/play', extra: attempt);
  }

  @override
  Widget build(BuildContext context) {
    final color = QuizUi.subjectColor(info.subject);
    final done = info.isFullyCompleted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientFor(color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(QuizUi.subjectIcon(info.subject),
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AcademicConstants.formatSubject(info.subject, language),
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${info.totalQuizzes} quizzes • ${info.totalQuestions} questions',
                      style: AppTextStyles.labelMedium,
                    ),
                  ],
                ),
              ),
              _DifficultyBadge(label: info.difficultyLabel),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressBar(value: info.progress, color: color),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${(info.progress * 100).round()}% complete',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${info.completedQuizzes}/${info.totalQuizzes} done • '
                '${info.remainingQuizzes} left',
                style: AppTextStyles.labelMedium,
              ),
            ],
          ),
          if (info.stats.attempts > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: 'Best', value: '${info.stats.bestScore}%'),
                  _divider(),
                  _MiniStat(label: 'Avg', value: '${info.stats.avgScore}%'),
                  _divider(),
                  _MiniStat(
                    label: 'Last',
                    value: _ago(info.stats.lastAttempt),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (done) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "You've completed all quizzes in this category 🎉",
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.secondaryGreen,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _start(context, practiceAgain: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Practice Again'),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _start(context),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  info.completedQuizzes > 0 ? 'Next Quiz' : 'Start Quiz',
                ),
              ),
            ),
          if (!done)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  'About ${info.estimatedMinutes} min',
                  style: AppTextStyles.labelMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: AppColors.divider);

  static String _ago(DateTime? date) {
    if (date == null) return '—';
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'now';
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AppColors.divider,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String label;

  const _DifficultyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = QuizUi.difficultyColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
