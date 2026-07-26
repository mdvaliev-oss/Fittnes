import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/units/weight_format.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/domain/entities/workout_session.dart';
import '../../workout/presentation/providers/workout_providers.dart';
import '../domain/progress_series.dart';
import 'providers/progress_providers.dart';
import 'widgets/strength_line_chart.dart';
import 'widgets/tonnage_bar_chart.dart';

/// Progress dashboard: tonnage, strength progression and personal records.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (sessions) => sessions.isEmpty
              ? const _EmptyProgress()
              : _ProgressBody(sessions: sessions),
        ),
      ),
    );
  }
}

class _ProgressBody extends ConsumerWidget {
  const _ProgressBody({required this.sessions});
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final unit = ref.watch(appSettingsProvider.select((s) => s.unit));
    final exercises = exercisesInHistory(sessions);
    final selectedId = ref.watch(selectedProgressExerciseProvider) ??
        (exercises.isNotEmpty ? exercises.first.id : null);
    final tonnage = tonnageSeries(sessions);
    final strength = selectedId == null
        ? const <StrengthPoint>[]
        : strengthSeries(sessions, selectedId);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workoutHistoryProvider);
        await ref.read(workoutHistoryProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl * 2,
        ),
        children: [
          Text('Прогресс', style: text.headlineLarge),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            title: 'Тоннаж по тренировкам',
            child: TonnageBarChart(points: tonnage),
          ),
          const SizedBox(height: AppSpacing.md),
          _ChartCard(
            title: 'Рост силы (e1RM)',
            trailing: exercises.isEmpty
                ? null
                : _ExercisePicker(
                    exercises: exercises,
                    selectedId: selectedId,
                    onChanged: (id) => ref
                        .read(selectedProgressExerciseProvider.notifier)
                        .state = id,
                  ),
            child: StrengthLineChart(points: strength),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Личные рекорды', style: text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          ...ref
              .watch(personalRecordsProvider)
              .map((r) => _RecordTile(record: r, unit: unit)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: trailing,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ExercisePicker extends StatelessWidget {
  const _ExercisePicker({
    required this.exercises,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ExerciseRef> exercises;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        isDense: true,
        isExpanded: true,
        dropdownColor: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.button),
        style: TextStyle(color: glass.textHi, fontSize: 13),
        icon: Icon(Icons.expand_more_rounded, color: glass.textMid),
        selectedItemBuilder: (context) => [
          for (final e in exercises)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                e.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
        ],
        items: [
          for (final e in exercises)
            DropdownMenuItem(
              value: e.id,
              child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.unit});
  final PersonalRecord record;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                record.name,
                style: text.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatWeight(record.e1rm, unit),
              style: AppTypography.numeric(glass.accent, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  const _EmptyProgress();

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
            Icon(Icons.insights_rounded, size: 48, color: glass.textLow),
            const SizedBox(height: AppSpacing.md),
            Text('Здесь появится прогресс', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Заверши несколько тренировок — построим графики силы и тоннажа.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
