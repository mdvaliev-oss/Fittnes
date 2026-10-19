import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/exercise.dart';
import 'exercise_visuals.dart';

/// Compact list row for a single exercise, with an inline favorite star.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          ExerciseThumb(exercise: exercise),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.primaryMuscles.map((m) => m.label).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    MiniBadge(
                      icon: ExerciseVisuals.equipmentIcon(exercise.equipment),
                      label: exercise.equipment.label,
                      color: glass.textMid,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    MiniBadge(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: exercise.level.label,
                      color: ExerciseVisuals.levelColor(exercise.level),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onFavoriteToggle != null)
            FavoriteButton(isFavorite: isFavorite, onTap: onFavoriteToggle!)
          else
            Icon(Icons.chevron_right_rounded, color: glass.textLow),
        ],
      ),
    );
  }
}

/// Two-column grid tile: pattern pictogram, name, primary muscle, level dot.
class ExerciseGridTile extends StatelessWidget {
  const ExerciseGridTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExerciseThumb(exercise: exercise, size: 44),
              const Spacer(),
              if (onFavoriteToggle != null)
                FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onFavoriteToggle!,
                ),
            ],
          ),
          const Spacer(),
          Text(
            exercise.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(fontSize: 14, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            exercise.primaryMuscles.first.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                ExerciseVisuals.equipmentIcon(exercise.equipment),
                size: 13,
                color: glass.textLow,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  exercise.equipment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: glass.textLow),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ExerciseVisuals.levelColor(exercise.level),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gradient tile with the movement-pattern pictogram.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({super.key, required this.exercise, this.size = 52});
  final Exercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.primaryBright.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Icon(
        ExerciseVisuals.patternIcon(exercise.pattern),
        color: Colors.white.withValues(alpha: 0.9),
        size: size * 0.46,
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
  });
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return IconButton(
      onPressed: onTap,
      tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
      visualDensity: VisualDensity.compact,
      icon: AnimatedSwitcher(
        duration: AppMotion.fast,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          key: ValueKey(isFavorite),
          color: isFavorite ? AppColors.warning : glass.textLow,
        ),
      ),
    );
  }
}

class MiniBadge extends StatelessWidget {
  const MiniBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
