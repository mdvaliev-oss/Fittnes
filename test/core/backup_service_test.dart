import 'package:fittnes/core/backup/backup_service.dart';
import 'package:fittnes/core/settings/app_settings.dart';
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

void main() {
  test('export then import restores workout sessions into a fresh repo',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final sourceRepo = WorkoutRepositoryMemory();
    await sourceRepo.save(_session());

    ProviderContainer containerWith(WorkoutRepository repo) =>
        ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            workoutRepositoryProvider.overrideWithValue(repo),
          ],
        );

    final source = containerWith(sourceRepo);
    addTearDown(source.dispose);
    final json = await source.read(backupServiceProvider).export();

    // Import into a fresh, empty repository.
    final targetRepo = WorkoutRepositoryMemory();
    final target = containerWith(targetRepo);
    addTearDown(target.dispose);

    expect(await targetRepo.history(), isEmpty);
    final result = await target.read(backupServiceProvider).import(json);

    expect(result.sessions, 1);
    final restored = await targetRepo.history();
    expect(restored, hasLength(1));
    expect(restored.single.title, 'Push Day');
    expect(restored.single.totalVolume, 500);
  });

  test('import rejects a backup from a newer schema', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workoutRepositoryProvider.overrideWithValue(WorkoutRepositoryMemory()),
      ],
    );
    addTearDown(container.dispose);

    const future = '{"app":"fittnes","version":999,"sessions":[]}';
    expect(
      () => container.read(backupServiceProvider).import(future),
      throwsA(isA<BackupException>()),
    );
  });

  test('import rejects malformed JSON with a BackupException', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workoutRepositoryProvider.overrideWithValue(WorkoutRepositoryMemory()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      () => container.read(backupServiceProvider).import('not json'),
      throwsA(isA<BackupException>()),
    );
  });

  test('exported JSON carries settings and is valid', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workoutRepositoryProvider.overrideWithValue(WorkoutRepositoryMemory()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appSettingsProvider.notifier)
        .setReminders(enabled: true, hour: 7, minute: 15);

    final json = await container.read(backupServiceProvider).export();
    expect(json, contains('"remindersEnabled": true'));
    expect(json, contains('"app": "fittnes"'));
  });
}
