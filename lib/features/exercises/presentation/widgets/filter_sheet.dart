import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/exercise_enums.dart';
import '../providers/exercise_providers.dart';

/// Opens the secondary facets (equipment / level / mechanic / favorites).
Future<void> showExerciseFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceHigh,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => const ExerciseFilterSheet(),
  );
}

class ExerciseFilterSheet extends ConsumerWidget {
  const ExerciseFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(exerciseFilterProvider);
    final notifier = ref.read(exerciseFilterProvider.notifier);
    final text = Theme.of(context).textTheme;
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Фильтры', style: text.titleLarge)),
              if (filter.activeFacetCount > 0 || filter.favoritesOnly)
                TextButton(
                  onPressed: () {
                    notifier.clearFacets();
                    if (filter.favoritesOnly) notifier.toggleFavorites();
                  },
                  child: const Text('Сбросить'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: filter.favoritesOnly,
            onChanged: (_) => notifier.toggleFavorites(),
            secondary: const Icon(Icons.star_rounded, color: AppColors.warning),
            title: Text('Только избранные', style: text.bodyLarge),
          ),
          _FacetChips<Equipment>(
            label: 'Оборудование',
            values: Equipment.values,
            labelOf: (e) => e.label,
            selected: filter.equipment,
            onToggle: notifier.toggleEquipment,
          ),
          _FacetChips<ExperienceLevel>(
            label: 'Уровень',
            values: ExperienceLevel.values,
            labelOf: (l) => l.label,
            selected: filter.level,
            onToggle: notifier.toggleLevel,
          ),
          _FacetChips<Mechanic>(
            label: 'Тип движения',
            values: Mechanic.values,
            labelOf: (m) => m.label,
            selected: filter.mechanic,
            onToggle: notifier.toggleMechanic,
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Показать',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Center(
            child: Text(
              'Фильтры применяются сразу',
              style: text.labelSmall?.copyWith(color: glass.textLow),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacetChips<T> extends StatelessWidget {
  const _FacetChips({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(labelOf(v)),
                  selected: v == selected,
                  onSelected: (_) => onToggle(v),
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: v == selected ? Colors.white : glass.textMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  backgroundColor: glass.fill,
                  selectedColor: AppColors.primary,
                  side: BorderSide(
                    color: v == selected ? Colors.transparent : glass.border,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
