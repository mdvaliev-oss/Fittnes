import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../workout/domain/services/workout_stats.dart';
import '../../workout/presentation/providers/active_workout_controller.dart';
import '../../workout/presentation/providers/workout_providers.dart';

/// Home dashboard.
///
/// Renders the design system end-to-end; the "start workout" CTA launches the
/// active-workout flow. Progress/history stats are wired in Module 3.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _startWorkout(BuildContext context, WidgetRef ref) {
    ref
        .read(activeWorkoutControllerProvider.notifier)
        .start(title: 'Push Day · Грудь и Трицепс');
    context.push(AppRoutes.activeWorkout);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl * 2,
          ),
          children: [
            // ── Greeting ──────────────────────────────────────────
            Text('Добро пожаловать', style: text.bodyMedium),
            Text('Готов к тренировке?', style: text.headlineLarge),
            const SizedBox(height: AppSpacing.lg),

            // ── Today's workout hero card ─────────────────────────
            GlassCard(
              gradientBorder: true,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: glass.accent, size: 20),
                      const SizedBox(width: AppSpacing.xs),
                      Text('СЕГОДНЯ',
                          style: text.labelSmall?.copyWith(
                            color: glass.accent,
                            letterSpacing: 1.2,
                          )),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Push Day · Грудь и Трицепс',
                      style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('6 упражнений · ~55 мин', style: text.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Начать тренировку',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _startWorkout(context, ref),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              onTap: () => context.push(AppRoutes.programs),
              child: Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded, color: glass.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Программы тренировок', style: text.titleLarge?.copyWith(fontSize: 16)),
                        Text('Full Body · Upper/Lower · PPL', style: text.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: glass.textLow),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Text('Обзор', style: text.titleLarge)),
                TextButton(
                  onPressed: () => context.push(AppRoutes.history),
                  child: const Text('История'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Stats grid (live from workout history) ────────────
            _StatsGrid(stats: ref.watch(workoutStatsProvider)),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final AsyncValue<WorkoutStats> stats;

  @override
  Widget build(BuildContext context) {
    final s = stats.valueOrNull ?? WorkoutStats.empty;
    String n(num v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.6,
      children: [
        StatTile(
          label: 'Серия',
          value: '${s.streakDays}',
          unit: 'дн.',
          icon: Icons.local_fire_department_rounded,
        ),
        StatTile(
          label: 'Тоннаж за неделю',
          value: n(s.weeklyTonnage / 1000),
          unit: 'т',
          icon: Icons.scale_rounded,
        ),
        StatTile(
          label: 'Тренировок',
          value: '${s.totalWorkouts}',
          icon: Icons.calendar_month_rounded,
        ),
        StatTile(
          label: 'Лучший e1RM',
          value: n(s.bestE1rm),
          unit: 'кг',
          icon: Icons.emoji_events_rounded,
          accent: s.bestE1rm > 0,
        ),
      ],
    );
  }
}
