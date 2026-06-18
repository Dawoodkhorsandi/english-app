import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// A rounded card filled with the brand indigo->violet gradient.
///
/// Used for hero / highlight surfaces (Home review card, Leaderboard rank).
/// Text and icons placed inside should use white / white-on-gradient colors.
class GradientHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;

  const GradientHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.gradient = AppColors.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.borderXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
