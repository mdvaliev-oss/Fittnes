import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../../../core/units/weight_format.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/weight_unit_toggle.dart';
import '../providers/body_weight_providers.dart';

/// Opens the "record body weight" sheet. Resolves with the saved kg value,
/// or `null` if dismissed.
Future<double?> showBodyWeightSheet(BuildContext context) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => const BodyWeightSheet(),
  );
}

/// Weight input with an inline `кг | lb` switch. Whatever unit is chosen, the
/// value is converted and stored in kilograms.
class BodyWeightSheet extends ConsumerStatefulWidget {
  const BodyWeightSheet({super.key});

  @override
  ConsumerState<BodyWeightSheet> createState() => _BodyWeightSheetState();
}

class _BodyWeightSheetState extends ConsumerState<BodyWeightSheet> {
  late WeightUnit _unit = ref.read(appSettingsProvider).unit;
  late final TextEditingController _value = TextEditingController(
    text: _seed(ref.read(bodyWeightSummaryProvider).latest?.kg),
  );
  DateTime _date = DateTime.now();
  bool _saving = false;

  String _seed(double? kg) =>
      kg == null ? '' : formatValue(_unit.fromKg(kg), _unit);

  double? get _parsed => double.tryParse(_value.text.replaceAll(',', '.'));

  /// The value the user typed, converted to canonical kilograms.
  double? get _kg {
    final v = _parsed;
    return v == null || v <= 0 ? null : _unit.toKg(v);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _switchUnit(WeightUnit next) {
    // Keep the physical weight the same, just re-express it.
    final kg = _kg;
    setState(() {
      _unit = next;
      if (kg != null) _value.text = formatValue(next.fromKg(kg), next);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final kg = _kg;
    if (kg == null || _saving) return;
    setState(() => _saving = true);
    await ref.read(bodyWeightActionsProvider).add(kg: kg, at: _date);
    await HapticFeedback.lightImpact();
    if (mounted) Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final kg = _kg;
    final hint = kg == null
        ? null
        : _unit == WeightUnit.lb
            ? '= ${formatWeight(kg, WeightUnit.kg)}'
            : '= ${formatWeight(kg, WeightUnit.lb)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Записать вес', style: text.titleLarge)),
              WeightUnitToggle(value: _unit, onChanged: _switchUnit),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _value,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTypography.numeric(glass.textHi, size: 40),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: _unit.short,
              suffixStyle: TextStyle(color: glass.textMid, fontSize: 18),
              filled: true,
              fillColor: glass.fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Text(
              hint ?? ' ',
              key: ValueKey(hint),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: glass.textMid),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 18, color: glass.textMid),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: _pickDate,
                child: Text(_dateLabel(_date)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Сохранить',
            icon: Icons.check_rounded,
            onPressed: kg == null || _saving ? null : _save,
          ),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) return 'Сегодня';
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
