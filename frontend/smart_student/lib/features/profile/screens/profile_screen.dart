import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/models/user_model.dart';
import '../../progress/cubit/progress_cubit.dart';
import '../../progress/models/progress_stats.dart';
import '../../../injection.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          body: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(user: user),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GroupLabel('Account'),
                    _MenuTile(
                      icon: Icons.edit_rounded,
                      color: AppColors.primaryBlue,
                      title: 'Edit Profile',
                      subtitle: 'Update your name & photo',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    _MenuTile(
                      icon: Icons.translate_rounded,
                      color: AppColors.accentPurple,
                      title: 'Change Language',
                      subtitle: 'English / తెలుగు',
                      onTap: () => _changeLanguage(context),
                    ),
                    const SizedBox(height: 16),
                    _GroupLabel('Learning'),
                    _MenuTile(
                      icon: Icons.quiz_rounded,
                      color: AppColors.secondaryGreen,
                      title: 'Quiz History',
                      subtitle: 'Your past attempts & analytics',
                      onTap: () => context.push('/quizzes/history'),
                    ),
                    _MenuTile(
                      icon: Icons.bookmark_rounded,
                      color: AppColors.accentOrange,
                      title: 'Saved Materials',
                      subtitle: 'Your bookmarked stories',
                      onTap: () => _showSaved(context),
                    ),
                    _MenuTile(
                      icon: Icons.download_rounded,
                      color: AppColors.primaryBlueLight,
                      title: 'Download History',
                      subtitle: 'PDFs you downloaded',
                      onTap: () => _comingSoon(context, 'Download History'),
                    ),
                    const SizedBox(height: 16),
                    _GroupLabel('More'),
                    _MenuTile(
                      icon: Icons.settings_rounded,
                      color: AppColors.textSecondary,
                      title: 'App Settings',
                      subtitle: 'Notifications & preferences',
                      onTap: () => _comingSoon(context, 'App Settings'),
                    ),
                    _MenuTile(
                      icon: Icons.help_outline_rounded,
                      color: AppColors.accentRed,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact us',
                      onTap: () => _showHelp(context),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final progress = context.read<ProgressCubit>();
                          await context.read<AuthCubit>().signOut();
                          // Drop the signed-out user's in-memory stats so the
                          // next account never sees them.
                          progress.reset();
                          if (context.mounted) context.go('/login');
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.accentRed,
                        ),
                        label: Text(
                          'Logout',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.accentRed,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentRed),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Smart Student • v1.0.0',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon!')));
  }

  void _changeLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget option(String label, String sub) => ListTile(
          leading: const Icon(
            Icons.language_rounded,
            color: AppColors.accentPurple,
          ),
          title: Text(label, style: AppTextStyles.titleMedium),
          subtitle: Text(sub, style: AppTextStyles.labelMedium),
          onTap: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Language preference: $label')),
            );
          },
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Language', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              option('English', 'Default language'),
              option('తెలుగు', 'Telugu'),
            ],
          ),
        );
      },
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'Need help? Reach us at:\n\nsupport@smartstudent.app\n\nWe usually reply within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaved(BuildContext context) async {
    final storage = getIt<StorageService>();
    final bookmarks = await storage.getBookmarkedStories();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saved Materials', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 16),
              if (bookmarks.isEmpty)
                Text('No saved items yet.', style: AppTextStyles.bodyMedium)
              else
                ...bookmarks.map(
                  (id) => ListTile(
                    leading: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.accentOrange,
                    ),
                    title: Text('Story $id'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/stories/$id');
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel? user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Profile',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final provider = avatarProvider(user?.photoUrl);
                return CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  backgroundImage: provider,
                  child: provider == null
                      ? const Icon(Icons.person, size: 44, color: Colors.white)
                      : null,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Student',
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
            if ((user?.email ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user!.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ] else if ((user?.phone ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                user!.phone,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
            const SizedBox(height: 16),
            BlocBuilder<ProgressCubit, ProgressStats>(
              builder: (context, stats) {
                return Row(
                  children: [
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${stats.streak} Day Streak',
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.star_rounded,
                      label: '${stats.pointsEarned} Points',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accentOrange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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

class _GroupLabel extends StatelessWidget {
  final String label;

  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  Text(subtitle, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
