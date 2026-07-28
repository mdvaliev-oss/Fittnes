import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import 'providers/nutrition_providers.dart';

/// Manual daily goal editor: kcal + macro grams, saved to app settings.
class NutritionTargetsScreen extends ConsumerStatefulWidget {
  const NutritionTargetsScreen({super.key});

  @override
  ConsumerState<NutritionTargetsScreen> createState() =>
      _NutritionTargetsScreenState();
}

class _NutritionTargetsScreenState
    extends ConsumerState<NutritionTargetsScreen> {
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carb;

  static String _n(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    final t = ref.read(nutritionTargetsProvider);
    _kcal = TextEditingController(text: _n(t.kcal));
    _protein = TextEditingController(text: _n(t.proteinG));
    _fat = TextEditingController(text: _n(t.fatG));
    _carb = TextEditingController(text: _n(t.carbG));
  }

  @override
  void dispose() {
    for (final c in [_kcal, _protein, _fat, _carb]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    double? p(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.'));
    ref.read(appSettingsProvider.notifier).setNutritionTargets(
          kcal: p(_kcal),
          protein: p(_protein),
          fat: p(_fat),
          carb: p(_carb),
        );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Назад',
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text('Дневная цель', style: text.headlineLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _Field(
                        controller: _kcal,
                        label: 'Калории',
                        suffix: 'ккал',
                      ),
                      _Field(controller: _protein, label: 'Белки', suffix: 'г'),
                      _Field(controller: _fat, label: 'Жиры', suffix: 'г'),
                      _Field(controller: _carb, label: 'Углеводы', suffix: 'г'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                isDense: true,
                suffixText: suffix,
                suffixStyle: TextStyle(color: glass.textLow, fontSize: 12),
                filled: true,
                fillColor: glass.fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
