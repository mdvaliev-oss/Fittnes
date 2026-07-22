import 'package:fittnes/features/progress/presentation/progress_screen.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:fittnes/features/workout/presentation/providers/workout_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

WorkoutSession _bench(int id, DateTime day, double weight) => WorkoutSession(
      id: id,
      title: 'S$id',
      startedAt: day,
      finishedAt: day.add(const Duration(hours: 1)),
      entries: [
        WorkoutExerciseEntry(
          id: id,
          exerciseId: 'bench',
          exerciseName: 'Жим штанги лёжа',
          sets: [
            WorkoutSet(id: id, weight: weight, reps: 5, isCompleted: true),
          ],
        ),
      ],
    );

void main() {
  testWidgets('renders charts and personal records from history',
      (tester) async {
    final history = [
      _bench(2, DateTime(2026, 2, 1), 110),
      _bench(1, DateTime(2026, 1, 1), 100),
    ];

    await pumpApp(
      tester,
      const ProgressScreen(),
      overrides: [
        workoutHistoryProvider.overrideWith((ref) async => history),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Прогресс'), findsOneWidget);
    expect(find.text('Тоннаж по тренировкам'), findsOneWidget);
    expect(find.text('Личные рекорды'), findsOneWidget);
    // Appears in both the exercise picker and the personal-records tile.
    expect(find.text('Жим штанги лёжа'), findsWidgets);
  });

  testWidgets('empty history shows the placeholder', (tester) async {
    await pumpApp(
      tester,
      const ProgressScreen(),
      overrides: [
        workoutHistoryProvider.overrideWith((ref) async => <WorkoutSession>[]),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Здесь появится прогресс'), findsOneWidget);
  });
}
