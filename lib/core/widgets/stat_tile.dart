import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/glass_theme.dart';
import 'glass_card.dart';

/// Compact metric tile for the home dashboard (tonnage, streak, PR, …).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? unit;
  final IconData? icon;

  /// Highlights the value in the accent (mint) color — e.g. a new PR.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final valueColor = accent ? glass.accent : glass.textHi;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: glass.textMid),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.numeric(valueColor, size: 24),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: glass.textMid),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: glass.textLow),
          ),
        ],
      ),
    );
  }
}
