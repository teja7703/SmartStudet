import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/quiz_result_model.dart';

class QuizReviewScreen extends StatelessWidget {
  final QuizResultModel result;

  const QuizReviewScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // English subject is English-only; all other subjects show Telugu too.
    final bilingual = result.subject.toLowerCase() != 'english';
    return Scaffold(
      appBar: AppBar(title: const Text('Review Answers')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: result.answers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _ReviewCard(
            index: index,
            answer: result.answers[index],
            bilingual: bilingual,
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final AnswerRecord answer;
  final bool bilingual;

  const _ReviewCard({
    required this.index,
    required this.answer,
    required this.bilingual,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = !answer.isAnswered
        ? AppColors.textSecondary
        : answer.isCorrect
            ? AppColors.secondaryGreen
            : AppColors.accentRed;
    final statusLabel = !answer.isAnswered
        ? 'Skipped'
        : answer.isCorrect
            ? 'Correct'
            : 'Incorrect';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q${index + 1}',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.question, style: AppTextStyles.titleMedium),
                    if (bilingual && answer.questionTe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        answer.questionTe,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.labelMedium.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...answer.options.map((option) {
            final isCorrect = option == answer.correctAnswer;
            final isSelected = option == answer.selectedAnswer;

            Color? bg;
            Color? border;
            IconData? icon;
            Color iconColor = AppColors.textHint;

            if (isCorrect) {
              bg = AppColors.secondaryGreen.withValues(alpha: 0.1);
              border = AppColors.secondaryGreen;
              icon = Icons.check_circle_rounded;
              iconColor = AppColors.secondaryGreen;
            } else if (isSelected) {
              bg = AppColors.accentRed.withValues(alpha: 0.1);
              border = AppColors.accentRed;
              icon = Icons.cancel_rounded;
              iconColor = AppColors.accentRed;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg ?? AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: border ?? AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon ?? Icons.circle_outlined,
                      size: 20, color: iconColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option, style: AppTextStyles.bodyMedium),
                        if (bilingual &&
                            answer.teForOption(option).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            answer.teForOption(option),
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Text(
                      'Your answer',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: border ?? AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (answer.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 18, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          answer.explanation,
                          style: AppTextStyles.bodyMedium,
                        ),
                        if (bilingual && answer.explanationTe.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            answer.explanationTe,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
