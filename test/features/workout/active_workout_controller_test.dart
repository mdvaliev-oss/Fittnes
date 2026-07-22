import 'package:fittnes/features/workout/domain/entities/set_type.dart';
import 'package:fittnes/features/workout/presentation/providers/active_workout_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late ActiveWorkoutController c;

  setUp(() {
    container = ProviderContainer();
    c = container.read(activeWorkoutControllerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('starts inactive; start() creates an empty session', () {
    expect(c.isActive, isFalse);
    c.start(title: 'Push');
    expect(c.isActive, isTrue);
    expect(container.read(activeWorkoutControllerProvider)!.title, 'Push');
    expect(container.read(activeWorkoutControllerProvider)!.entries, isEmpty);
  });

  test('addExerciseRef adds an entry with one prefilled set', () {
    c.start();
    c.addExerciseRef(
      'bench',
      'Жим',
      recommendedWeight: 100,
      recommendedReps: 5,
    );
    final session = container.read(activeWorkoutControllerProvider)!;
    expect(session.entries, hasLength(1));
    expect(session.entries.single.sets, hasLength(1));
    expect(session.entries.single.sets.single.weight, 100);
    expect(session.entries.single.sets.single.reps, 5);
  });

  test('addSet templates weight/reps from the previous set', () {
    c.start();
    c.addExerciseRef(
      'bench',
      'Жим',
      recommendedWeight: 100,
      recommendedReps: 5,
    );
    final entryId =
        container.read(activeWorkoutControllerProvider)!.entries.single.id;
    c.addSet(entryId);
    final sets =
        container.read(activeWorkoutControllerProvider)!.entries.single.sets;
    expect(sets, hasLength(2));
    expect(sets.last.weight, 100);
    expect(sets.last.reps, 5);
  });

  test('updateSet, completion and volume', () {
    c.start();
    c.addExerciseRef('bench', 'Жим');
    final entry =
        container.read(activeWorkoutControllerProvider)!.entries.single;
    final setId = entry.sets.single.id;
    c.updateSet(entry.id, setId, weight: 80, reps: 10);
    c.toggleSetComplete(entry.id, setId);
    final session = container.read(activeWorkoutControllerProvider)!;
    expect(session.entries.single.sets.single.isCompleted, isTrue);
    expect(session.totalVolume, 800);
    expect(session.completedSets, 1);
  });

  test('cycleSetType rotates through the set types', () {
    c.start();
    c.addExerciseRef('bench', 'Жим');
    final entry =
        container.read(activeWorkoutControllerProvider)!.entries.single;
    expect(entry.sets.single.type, SetType.normal);
    c.cycleSetType(entry.id, entry.sets.single.id);
    final next = container
        .read(activeWorkoutControllerProvider)!
        .entries
        .single
        .sets
        .single
        .type;
    expect(next, isNot(SetType.normal));
  });

  test('toggleSuperset groups an exercise with the one above it', () {
    c.start();
    c.addExerciseRef('a', 'A');
    c.addExerciseRef('b', 'B');
    final entries = container.read(activeWorkoutControllerProvider)!.entries;
    c.toggleSuperset(entries[1].id);
    final grouped = container.read(activeWorkoutControllerProvider)!.entries;
    expect(grouped[0].supersetGroup, isNotNull);
    expect(grouped[0].supersetGroup, grouped[1].supersetGroup);
  });

  test('removeSet and removeEntry', () {
    c.start();
    c.addExerciseRef('bench', 'Жим');
    final entry =
        container.read(activeWorkoutControllerProvider)!.entries.single;
    c.addSet(entry.id);
    c.removeSet(entry.id, entry.sets.single.id);
    expect(
      container.read(activeWorkoutControllerProvider)!.entries.single.sets,
      hasLength(1),
    );
    c.removeEntry(entry.id);
    expect(container.read(activeWorkoutControllerProvider)!.entries, isEmpty);
  });

  test('finish() stamps finishedAt and clears active state', () {
    c.start();
    c.addExerciseRef('bench', 'Жим');
    final finished = c.finish();
    expect(finished, isNotNull);
    expect(finished!.isFinished, isTrue);
    expect(c.isActive, isFalse);
    expect(container.read(activeWorkoutControllerProvider), isNull);
  });
}
