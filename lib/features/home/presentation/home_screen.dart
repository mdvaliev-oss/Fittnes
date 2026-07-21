import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/stat_tile.dart';

/// Home dashboard.
///
/// Module 0 renders the layout with placeholder data so the design system is
/// visible end-to-end; Module 2+ wires real workout/progress providers in.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () {}, // wired in Module 2
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

            const SizedBox(height: AppSpacing.lg),
            Text('Обзор', style: text.titleLarge),
            const SizedBox(height: AppSpacing.sm),

            // ── Stats grid ────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.6,
              children: const [
                StatTile(
                  label: 'Серия',
                  value: '12',
                  unit: 'дн.',
                  icon: Icons.local_fire_department_rounded,
                ),
                StatTile(
                  label: 'Тоннаж за неделю',
                  value: '18.4',
                  unit: 'т',
                  icon: Icons.scale_rounded,
                ),
                StatTile(
                  label: 'Тренировок',
                  value: '48',
                  icon: Icons.calendar_month_rounded,
                ),
                StatTile(
                  label: 'Новый PR',
                  value: '140',
                  unit: 'кг',
                  icon: Icons.emoji_events_rounded,
                  accent: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
