import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/workout_session.dart';
import 'providers/workout_providers.dart';

/// Chronological list of finished sessions.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
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
                    Text('История', style: text.headlineLarge),
                  ],
                ),
              ),
              Expanded(
                child: history.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data: (sessions) => sessions.isEmpty
                      ? const _EmptyHistory()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xxl,
                          ),
                          itemCount: sessions.length,
                          itemBuilder: (context, i) =>
                              _SessionCard(session: sessions[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(session.title, style: text.titleLarge)),
                Text(_formatDate(session.startedAt), style: text.labelSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _Metric(
                  icon: Icons.timer_outlined,
                  value: formatClock(session.elapsed()),
                ),
                const SizedBox(width: AppSpacing.md),
                _Metric(
                  icon: Icons.scale_rounded,
                  value: '${session.totalVolume.toStringAsFixed(0)} кг',
                ),
                const SizedBox(width: AppSpacing.md),
                _Metric(
                  icon: Icons.repeat_rounded,
                  value: '${session.totalSets} подх.',
                ),
              ],
            ),
            if (session.entries.isNotEmpty) ...[
              Divider(color: glass.border, height: AppSpacing.lg),
              ...session.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(e.exerciseName,
                            style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${e.sets.length}×', style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: glass.textMid),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.numeric(glass.textHi, size: 15)),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 48, color: glass.textLow),
          const SizedBox(height: AppSpacing.md),
          Text('Пока нет тренировок', style: text.titleLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text('Завершите первую тренировку — она появится здесь.',
              style: text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
