import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ambient_background.dart';

/// Result of the effort picker.
typedef EffortSelection = ({double? rpe, int? rir});

/// Bottom sheet to pick RPE (6–10, 0.5 steps) and/or RIR (0–5).
Future<EffortSelection?> showEffortPicker(
  BuildContext context, {
  double? rpe,
  int? rir,
}) {
  return showModalBottomSheet<EffortSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _EffortSheet(rpe: rpe, rir: rir),
  );
}

class _EffortSheet extends StatefulWidget {
  const _EffortSheet({this.rpe, this.rir});
  final double? rpe;
  final int? rir;

  @override
  State<_EffortSheet> createState() => _EffortSheetState();
}

class _EffortSheetState extends State<_EffortSheet> {
  late double? _rpe = widget.rpe;
  late int? _rir = widget.rir;

  static const _rpeValues = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
  static const _rirValues = [0, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      child: AmbientBackground(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Оценка усилия', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                Text('RPE', style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final v in _rpeValues)
                      _Chip(
                        label: v.toStringAsFixed(v % 1 == 0 ? 0 : 1),
                        selected: _rpe == v,
                        onTap: () =>
                            setState(() => _rpe = _rpe == v ? null : v),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('RIR (запас повторений)', style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final v in _rirValues)
                      _Chip(
                        label: '$v',
                        selected: _rir == v,
                        onTap: () =>
                            setState(() => _rir = _rir == v ? null : v),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pop(context, (rpe: null, rir: null)),
                        child: const Text('Сбросить'),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, (rpe: _rpe, rir: _rir)),
                        child: const Text('Готово'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
