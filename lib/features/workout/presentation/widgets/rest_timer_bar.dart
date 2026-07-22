import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/widgets/glass_card.dart';
import '../providers/rest_timer_controller.dart';

/// Floating rest-countdown bar shown while the timer is active.
///
/// Animated progress ring + remaining time + quick ±15s / skip controls.
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerProvider);
    final controller = ref.read(restTimerProvider.notifier);

    return AnimatedSwitcher(
      duration: AppMotion.base,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !state.isActive
          ? const SizedBox.shrink()
          : Padding(
              key: const ValueKey('rest-timer'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: GlassCard(
                gradientBorder: true,
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: state.progress),
                            duration: AppMotion.fast,
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent,
                              ),
                            ),
                          ),
                          const Icon(Icons.timer_rounded, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Отдых  ${formatSeconds(state.remaining)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFeatures: const [],
                      ),
                    ),
                    const Spacer(),
                    _MiniAction(
                      label: '-15',
                      onTap: () => controller.addSeconds(-15),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _MiniAction(
                      label: '+15',
                      onTap: () => controller.addSeconds(15),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _MiniAction(
                      label: 'Пропустить',
                      onTap: controller.skip,
                      accent: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.onTap,
    this.accent = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: accent ? AppColors.accent : Colors.white,
          ),
        ),
      ),
    );
  }
}
