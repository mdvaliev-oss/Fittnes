import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/widgets/pressable_scale.dart';

/// Stepper + presets for the default rest between sets. Writes straight to
/// [AppSettings.defaultRestSeconds]; used in Profile and from the timer bar.
class RestDurationPicker extends ConsumerWidget {
  const RestDurationPicker({super.key, this.compact = false});

  /// Tighter layout for the bottom sheet.
  final bool compact;

  static const _presets = [60, 90, 120, 180];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds =
        ref.watch(appSettingsProvider.select((s) => s.defaultRestSeconds));
    final notifier = ref.read(appSettingsProvider.notifier);
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    void set(int v) {
      HapticFeedback.selectionClick();
      notifier.setDefaultRestSeconds(v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Отдых между подходами', style: text.bodyLarge),
            ),
            _StepButton(
              icon: Icons.remove_rounded,
              enabled: seconds > AppSettings.minRestSeconds,
              onTap: () => set(seconds - AppSettings.restStep),
            ),
            SizedBox(
              width: 64,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.9, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  formatSeconds(seconds),
                  key: ValueKey(seconds),
                  textAlign: TextAlign.center,
                  style: AppTypography.numeric(glass.textHi, size: 20),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              enabled: seconds < AppSettings.maxRestSeconds,
              onTap: () => set(seconds + AppSettings.restStep),
            ),
          ],
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text(formatSeconds(p)),
                selected: p == seconds,
                onSelected: (_) => set(p),
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: p == seconds ? Colors.white : glass.textMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: glass.fill,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: p == seconds ? Colors.transparent : glass.border,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return PressableScale(
      enabled: enabled,
      scale: 0.9,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: glass.fill,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: glass.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? glass.textHi : glass.textLow,
        ),
      ),
    );
  }
}

/// Bottom sheet wrapper used from the rest-timer bar during a workout.
Future<void> showRestDurationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Таймер отдыха', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const RestDurationPicker(compact: true),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Применяется к упражнениям, которые добавишь дальше. '
            'Текущий отсчёт можно подправить кнопками ±15.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: context.glass.textLow),
          ),
        ],
      ),
    ),
  );
}
