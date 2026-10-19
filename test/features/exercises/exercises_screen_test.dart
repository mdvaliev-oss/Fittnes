import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/exercises/domain/exercise_filter.dart';
import 'package:fittnes/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:fittnes/features/exercises/presentation/exercises_screen.dart';
import 'package:fittnes/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  _FakeExerciseRepository(this.items);
  final List<Exercise> items;

  @override
  Future<List<Exercise>> getAll() async => items;

  @override
  Future<List<Exercise>> search(ExerciseFilter filter) async =>
      items.where(filter.matches).toList();

  @override
  Future<Exercise?> getById(String id) async {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }
}

const _bench = Exercise(
  id: 'bench',
  name: 'Жим штанги лёжа',
  description: '',
  primaryMuscles: [Muscle.chest],
  category: ExerciseCategory.strength,
  level: ExperienceLevel.intermediate,
  equipment: Equipment.barbell,
);
const _curl = Exercise(
  id: 'curl',
  name: 'Сгибание на бицепс',
  description: '',
  primaryMuscles: [Muscle.biceps],
  category: ExerciseCategory.hypertrophy,
  level: ExperienceLevel.beginner,
  equipment: Equipment.dumbbell,
);
const _squat = Exercise(
  id: 'squat',
  name: 'Присед со штангой',
  description: '',
  primaryMuscles: [Muscle.quads],
  category: ExerciseCategory.strength,
  level: ExperienceLevel.intermediate,
  equipment: Equipment.barbell,
);

void main() {
  final overrides = [
    exerciseRepositoryProvider.overrideWithValue(
      _FakeExerciseRepository([_bench, _curl, _squat]),
    ),
  ];

  testWidgets('browsing shows the catalog grouped by region with the count',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги лёжа'), findsOneWidget);
    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // total count in header
    // Section headers (the chips carry the same labels, hence findsWidgets).
    expect(find.text('Грудь'), findsWidgets);
    expect(find.text('Руки'), findsWidgets);
  });

  testWidgets('search query filters the list and drops the grouping',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Сгиб');
    await tester.pumpAndSettle();

    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('Жим штанги лёжа'), findsNothing);
  });

  testWidgets('quick region chip narrows to that group', (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    // "Грудь" is also a section header and a muscle label — tap the chip.
    final chip = find.ancestor(
      of: find.text('Грудь').first,
      matching: find.byType(GestureDetector),
    );
    await tester.tap(chip.first);
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги лёжа'), findsOneWidget);
    expect(find.text('Присед со штангой'), findsNothing);
    expect(find.text('Сгибание на бицепс'), findsNothing);
    expect(find.text('Сбросить'), findsOneWidget);

    // Tapping the active chip again clears it.
    await tester.tap(chip.first);
    await tester.pumpAndSettle();
    expect(find.text('Присед со штангой'), findsOneWidget);
  });

  testWidgets('filter sheet applies equipment facet and shows a badge',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Фильтры'));
    await tester.pumpAndSettle();
    expect(find.text('Оборудование'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Гантели'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Показать'));
    await tester.pumpAndSettle();

    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('Жим штанги лёжа'), findsNothing);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ExercisesScreen)));
    expect(
      container.read(exerciseFilterProvider).equipment,
      Equipment.dumbbell,
    );
    expect(container.read(exerciseFilterProvider).activeFacetCount, 1);
  });

  testWidgets('star toggles a favorite and the favorites chip filters by it',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    // Star the curl via its row button.
    final curlRow = find.ancestor(
      of: find.text('Сгибание на бицепс'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(
        of: curlRow.first,
        matching: find.byIcon(Icons.star_outline_rounded),
      ),
    );
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(ExercisesScreen)));
    expect(container.read(favoriteExercisesProvider), {'curl'});

    await tester.tap(find.text('Избранное'));
    await tester.pumpAndSettle();
    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('Жим штанги лёжа'), findsNothing);
  });

  testWidgets('empty favorites shows a hint and a reset action',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Избранное'));
    await tester.pumpAndSettle();
    expect(find.text('Избранных пока нет'), findsOneWidget);

    await tester.tap(find.text('Сбросить фильтры'));
    await tester.pumpAndSettle();
    expect(find.text('Жим штанги лёжа'), findsOneWidget);
  });

  testWidgets('grid layout toggle renders tiles', (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Сеткой'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Списком'), findsOneWidget);
    expect(find.text('Присед со штангой'), findsOneWidget);
  });
}
