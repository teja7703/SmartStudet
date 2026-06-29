import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/academic_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Step 1 of the quiz journey: pick your class.
class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classes = AcademicConstants.academicLevels;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(
            tooltip: 'Quiz History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/quizzes/history'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Choose your class', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Select a class to see its subjects and quizzes.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...classes.map(
            (level) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ClassCard(
                title: AcademicConstants.formatLevel(level),
                onTap: () => context.push('/quizzes/$level/subjects'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _ClassCard({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
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
                  gradient: AppColors.gradientFor(AppColors.primaryBlue),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: AppTextStyles.titleLarge),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
