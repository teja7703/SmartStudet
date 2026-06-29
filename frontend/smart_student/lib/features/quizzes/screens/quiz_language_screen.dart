import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Step 2 of the quiz journey: pick the language for this class session.
class QuizLanguageScreen extends StatelessWidget {
  final String classLevel;

  const QuizLanguageScreen({super.key, required this.classLevel});

  void _select(BuildContext context, String language) {
    context.push('/quizzes/$language/$classLevel/subjects');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AcademicConstants.formatLevel(classLevel)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Select Language', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('భాషను ఎంచుకోండి', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 20),
          _LanguageCard(
            title: 'English',
            subtitle: 'Take quizzes in English',
            icon: Icons.translate_rounded,
            color: AppColors.primaryBlue,
            onTap: () => _select(context, AcademicConstants.langEnglish),
          ),
          const SizedBox(height: 16),
          _LanguageCard(
            title: 'తెలుగు',
            subtitle: 'తెలుగులో క్విజ్‌లు',
            icon: Icons.language_rounded,
            color: AppColors.secondaryGreen,
            onTap: () => _select(context, AcademicConstants.langTelugu),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The English subject is always shown in English.',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
