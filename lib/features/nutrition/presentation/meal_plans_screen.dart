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
import '../domain/nutrition_math.dart';
import 'providers/nutrition_providers.dart';

/// List of ready-made daily menus (~2000 kcal). Tap → detail → apply to a day.
class MealPlansScreen extends ConsumerWidget {
  const MealPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;
    final plans = ref.watch(mealPlansProvider);
    final catalog = ref.watch(foodCatalogByIdProvider).valueOrNull ?? const {};

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
                    child: Text('Готовые меню', style: text.headlineLarge),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Рационы на ~2000 ккал из доступных продуктов. '
                  'Открой меню и примени на выбранный день.',
                  style: text.bodyMedium?.copyWith(color: glass.textMid),
                ),
              ),
              plans.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text('Ошибка: $e'),
                ),
                data: (list) => Column(
                  children: [
                    for (final plan in list)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: _PlanCard(plan: plan, catalog: catalog),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.catalog});
  final MealPlan plan;
  final Map<String, FoodItem> catalog;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;
    final totals = mealPlanTotals(plan, catalog);

    return GlassCard(
      onTap: () => context.push(AppRoutes.mealPlanDetail(plan.id)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: glass.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(Icons.restaurant_menu_rounded, color: glass.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: text.titleLarge?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${totals.kcal.round()} ккал · Б ${totals.protein.round()} '
                  'Ж ${totals.fat.round()} У ${totals.carb.round()}',
                  style: text.bodyMedium?.copyWith(color: glass.textMid),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: glass.textLow),
        ],
      ),
    );
  }
}
