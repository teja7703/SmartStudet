import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shared Hero tag so the FAB morphs smoothly into the SmartGPT screen avatar.
const String kSmartGptHeroTag = 'smart-gpt-hero';

/// Gradient circular floating action button that opens SmartGPT.
class SmartGptFab extends StatelessWidget {
  final VoidCallback onPressed;

  const SmartGptFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: kSmartGptHeroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.smartGptGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
