import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/app_settings.dart';
import '../theme/app_spacing.dart';
import '../theme/glass_theme.dart';
import '../units/weight_format.dart';

/// Compact two-segment `кг | lb` switch. Purely presentational — the caller
/// decides whether it flips the global setting or a local field.
class WeightUnitToggle extends StatelessWidget {
  const WeightUnitToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  final WeightUnit value;
  final ValueChanged<WeightUnit> onChanged;

  /// Smaller paddings for toolbars and table headers.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Semantics(
      label: 'Единицы веса',
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: glass.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: glass.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final unit in WeightUnit.values)
              _Segment(
                label: unit.short,
                selected: unit == value,
                dense: dense,
                onTap: () {
                  if (unit == value) return;
                  HapticFeedback.selectionClick();
                  onChanged(unit);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.xs : AppSpacing.sm,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: selected
              ? glass.accent.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: dense ? 11.5 : 13,
            fontWeight: FontWeight.w700,
            color: selected ? glass.accent : glass.textMid,
          ),
        ),
      ),
    );
  }
}
