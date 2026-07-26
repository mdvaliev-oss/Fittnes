import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/exercise.dart';
import '../domain/entities/muscle.dart';
import 'providers/exercise_providers.dart';
import 'widgets/muscle_map.dart';
import 'widgets/technique_viewer.dart';

/// Full technique + coaching detail for a single exercise.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      body: AmbientBackground(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (ex) => ex == null
              ? const Center(child: Text('Упражнение не найдено'))
              : _DetailBody(exercise: ex),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Назад',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: text.headlineMedium),
                    if (exercise.altName != null)
                      Text(exercise.altName!, style: text.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          TechniqueViewer(exercise: exercise),
          const SizedBox(height: AppSpacing.md),

          _MetaRow(exercise: exercise),
          const SizedBox(height: AppSpacing.md),

          if (exercise.description.isNotEmpty) ...[
            Text(exercise.description, style: text.bodyLarge),
            const SizedBox(height: AppSpacing.md),
          ],

          // Muscle map
          _Section(
            title: 'Работающие мышцы',
            child: Column(
              children: [
                MuscleMap(activation: exercise.muscleActivation),
                const SizedBox(height: AppSpacing.sm),
                const _MuscleLegend(),
                const SizedBox(height: AppSpacing.sm),
                _MuscleChips(exercise: exercise),
              ],
            ),
          ),

          if (exercise.instructions.isNotEmpty)
            _Section(
              title: 'Техника выполнения',
              child: _NumberedList(items: exercise.instructions),
            ),

          _TempoBreathing(exercise: exercise),

          if (exercise.tips.isNotEmpty)
            _Section(
              title: 'Советы тренера',
              accent: AppColors.accent,
              child: _BulletList(
                items: exercise.tips,
                icon: Icons.check_circle_rounded,
                color: AppColors.accent,
              ),
            ),

          if (exercise.commonMistakes.isNotEmpty)
            _Section(
              title: 'Типичные ошибки',
              accent: AppColors.warning,
              child: _BulletList(
                items: exercise.commonMistakes,
                icon: Icons.error_rounded,
                color: AppColors.warning,
              ),
            ),

          if (exercise.contraindications.isNotEmpty)
            _Section(
              title: 'Противопоказания',
              accent: AppColors.danger,
              child: _BulletList(
                items: exercise.contraindications,
                icon: Icons.block_rounded,
                color: AppColors.danger,
              ),
            ),

          if (exercise.variations.isNotEmpty)
            _Section(
              title: 'Варианты выполнения',
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final v in exercise.variations) _Pill(label: v),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.accent});
  final String title;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: text.titleLarge?.copyWith(
                color: accent ?? Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Уровень', exercise.level.label),
      ('Оборудование', exercise.equipment.label),
      ('Тип', exercise.category.label),
      if (exercise.mechanic != null) ('Механика', exercise.mechanic!.label),
      if (exercise.force != null) ('Усилие', exercise.force!.label),
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [for (final (k, v) in items) _Pill(label: '$k: $v')],
    );
  }
}

class _TempoBreathing extends StatelessWidget {
  const _TempoBreathing({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final rom = exercise.rangeOfMotion;
    if (exercise.tempo == null && exercise.breathing == null && rom == null) {
      return const SizedBox.shrink();
    }
    return _Section(
      title: 'Темп, дыхание и амплитуда',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.tempo != null)
            _KeyValue(
              icon: Icons.speed_rounded,
              label: 'Темп',
              value: exercise.tempo!,
            ),
          if (exercise.breathing != null)
            _KeyValue(
              icon: Icons.air_rounded,
              label: 'Дыхание',
              value: exercise.breathing!,
            ),
          if (rom != null)
            _KeyValue(
              icon: Icons.open_in_full_rounded,
              label: 'Амплитуда',
              value: rom,
            ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: glass.textMid),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: text.bodyMedium?.copyWith(color: glass.textMid),
          ),
          Expanded(child: Text(value, style: text.bodyLarge)),
        ],
      ),
    );
  }
}

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(items[i], style: text.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.items,
    required this.icon,
    required this.color,
  });
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(item, style: text.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MuscleChips extends StatelessWidget {
  const _MuscleChips({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    Widget group(String title, List<Muscle> muscles, Color color) {
      if (muscles.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall),
            for (final m in muscles) _Pill(label: m.label, color: color),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group('Основные', exercise.primaryMuscles, AppColors.primaryBright),
        group('Второстепенные', exercise.secondaryMuscles, AppColors.primary),
        group('Стабилизаторы', exercise.stabilizers, AppColors.accent),
      ],
    );
  }
}

class _MuscleLegend extends StatelessWidget {
  const _MuscleLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.primaryBright, label: 'Основные'),
        SizedBox(width: AppSpacing.md),
        _LegendDot(color: AppColors.primary, label: 'Второстепенные'),
        SizedBox(width: AppSpacing.md),
        _LegendDot(color: AppColors.accent, label: 'Стабилизаторы'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final c = color ?? glass.textMid;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}
