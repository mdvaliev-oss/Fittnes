import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../domain/entities/food_entry.dart';
import '../domain/entities/food_item.dart';
import '../domain/entities/meal_type.dart';
import '../domain/nutrition_math.dart';
import 'providers/nutrition_providers.dart';

/// Search the catalog + custom foods and log a portion into a meal.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, required this.day, required this.meal});

  final DateTime day;
  final MealType meal;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;
    final foods = ref.watch(allFoodsProvider);

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
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Назад',
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text('Добавить', style: text.headlineMedium),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Поиск продукта…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: glass.fill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.customFood),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Создать свой продукт'),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: foods.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data: (all) {
                    final q = _query.toLowerCase();
                    final list = q.isEmpty
                        ? all
                        : all
                            .where((f) => f.name.toLowerCase().contains(q))
                            .toList();
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: glass.textMid),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xxl,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) => _FoodRow(
                        food: list[i],
                        onTap: () => _pickPortion(list[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPortion(FoodItem food) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortionSheet(food: food, meal: widget.meal),
    );
    if (added == true && mounted) {
      await Navigator.of(context).maybePop();
    }
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.food, required this.onTap});
  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(food.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${food.kcalPer100.round()} ккал · Б${food.proteinPer100.round()} '
        'Ж${food.fatPer100.round()} У${food.carbPer100.round()} / 100 г',
        style: TextStyle(color: glass.textMid, fontSize: 12),
      ),
      trailing: food.isCustom
          ? Icon(Icons.person_rounded, size: 16, color: glass.textLow)
          : null,
      onTap: onTap,
    );
  }
}

/// Bottom sheet: choose grams + meal, preview macros, confirm.
class _PortionSheet extends ConsumerStatefulWidget {
  const _PortionSheet({required this.food, required this.meal});
  final FoodItem food;
  final MealType meal;

  @override
  ConsumerState<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends ConsumerState<_PortionSheet> {
  final _grams = TextEditingController(text: '100');
  late MealType _meal = widget.meal;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  double get _g => double.tryParse(_grams.text.replaceAll(',', '.')) ?? 0;

  Future<void> _add() async {
    final grams = _g;
    if (grams <= 0) return;
    final m = macrosFor(widget.food, grams);
    final now = DateTime.now();
    final entry = FoodEntry(
      day: _dayOnly(),
      meal: _meal,
      name: widget.food.name,
      grams: grams,
      kcal: m.kcal,
      protein: m.protein,
      fat: m.fat,
      carb: m.carb,
      createdAt: now,
    );
    await ref.read(nutritionRepositoryProvider).addEntry(entry);
    ref.invalidate(dailyNutritionProvider);
    ref.invalidate(todayNutritionProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  DateTime _dayOnly() {
    final d = ref.read(selectedNutritionDateProvider);
    return DateTime(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final m = macrosFor(widget.food, _g);
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
          border: Border.all(color: glass.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.food.name, style: text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _grams,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      suffixText: 'г',
                      filled: true,
                      fillColor: glass.fill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<MealType>(
                    initialValue: _meal,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: glass.fill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      for (final meal in MealType.values)
                        DropdownMenuItem(value: meal, child: Text(meal.label)),
                    ],
                    onChanged: (v) => setState(() => _meal = v ?? _meal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${m.kcal.round()} ккал · Б ${m.protein.round()} · '
              'Ж ${m.fat.round()} · У ${m.carb.round()}',
              style: TextStyle(color: glass.textHi, fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Добавить'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
