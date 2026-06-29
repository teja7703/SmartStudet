import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/avatar_image.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/feature_tile.dart';
import '../../../core/widgets/gradient_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/models/user_model.dart';
import '../../progress/cubit/progress_cubit.dart';
import '../../progress/models/progress_stats.dart';
import '../../smart_gpt/widgets/smart_gpt_fab.dart';
import '../../smart_gpt/widgets/smart_gpt_promo_card.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _motivations = [
    'Small steps every day lead to big results.',
    'Your only limit is the effort you give today.',
    'Learn a little more than yesterday.',
    'Discipline beats motivation. Show up daily!',
    'Dream big. Study hard. Achieve more.',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<ProgressCubit>().load();
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardCubit>().loadDashboard(),
      context.read<ProgressCubit>().load(),
    ]);
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _todaysMotivation() {
    final day = DateTime.now().day;
    return _motivations[day % _motivations.length];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: SmartGptFab(
                onPressed: () => context.push('/smart-gpt'),
              ),
              body: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primaryBlue,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(user: user, greeting: _greeting()),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: SmartGptPromoCard(
                          onTap: () => context.push('/smart-gpt'),
                        ),
                      ),
                    ),
                    if (state is DashboardLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: ShimmerGridLoading(itemCount: 6),
                        ),
                      )
                    else if (state is DashboardError)
                      SliverFillRemaining(
                        child: ErrorStateWidget(
                          message: state.message,
                          onRetry: () =>
                              context.read<DashboardCubit>().loadDashboard(),
                        ),
                      )
                    else if (state is DashboardLoaded) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: SectionHeader(title: 'Explore'),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width > 600
                                    ? 3
                                    : 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.15,
                              ),
                          delegate: SliverChildListDelegate(
                            _quickAccess(context),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: GradientBanner(
                            title: 'DAILY MOTIVATION',
                            message: _todaysMotivation(),
                            icon: Icons.format_quote_rounded,
                            gradient: AppColors.purpleGradient,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: GradientBanner(
                            title: 'DAILY QUIZ',
                            message:
                                'Test what you learned today and earn points!',
                            icon: Icons.bolt_rounded,
                            gradient: AppColors.orangeGradient,
                            actionLabel: 'Start Quiz',
                            onAction: () => context.push('/quizzes'),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                          child: SectionHeader(title: 'Your Progress'),
                        ),
                      ),
                      const SliverToBoxAdapter(child: _ProgressSection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _quickAccess(BuildContext context) {
    return [
      FeatureTile(
        title: 'Study Materials',
        subtitle: 'Notes & PDFs',
        icon: Icons.menu_book_rounded,
        color: AppColors.primaryBlue,
        onTap: () => context.push('/study-materials'),
      ),
      FeatureTile(
        title: 'Quizzes',
        subtitle: 'Practice MCQs',
        icon: Icons.quiz_rounded,
        color: AppColors.secondaryGreen,
        onTap: () => context.push('/quizzes'),
      ),
      FeatureTile(
        title: 'Career Guidance',
        subtitle: 'Plan ahead',
        icon: Icons.work_outline_rounded,
        color: AppColors.accentPurple,
        onTap: () => context.push('/careers'),
      ),
      FeatureTile(
        title: 'Success Stories',
        subtitle: 'Get inspired',
        icon: Icons.auto_stories_rounded,
        color: AppColors.accentRed,
        onTap: () => context.push('/stories'),
      ),
      FeatureTile(
        title: 'Spoken English',
        subtitle: 'Speak daily',
        icon: Icons.record_voice_over_rounded,
        color: AppColors.primaryBlueLight,
        onTap: () => context.push('/spoken-english'),
      ),
      FeatureTile(
        title: 'Previous Papers',
        subtitle: 'Exam prep',
        icon: Icons.description_rounded,
        color: AppColors.accentOrange,
        onTap: () => context.push('/previous-papers'),
      ),
      FeatureTile(
        title: 'Games & Puzzles',
        subtitle: 'Have fun',
        icon: Icons.videogame_asset_rounded,
        color: AppColors.accentPurple,
        onTap: () => context.push('/games'),
      ),
      FeatureTile(
        title: 'Video Lessons',
        subtitle: 'Coming soon',
        icon: Icons.play_circle_fill_rounded,
        color: AppColors.secondaryGreenDark,
        onTap: () => context.push('/coming-soon/video-lessons'),
      ),
    ];
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressStats>(
      builder: (context, stats) {
        if (stats.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: AppColors.secondaryGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start your journey',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Take a quiz or open a lesson — your progress will show up here.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _ProgressStat(
                    label: 'Quizzes',
                    value: '${stats.quizzesCompleted}',
                    icon: Icons.quiz_rounded,
                    color: AppColors.secondaryGreen,
                  ),
                  const SizedBox(width: 12),
                  _ProgressStat(
                    label: 'Avg Score',
                    value: '${stats.avgScore}%',
                    icon: Icons.insights_rounded,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  _ProgressStat(
                    label: 'Points',
                    value: '${stats.pointsEarned}',
                    icon: Icons.star_rounded,
                    color: AppColors.accentOrange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Activity',
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ),
            ...stats.recent.map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _ActivityTile(item: item),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
            Text(
              label,
              style: AppTextStyles.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityItem item;

  const _ActivityTile({required this.item});

  ({IconData icon, Color color}) get _visuals {
    switch (item.type) {
      case 'quiz':
        return (icon: Icons.quiz_rounded, color: AppColors.secondaryGreen);
      case 'story':
        return (icon: Icons.auto_stories_rounded, color: AppColors.accentRed);
      case 'material':
        return (icon: Icons.menu_book_rounded, color: AppColors.primaryBlue);
      default:
        return (icon: Icons.history_rounded, color: AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visuals;
    return AppCard(
      onTap: () => context.push(item.route),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: v.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(v.icon, color: v.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle.isNotEmpty)
                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel? user;
  final String greeting;

  const _Header({required this.user, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_icon_fullbleed.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Smart Student',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.firstName ?? 'Student',
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final provider = avatarProvider(user?.photoUrl);
                    return CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      backgroundImage: provider,
                      child: provider == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SearchField(onTap: () => context.push('/search')),
            const SizedBox(height: 16),
            BlocBuilder<ProgressCubit, ProgressStats>(
              builder: (context, stats) {
                return Row(
                  children: [
                    _StatChip(
                      icon: Icons.local_fire_department_rounded,
                      label: '${stats.streak} Day Streak',
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: Icons.star_rounded,
                      label: '${stats.pointsEarned} Points',
                      color: AppColors.accentOrange,
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

class _SearchField extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.textHint),
            const SizedBox(width: 10),
            Text(
              'Search materials, quizzes...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
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
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

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
            Icon(icon, color: color, size: 20),
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
