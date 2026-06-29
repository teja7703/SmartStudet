import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../progress/cubit/progress_cubit.dart';
import '../../progress/models/progress_stats.dart';
import '../models/quiz_result_model.dart';
import '../quiz_ui.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizResultModel result;

  const QuizResultScreen({super.key, required this.result});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    // The attempt was already saved to history; refresh progress so the
    // home/profile screens reflect the new completion immediately.
    context.read<ProgressCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final percentage = result.percentage;
    final passed = percentage >= 50;
    final gradient =
        passed ? AppColors.greenGradient : AppColors.sunsetGradient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: (passed
                            ? AppColors.secondaryGreen
                            : AppColors.accentRed)
                        .withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$percentage%',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      'Score',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              passed ? 'Great Job!' : 'Keep Practicing!',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '${result.title} • ${QuizUi.classLabel(result.classLevel)}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'You got ${result.correct} of ${result.total} correct',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatTile(
                  label: 'Correct',
                  value: '${result.correct}',
                  color: AppColors.secondaryGreen,
                  icon: Icons.check_circle_rounded,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Wrong',
                  value: '${result.wrong}',
                  color: AppColors.accentRed,
                  icon: Icons.cancel_rounded,
                ),
                const SizedBox(width: 12),
                _StatTile(
                  label: 'Skipped',
                  value: '${result.skipped}',
                  color: AppColors.textSecondary,
                  icon: Icons.remove_circle_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'Points',
                    value: '${result.pointsEarned}/${result.totalPoints}',
                  ),
                  Container(width: 1, height: 36, color: AppColors.divider),
                  _MiniStat(
                    label: 'Time',
                    value: QuizUi.formatDuration(result.timeTakenSeconds),
                  ),
                  Container(width: 1, height: 36, color: AppColors.divider),
                  _MiniStat(label: 'Accuracy', value: '$percentage%'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ProgressCubit, ProgressStats>(
              builder: (context, stats) {
                return Row(
                  children: [
                    _RewardChip(
                      icon: Icons.star_rounded,
                      color: AppColors.accentOrange,
                      label: '+${result.pointsEarned} points',
                    ),
                    const SizedBox(width: 12),
                    _RewardChip(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.accentRed,
                      label: '${stats.streak} day streak',
                    ),
                  ],
                );
              },
            ),
            if (percentage == 100) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Achievement unlocked: Perfect Score!',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/quizzes/review', extra: result),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Review Answers'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(
                  '/quizzes/${result.language}/${result.classLevel}/subjects',
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next Quiz'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/study-materials'),
                    child: const Text('Continue Learning'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go to Home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _RewardChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: color.withValues(alpha: 0.08),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelMedium),
          ],
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
        Text(value, style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
