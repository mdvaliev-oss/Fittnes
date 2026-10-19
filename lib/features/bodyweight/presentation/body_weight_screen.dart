import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/units/weight_format.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/body_weight_series.dart';
import '../domain/entities/body_weight_entry.dart';
import 'providers/body_weight_providers.dart';
import 'widgets/body_weight_chart.dart';
import 'widgets/body_weight_sheet.dart';

/// Full-screen body-weight log: headline, chart and the editable history.
class BodyWeightScreen extends ConsumerWidget {
  const BodyWeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;
    final unit = ref.watch(appSettingsProvider.select((s) => s.unit));
    final history = ref.watch(bodyWeightHistoryProvider);

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xs,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Назад',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Вес тела', style: text.headlineLarge),
                  ],
                ),
              ),
              Expanded(
                child: history.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data: (entries) => ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      120,
                    ),
                    children: [
                      _Headline(entries: entries, unit: unit),
                      const SizedBox(height: AppSpacing.md),
                      GlassCard(
                        child: BodyWeightChart(
                          points: bodyWeightChartPoints(entries),
                          unit: unit,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Записей пока нет. Нажми «Записать вес» — можно '
                            'вводить в кг или lb, хранится всё в кг.',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium,
                          ),
                        )
                      else ...[
                        Text('История', style: text.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        for (var i = 0; i < entries.length; i++)
                          _EntryTile(
                            entry: entries[i],
                            previous:
                                i + 1 < entries.length ? entries[i + 1] : null,
                            unit: unit,
                            onDelete: () => ref
                                .read(bodyWeightActionsProvider)
                                .delete(entries[i].id),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: PrimaryButton(
        label: 'Записать вес',
        icon: Icons.add_rounded,
        expand: false,
        onPressed: () => showBodyWeightSheet(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: glass.fill.withValues(alpha: 0),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.entries, required this.unit});
  final List<BodyWeightEntry> entries;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final summary = summarizeBodyWeight(entries);
    final latest = summary.latest;

    return GlassCard(
      gradientBorder: true,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сейчас', style: text.labelSmall),
                const SizedBox(height: 2),
                Text(
                  latest == null ? '—' : formatWeight(latest.kg, unit),
                  style: AppTypography.numeric(glass.textHi, size: 32),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('За 30 дней', style: text.labelSmall),
              const SizedBox(height: 2),
              _Delta(kg: summary.change, unit: unit, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.previous,
    required this.unit,
    required this.onDelete,
  });

  final BodyWeightEntry entry;
  final BodyWeightEntry? previous;
  final WeightUnit unit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final d = entry.measuredAt;

    return Dismissible(
      key: ValueKey('bw-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${d.day.toString().padLeft(2, '0')}.'
                  '${d.month.toString().padLeft(2, '0')}.${d.year}',
                  style: text.bodyLarge,
                ),
              ),
              _Delta(
                kg: previous == null ? null : entry.kg - previous!.kg,
                unit: unit,
                size: 13,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                formatWeight(entry.kg, unit),
                style: AppTypography.numeric(glass.textHi, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signed weight change, coloured by direction (loss is mint, gain is warm).
class _Delta extends StatelessWidget {
  const _Delta({required this.kg, required this.unit, required this.size});
  final double? kg;
  final WeightUnit unit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final v = kg;
    if (v == null) {
      return Text('—', style: AppTypography.numeric(glass.textLow, size: size));
    }
    final rounded = double.parse(unit.fromKg(v).toStringAsFixed(unit.decimals));
    final color = rounded == 0
        ? glass.textMid
        : rounded < 0
            ? AppColors.accent
            : AppColors.warning;
    final sign = rounded > 0 ? '+' : '';
    // `abs()` keeps a sub-resolution loss from rendering as "-0".
    return Text(
      '$sign${formatWeight(rounded == 0 ? 0 : v, unit)}',
      style: AppTypography.numeric(color, size: size),
    );
  }
}
