import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';

/// A horizontally scrollable row of selectable filter chips.
class FilterChipRow<T> extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onToggle,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final value = values[i];
          final isSel = value == selected;
          return GestureDetector(
            onTap: () => onToggle(value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSel ? null : glass.fill,
                gradient: isSel ? AppColors.primaryGradient : null,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isSel ? Colors.transparent : glass.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                labelOf(value),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : glass.textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
