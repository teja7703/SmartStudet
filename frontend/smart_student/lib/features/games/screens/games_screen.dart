import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class _Game {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _Game({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const List<_Game> _games = [
    _Game(
      title: 'Memory Match',
      subtitle: 'Flip & match the pairs',
      icon: Icons.grid_view_rounded,
      color: AppColors.accentPurple,
      route: '/games/memory',
    ),
    _Game(
      title: 'Quick Math',
      subtitle: 'Beat the clock',
      icon: Icons.calculate_rounded,
      color: AppColors.primaryBlue,
      route: '/games/quick-math',
    ),
    _Game(
      title: 'Tic Tac Toe',
      subtitle: 'Play vs computer',
      icon: Icons.close_rounded,
      color: AppColors.secondaryGreen,
      route: '/games/tic-tac-toe',
    ),
    _Game(
      title: 'Word Scramble',
      subtitle: 'Unscramble the word',
      icon: Icons.abc_rounded,
      color: AppColors.accentOrange,
      route: '/games/word-scramble',
    ),
    _Game(
      title: 'Riddles',
      subtitle: 'Brain teasers',
      icon: Icons.psychology_rounded,
      color: AppColors.accentRed,
      route: '/games/riddles',
    ),
    _Game(
      title: 'Guess Number',
      subtitle: 'Crack the code',
      icon: Icons.tag_rounded,
      color: AppColors.primaryBlueLight,
      route: '/games/guess-number',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games & Puzzles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.videogame_asset_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brain Games',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take a fun break and sharpen your mind!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: _games.map((game) => _GameCard(game: game)).toList(),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final _Game game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(game.route),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: game.color.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientFor(game.color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(game.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(game.title, style: AppTextStyles.titleMedium),
              const SizedBox(height: 2),
              Text(
                game.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
