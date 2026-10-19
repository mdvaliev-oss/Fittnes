import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_theme.dart';
import '../../../core/widgets/ambient_background.dart';
import '../domain/entities/exercise.dart';
import '../domain/entities/muscle_group.dart';
import 'providers/exercise_providers.dart';
import 'widgets/exercise_card.dart';
import 'widgets/exercise_visuals.dart';
import 'widgets/filter_sheet.dart';

/// Exercise catalog: search, quick region chips, a filter sheet for the
/// finer facets, favorites, and list / grid layouts. When nothing narrows
/// the catalog it is shown grouped by region with headers.
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(exerciseFilterProvider);
    final notifier = ref.read(exerciseFilterProvider.notifier);
    final results = ref.watch(filteredExercisesProvider);
    final total = ref.watch(exerciseCountProvider);
    final layout = ref.watch(catalogLayoutProvider);
    final favorites = ref.watch(favoriteExercisesProvider);
    final glass = context.glass;
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Упражнения',
                      style: text.headlineLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  total.maybeWhen(
                    data: (n) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('$n', style: text.bodyMedium),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  if (!filter.isEmpty)
                    TextButton(
                      onPressed: notifier.clear,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Сбросить'),
                    ),
                ],
              ),
            ),

            // Search + filter button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: notifier.setQuery,
                      style: text.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Поиск упражнения…',
                        prefixIcon:
                            Icon(Icons.search_rounded, color: glass.textMid),
                        filled: true,
                        fillColor: glass.fill,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _FilterButton(
                    count: filter.activeFacetCount +
                        (filter.favoritesOnly ? 1 : 0),
                    onTap: () => showExerciseFilterSheet(context),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _LayoutButton(
                    layout: layout,
                    onTap: () =>
                        ref.read(catalogLayoutProvider.notifier).state =
                            layout == CatalogLayout.list
                                ? CatalogLayout.grid
                                : CatalogLayout.list,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Quick region chips
            _GroupChipRow(
              selected: filter.group,
              favoritesOnly: filter.favoritesOnly,
              onToggle: notifier.toggleGroup,
              onFavorites: notifier.toggleFavorites,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Results
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Ошибка загрузки: $e', style: text.bodyMedium),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyResults(
                      favoritesOnly: filter.favoritesOnly,
                      onReset: notifier.clear,
                    );
                  }
                  return _Results(
                    list: list,
                    grouped: filter.isBrowsing,
                    layout: layout,
                    favorites: favorites,
                    onFavorite: (id) =>
                        ref.read(favoriteExercisesProvider.notifier).toggle(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final active = count > 0;
    return Semantics(
      button: true,
      label: 'Фильтры',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color:
                active ? AppColors.primary.withValues(alpha: 0.25) : glass.fill,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: active ? AppColors.primaryBright : glass.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                color: active ? AppColors.primaryBright : glass.textMid,
              ),
              if (active) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppColors.primaryBright,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutButton extends StatelessWidget {
  const _LayoutButton({required this.layout, required this.onTap});
  final CatalogLayout layout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isList = layout == CatalogLayout.list;
    return Tooltip(
      message: isList ? 'Сеткой' : 'Списком',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: glass.fill,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: glass.border),
          ),
          child: Icon(
            isList ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
            color: glass.textMid,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _GroupChipRow extends StatelessWidget {
  const _GroupChipRow({
    required this.selected,
    required this.favoritesOnly,
    required this.onToggle,
    required this.onFavorites,
  });

  final MuscleGroup? selected;
  final bool favoritesOnly;
  final ValueChanged<MuscleGroup> onToggle;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          _Chip(
            label: 'Избранное',
            icon: Icons.star_rounded,
            selected: favoritesOnly,
            accent: AppColors.warning,
            onTap: onFavorites,
          ),
          const SizedBox(width: AppSpacing.xs),
          for (final g in MuscleGroup.values) ...[
            _Chip(
              label: g.label,
              icon: ExerciseVisuals.groupIcon(g),
              selected: g == selected,
              onTap: () => onToggle(g),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accent,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final fg = selected ? Colors.white : (accent ?? glass.textMid);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? (accent ?? AppColors.primary) : glass.fill,
          gradient:
              selected && accent == null ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? Colors.transparent : glass.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.list,
    required this.grouped,
    required this.layout,
    required this.favorites,
    required this.onFavorite,
  });

  final List<Exercise> list;
  final bool grouped;
  final CatalogLayout layout;
  final Set<String> favorites;
  final ValueChanged<String> onFavorite;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final glass = context.glass;

    final sections = grouped
        ? [
            for (final g in MuscleGroup.values)
              (
                g,
                list
                    .where((e) => MuscleGroup.of(e.primaryMuscles.first) == g)
                    .toList(),
              ),
          ].where((s) => s.$2.isNotEmpty).toList()
        : [(null, list)];

    return CustomScrollView(
      slivers: [
        for (final (group, items) in sections) ...[
          if (group != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Icon(
                      ExerciseVisuals.groupIcon(group),
                      size: 16,
                      color: glass.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(group.label, style: text.titleLarge),
                    const SizedBox(width: AppSpacing.xs),
                    Text('${items.length}', style: text.bodyMedium),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: layout == CatalogLayout.grid
                ? SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.xs,
                      crossAxisSpacing: AppSpacing.xs,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ExerciseGridTile(
                        exercise: items[i],
                        isFavorite: favorites.contains(items[i].id),
                        onFavoriteToggle: () => onFavorite(items[i].id),
                        onTap: () =>
                            context.push(AppRoutes.exerciseDetail(items[i].id)),
                      ),
                      childCount: items.length,
                    ),
                  )
                : SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) => ExerciseCard(
                      exercise: items[i],
                      isFavorite: favorites.contains(items[i].id),
                      onFavoriteToggle: () => onFavorite(items[i].id),
                      onTap: () =>
                          context.push(AppRoutes.exerciseDetail(items[i].id)),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl * 2)),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.favoritesOnly, required this.onReset});
  final bool favoritesOnly;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              favoritesOnly
                  ? Icons.star_outline_rounded
                  : Icons.search_off_rounded,
              size: 44,
              color: glass.textLow,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              favoritesOnly ? 'Избранных пока нет' : 'Ничего не найдено',
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              favoritesOnly
                  ? 'Нажми ★ на карточке упражнения — оно появится здесь.'
                  : 'Попробуй другое слово или сними фильтры.',
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Сбросить фильтры'),
            ),
          ],
        ),
      ),
    );
  }
}
