import 'package:fittnes/core/backup/backup_service.dart';
import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/features/bodyweight/data/body_weight_repository_memory.dart';
import 'package:fittnes/features/bodyweight/domain/entities/body_weight_entry.dart';
import 'package:fittnes/features/bodyweight/presentation/providers/body_weight_providers.dart';
import 'package:fittnes/features/workout/data/workout_repository_memory.dart';
import 'package:fittnes/features/workout/domain/entities/workout_exercise_entry.dart';
import 'package:fittnes/features/workout/domain/entities/workout_session.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:fittnes/features/workout/domain/repositories/workout_repository.dart';
import 'package:fittnes/features/workout/presentation/providers/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

WorkoutSession _session() => WorkoutSession(
      id: 1,
      title: 'Push Day',
      startedAt: DateTime(2026, 3, 1, 10),
      finishedAt: DateTime(2026, 3, 1, 11),
      entries: [
        const WorkoutExerciseEntry(
          id: 1,
          exerciseId: 'bench',
          exerciseName: 'Жим лёжа',
          sets: [
            WorkoutSet(id: 1, weight: 100, reps: 5, isCompleted: true),
          ],
        ),
      ],
    );

Future<ProviderContainer> _container(
  WorkoutRepository repo, {
  BodyWeightRepositoryMemory? weights,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      workoutRepositoryProvider.overrideWithValue(repo),
      bodyWeightRepositoryProvider
          .overrideWithValue(weights ?? BodyWeightRepositoryMemory()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('export then import restores workout sessions into a fresh repo',
      () async {
    final sourceRepo = WorkoutRepositoryMemory();
    await sourceRepo.save(_session());
    final source = await _container(sourceRepo);
    final json = await source.read(backupServiceProvider).export();

    // Import into a fresh, empty repository.
    final targetRepo = WorkoutRepositoryMemory();
    final target = await _container(targetRepo);

    expect(await targetRepo.history(), isEmpty);
    final result = await target.read(backupServiceProvider).import(json);

    expect(result.sessions, 1);
    final restored = await targetRepo.history();
    expect(restored, hasLength(1));
    expect(restored.single.title, 'Push Day');
    expect(restored.single.totalVolume, 500);
  });

  test('export then import restores body-weight history', () async {
    final sourceWeights = BodyWeightRepositoryMemory();
    await sourceWeights.add(
      BodyWeightEntry(measuredAt: DateTime(2026, 4, 1), kg: 84.2),
    );
    await sourceWeights.add(
      BodyWeightEntry(measuredAt: DateTime(2026, 5, 1), kg: 83),
    );
    final source =
        await _container(WorkoutRepositoryMemory(), weights: sourceWeights);
    final json = await source.read(backupServiceProvider).export();

    final targetWeights = BodyWeightRepositoryMemory();
    final target =
        await _container(WorkoutRepositoryMemory(), weights: targetWeights);
    await target.read(backupServiceProvider).import(json);

    final restored = await targetWeights.all();
    expect(restored.map((e) => e.kg), [83, 84.2]);
  });

  test('import of a v2 backup ignores the removed nutrition keys', () async {
    final repo = WorkoutRepositoryMemory();
    final container = await _container(repo);

    const legacy = '''
{
  "app": "fittnes",
  "version": 2,
  "settings": {"unit": "lb", "nutritionKcal": 1800},
  "sessions": [
    {"id": 7, "title": "Legacy", "startedAt": "2026-01-05T10:00:00.000",
     "finishedAt": "2026-01-05T11:00:00.000", "entries": []}
  ],
  "customFoods": [{"id": "x", "name": "Протеин", "kcalPer100": 380}],
  "foodEntries": [{"name": "Гречка", "grams": 150}]
}''';

    final result = await container.read(backupServiceProvider).import(legacy);
    expect(result.sessions, 1);
    expect((await repo.history()).single.title, 'Legacy');
    expect(container.read(appSettingsProvider).unit, WeightUnit.lb);
  });

  test('import rejects a backup from a newer schema', () async {
    final container = await _container(WorkoutRepositoryMemory());

    const future = '{"app":"fittnes","version":999,"sessions":[]}';
    expect(
      () => container.read(backupServiceProvider).import(future),
      throwsA(isA<BackupException>()),
    );
  });

  test('import rejects malformed JSON with a BackupException', () async {
    final container = await _container(WorkoutRepositoryMemory());

    expect(
      () => container.read(backupServiceProvider).import('not json'),
      throwsA(isA<BackupException>()),
    );
  });

  test('exported JSON carries settings and is valid', () async {
    final container = await _container(WorkoutRepositoryMemory());

    await container
        .read(appSettingsProvider.notifier)
        .setReminders(enabled: true, hour: 7, minute: 15);

    final json = await container.read(backupServiceProvider).export();
    expect(json, contains('"remindersEnabled": true'));
    expect(json, contains('"app": "fittnes"'));
    expect(json, isNot(contains('customFoods')));
  });
}
