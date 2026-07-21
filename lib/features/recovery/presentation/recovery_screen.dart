import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../exercises/domain/entities/muscle.dart';
import '../../exercises/presentation/widgets/muscle_map.dart';
import '../domain/recovery_model.dart';
import 'recovery_providers.dart';

/// Visualises per-muscle recovery on the body heat-map.
class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(muscleRecoveryProvider);
    final text = Theme.of(context).textTheme;

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
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Text('Восстановление', style: text.headlineLarge),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data: (recovery) => recovery.fatigue.isEmpty
                      ? const _EmptyRecovery()
                      : _RecoveryBody(recovery: recovery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryBody extends StatelessWidget {
  const _RecoveryBody({required this.recovery});
  final MuscleRecovery recovery;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;
    final readiness = (recovery.overallReadiness * 100).round();

    final colors = {
      for (final e in recovery.fatigue.entries) e.key: recoveryHeatColor(e.value),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        GlassCard(
          gradientBorder: true,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Готовность тела', style: text.bodyMedium),
                  Text('$readiness%', style: AppTypography.numeric(glass.accent, size: 32)),
                ],
              ),
              const Spacer(),
              const _Legend(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: MuscleBodyMap(muscleColors: colors),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('По группам мышц', style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final entry in recovery.byFatigue)
          _MuscleRecoveryRow(muscle: entry.key, fatigue: entry.value),
      ],
    );
  }
}

class _MuscleRecoveryRow extends StatelessWidget {
  const _MuscleRecoveryRow({required this.muscle, required this.fatigue});
  final Muscle muscle;
  final double fatigue;

  @override
  Widget build(BuildContext context) {
    final recovery = 1 - fatigue;
    final color = recoveryHeatColor(fatigue);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(muscle.label, style: text.bodyLarge)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: recovery,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 40,
            child: Text(
              '${(recovery * 100).round()}%',
              textAlign: TextAlign.right,
              style: text.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: AppColors.accent, label: 'Восстановлено'),
        SizedBox(height: 4),
        _LegendDot(color: AppColors.warning, label: 'Частично'),
        SizedBox(height: 4),
        _LegendDot(color: AppColors.danger, label: 'Устал'),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _EmptyRecovery extends StatelessWidget {
  const _EmptyRecovery();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa_rounded, size: 48, color: glass.textLow),
            const SizedBox(height: AppSpacing.md),
            Text('Мышцы свежие', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text('За последние 7 дней тренировок нет — можно бить по любой группе.',
                textAlign: TextAlign.center, style: text.bodyMedium,),
          ],
        ),
      ),
    );
  }
}
