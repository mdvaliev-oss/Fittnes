import 'package:fittnes/features/exercises/domain/entities/exercise.dart';
import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/exercises/domain/exercise_filter.dart';
import 'package:fittnes/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:fittnes/features/exercises/presentation/exercises_screen.dart';
import 'package:fittnes/features/exercises/presentation/providers/exercise_providers.dart';
import 'package:flutter/material.dart';
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

void main() {
  final overrides = [
    exerciseRepositoryProvider.overrideWithValue(
      _FakeExerciseRepository([_bench, _curl]),
    ),
  ];

  testWidgets('renders the catalog with all exercises and the count',
      (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    expect(find.text('Жим штанги лёжа'), findsOneWidget);
    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // total count in header
  });

  testWidgets('search query filters the list', (tester) async {
    await pumpApp(tester, const ExercisesScreen(), overrides: overrides);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Сгиб');
    await tester.pumpAndSettle();

    expect(find.text('Сгибание на бицепс'), findsOneWidget);
    expect(find.text('Жим штанги лёжа'), findsNothing);
  });
}
