import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/food_item.dart';
import 'providers/nutrition_providers.dart';

/// Create or edit a custom food (macros per 100 g). Pass [existing] to edit.
class CustomFoodEditor extends ConsumerStatefulWidget {
  const CustomFoodEditor({super.key, this.existing});

  final FoodItem? existing;

  @override
  ConsumerState<CustomFoodEditor> createState() => _CustomFoodEditorState();
}

class _CustomFoodEditorState extends ConsumerState<CustomFoodEditor> {
  late final TextEditingController _name;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carb;

  static String _n(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _kcal = TextEditingController(text: e == null ? '' : _n(e.kcalPer100));
    _protein =
        TextEditingController(text: e == null ? '' : _n(e.proteinPer100));
    _fat = TextEditingController(text: e == null ? '' : _n(e.fatPer100));
    _carb = TextEditingController(text: e == null ? '' : _n(e.carbPer100));
  }

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _fat, _carb]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите название продукта')),
      );
      return;
    }
    final food = FoodItem(
      id: widget.existing?.id ?? '',
      name: name,
      kcalPer100: _num(_kcal),
      proteinPer100: _num(_protein),
      fatPer100: _num(_fat),
      carbPer100: _num(_carb),
      isCustom: true,
    );
    await ref.read(nutritionRepositoryProvider).saveCustomFood(food);
    ref.invalidate(customFoodsProvider);
    if (mounted) await Navigator.of(context).maybePop();
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
                  Expanded(
                    child: Text(
                      widget.existing == null ? 'Новый продукт' : 'Продукт',
                      style: text.headlineMedium,
                    ),
                  ),
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
                        controller: _name,
                        label: 'Название',
                        number: false,
                      ),
                      const Divider(height: AppSpacing.lg),
                      Text(
                        'На 100 г:',
                        style: text.labelMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
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
    this.suffix,
    this.number = true,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool number;

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
            width: number ? 120 : 200,
            child: TextField(
              controller: controller,
              textAlign: number ? TextAlign.right : TextAlign.start,
              keyboardType: number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: number
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                  : null,
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
