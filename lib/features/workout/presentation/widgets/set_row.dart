import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/units/weight_format.dart';
import '../../domain/entities/set_type.dart';
import '../../domain/entities/workout_set.dart';
import '../providers/active_workout_controller.dart';
import '../providers/rest_timer_controller.dart';
import 'effort_picker_sheet.dart';

/// One editable set row: type badge · previous hint · weight · reps · effort ·
/// complete. Completing a set kicks off the rest timer.
class SetRow extends ConsumerStatefulWidget {
  const SetRow({
    super.key,
    required this.entryId,
    required this.set,
    required this.index,
    required this.restSeconds,
    this.previousHint,
  });

  final int entryId;
  final WorkoutSet set;
  final int index;
  final int restSeconds;

  /// e.g. "80×8" from last workout — shown as a target hint.
  final String? previousHint;

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow> {
  // Weight is stored in kg; the field shows/edits it in the user's unit.
  late final WeightUnit _unit = ref.read(appSettingsProvider).unit;
  late final TextEditingController _weight = TextEditingController(
    text: widget.set.weight == null
        ? ''
        : formatValue(_unit.fromKg(widget.set.weight!), _unit),
  );
  late final TextEditingController _reps =
      TextEditingController(text: widget.set.reps?.toString() ?? '');

  static String _fmt(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  ActiveWorkoutController get _controller =>
      ref.read(activeWorkoutControllerProvider.notifier);

  void _commitWeight(String raw) {
    final v = double.tryParse(raw.replaceAll(',', '.'));
    if (v != null) {
      _controller.updateSet(
        widget.entryId,
        widget.set.id,
        weight: _unit.toKg(v),
      );
    }
  }

  void _commitReps(String raw) {
    final v = int.tryParse(raw);
    if (v != null) {
      _controller.updateSet(widget.entryId, widget.set.id, reps: v);
    }
  }

  void _toggleComplete() {
    _controller.toggleSetComplete(widget.entryId, widget.set.id);
    final nowComplete = !widget.set.isCompleted;
    if (nowComplete) {
      HapticFeedback.selectionClick();
      ref.read(restTimerProvider.notifier).start(widget.restSeconds);
    }
  }

  Future<void> _pickEffort() async {
    final result = await showEffortPicker(
      context,
      rpe: widget.set.rpe,
      rir: widget.set.rir,
    );
    if (result == null) return;
    _controller.setEffort(
      widget.entryId,
      widget.set.id,
      rpe: result.rpe,
      rir: result.rir,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final set = widget.set;
    final done = set.isCompleted;

    return Dismissible(
      key: ValueKey('set-${set.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: AppColors.danger.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => _controller.removeSet(widget.entryId, set.id),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding:
            const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: done
              ? AppColors.accent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          children: [
            _TypeBadge(
              set: set,
              index: widget.index,
              onTap: () => _controller.cycleSetType(widget.entryId, set.id),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 3,
              child: _NumField(
                controller: _weight,
                hint: _weightHint,
                suffix: _unit.label,
                decimal: true,
                onChanged: _commitWeight,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              flex: 2,
              child: _NumField(
                controller: _reps,
                hint: _repsHint,
                suffix: '×',
                decimal: false,
                onChanged: _commitReps,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 46,
              child: TextButton(
                onPressed: _pickEffort,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: glass.textMid,
                ),
                child:
                    Text(_effortLabel, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
            IconButton(
              onPressed: _toggleComplete,
              icon: Icon(
                done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: done ? AppColors.accent : glass.textLow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? get _weightHint {
    final raw = widget.previousHint?.split('×').first;
    if (raw == null) return null;
    final kg = double.tryParse(raw);
    return kg == null ? raw : formatValue(_unit.fromKg(kg), _unit);
  }

  String? get _repsHint => widget.previousHint != null
      ? (widget.previousHint!.split('×').length > 1
          ? widget.previousHint!.split('×')[1]
          : null)
      : null;

  String get _effortLabel {
    final set = widget.set;
    if (set.rpe != null) return '@${_fmt(set.rpe)}';
    if (set.rir != null) return '${set.rir}rir';
    return 'RPE';
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.set,
    required this.index,
    required this.onTap,
  });
  final WorkoutSet set;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNormal = set.type == SetType.normal;
    final color = switch (set.type) {
      SetType.warmup => AppColors.warning,
      SetType.dropset => AppColors.primaryBright,
      SetType.failure => AppColors.danger,
      SetType.normal => AppColors.primary,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          isNormal ? '$index' : set.type.badge,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.decimal,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final String suffix;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(decimal ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: glass.textLow),
        suffixText: suffix,
        suffixStyle: TextStyle(color: glass.textLow, fontSize: 12),
        filled: true,
        fillColor: glass.fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
