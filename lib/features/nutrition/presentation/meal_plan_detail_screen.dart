import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/food_item.dart';
import '../domain/entities/meal_plan.dart';
import '../domain/entities/meal_type.dart';
import '../domain/nutrition_math.dart';
import 'nutrition_screen.dart' show dayLabel;
import 'providers/nutrition_providers.dart';

/// A single meal plan: meal-by-meal breakdown + "apply to day" (replaces the
/// selected day's entries with this menu).
class MealPlanDetailScreen extends ConsumerWidget {
  const MealPlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final plans = ref.watch(mealPlansProvider).valueOrNull ?? const [];
    final catalog = ref.watch(foodCatalogByIdProvider).valueOrNull ?? const {};
    final day = ref.watch(selectedNutritionDateProvider);
    final plan = plans.where((p) => p.id == planId).firstOrNull;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: plan == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xxl * 2,
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
                          child: Text(plan.title, style: text.headlineMedium),
                        ),
                      ],
                    ),
                    if (plan.subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          plan.subtitle,
                          style: text.bodyMedium
                              ?.copyWith(color: context.glass.textMid),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    _TotalCard(plan: plan, catalog: catalog),
                    const SizedBox(height: AppSpacing.sm),
                    for (final meal in MealType.values)
                      if (plan.ofMeal(meal).isNotEmpty)
                        _MealCard(
                          meal: meal,
                          items: plan.ofMeal(meal),
                          catalog: catalog,
                        ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: FilledButton.icon(
                        onPressed: () =>
                            _apply(context, ref, plan, catalog, day),
                        icon: const Icon(Icons.playlist_add_check_rounded),
                        label: Text('Применить на ${dayLabel(day)}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        0,
                      ),
                      child: Text(
                        'Заменит все приёмы за выбранный день в дневнике.',
                        textAlign: TextAlign.center,
                        style: text.labelSmall
                            ?.copyWith(color: context.glass.textLow),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    MealPlan plan,
    Map<String, FoodItem> catalog,
    DateTime day,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Применить меню?'),
        content: Text(
          'Все приёмы за ${dayLabel(day)} будут заменены продуктами этого меню.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Заменить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = ref.read(nutritionRepositoryProvider);
    await repo.clearDay(day);
    for (final entry in resolveMealPlan(plan, catalog, day)) {
      await repo.addEntry(entry);
    }
    ref
      ..invalidate(dailyNutritionProvider)
      ..invalidate(todayNutritionProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Меню «${plan.title}» применено')),
    );
    context.go(AppRoutes.nutrition);
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.plan, required this.catalog});
  final MealPlan plan;
  final Map<String, FoodItem> catalog;

  @override
  Widget build(BuildContext context) {
    final t = mealPlanTotals(plan, catalog);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(value: '${t.kcal.round()}', label: 'ккал'),
            _Stat(value: '${t.protein.round()}', label: 'белки'),
            _Stat(value: '${t.fat.round()}', label: 'жиры'),
            _Stat(value: '${t.carb.round()}', label: 'углеводы'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.titleLarge?.copyWith(color: glass.textHi)),
        Text(label, style: text.labelSmall?.copyWith(color: glass.textMid)),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.items,
    required this.catalog,
  });

  final MealType meal;
  final List<MealPlanItem> items;
  final Map<String, FoodItem> catalog;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    var kcal = 0.0;
    for (final i in items) {
      final f = catalog[i.foodId];
      if (f != null) kcal += macrosFor(f, i.grams).kcal;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  meal.label,
                  style: text.titleLarge?.copyWith(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${kcal.round()} ккал',
                  style: TextStyle(color: glass.textMid, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        catalog[i.foodId]?.name ?? i.foodId,
                        style: text.bodyLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${i.grams.round()} г',
                      style: TextStyle(color: glass.textMid, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
