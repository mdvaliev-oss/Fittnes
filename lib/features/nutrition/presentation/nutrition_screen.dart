import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/entities/food_entry.dart';
import '../domain/entities/meal_type.dart';
import '../domain/entities/nutrition_targets.dart';
import '../domain/nutrition_math.dart';
import 'providers/nutrition_providers.dart';
import 'widgets/calorie_ring.dart';

/// The nutrition diary: day summary (calorie ring + macro bars) and the four
/// meals with their logged foods.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final day = ref.watch(selectedNutritionDateProvider);
    final dayAsync = ref.watch(dailyNutritionProvider);
    final targets = ref.watch(nutritionTargetsProvider);

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dailyNutritionProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl * 2,
            ),
            children: [
              Row(
                children: [
                  Text('Питание', style: text.headlineLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.nutritionTargets),
                    icon: const Icon(Icons.flag_rounded, size: 18),
                    label: const Text('Цель'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DateBar(
                day: day,
                onShift: (delta) {
                  ref.read(selectedNutritionDateProvider.notifier).state =
                      DateTime(day.year, day.month, day.day + delta);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              dayAsync.when(
                loading: () => const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Ошибка: $e'),
                data: (daily) => _DaySummary(daily: daily, targets: targets),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final meal in MealType.values)
                _MealSection(
                  meal: meal,
                  entries: dayAsync.valueOrNull?.ofMeal(meal) ?? const [],
                  onAdd: () => context.push(
                    AppRoutes.addFood,
                    extra: {'meal': meal, 'day': day},
                  ),
                  onDelete: (entry) async {
                    if (entry.id == null) return;
                    await ref
                        .read(nutritionRepositoryProvider)
                        .removeEntry(entry.id!);
                    ref.invalidate(dailyNutritionProvider);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({required this.day, required this.onShift});
  final DateTime day;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => onShift(-1),
          tooltip: 'Предыдущий день',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          dayLabel(day),
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: glass.textHi),
        ),
        IconButton(
          onPressed: _isToday(day) ? null : () => onShift(1),
          tooltip: 'Следующий день',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.daily, required this.targets});
  final DailyNutrition daily;
  final NutritionTargets targets;

  @override
  Widget build(BuildContext context) {
    final totals = daily.totals;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          CalorieRing(consumed: totals.kcal, target: targets.kcal),
          const SizedBox(height: AppSpacing.md),
          _MacroBar(
            label: 'Белки',
            consumed: totals.protein,
            target: targets.proteinG,
            color: AppColors.primaryBright,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MacroBar(
            label: 'Жиры',
            consumed: totals.fat,
            target: targets.fatG,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MacroBar(
            label: 'Углеводы',
            consumed: totals.carb,
            target: targets.carbG,
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final fraction = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(color: glass.textHi, fontSize: 13)),
            const Spacer(),
            Text(
              '${consumed.round()} / ${target.round()} г',
              style: TextStyle(color: glass.textMid, fontSize: 12.5),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: glass.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<FoodEntry> onDelete;

  static const _icons = {
    MealType.breakfast: Icons.free_breakfast_rounded,
    MealType.lunch: Icons.lunch_dining_rounded,
    MealType.dinner: Icons.dinner_dining_rounded,
    MealType.snack: Icons.cookie_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    final kcal = sumEntries(entries).kcal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icons[meal], size: 20, color: glass.accent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  meal.label,
                  style: text.titleLarge?.copyWith(fontSize: 17),
                ),
                const Spacer(),
                Text(
                  '${kcal.round()} ккал',
                  style: TextStyle(color: glass.textMid, fontSize: 13),
                ),
              ],
            ),
            for (final e in entries)
              Dismissible(
                key: ValueKey('food-${e.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  color: AppColors.danger.withValues(alpha: 0.18),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
                onDismissed: (_) => onDelete(e),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.name,
                          style: text.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${e.grams.round()} г',
                        style: TextStyle(color: glass.textMid, fontSize: 12.5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${e.kcal.round()} ккал',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: glass.textHi, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Добавить'),
              style: TextButton.styleFrom(
                foregroundColor: glass.accent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Сегодня" / "Вчера" / "3 мая" style label for a diary day.
String dayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(day.year, day.month, day.day);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == -1) return 'Вчера';
  if (diff == 1) return 'Завтра';
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${day.day} ${months[day.month - 1]}';
}
