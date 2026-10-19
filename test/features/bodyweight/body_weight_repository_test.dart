// The Drift case requires generated code: run
//   dart run build_runner build --delete-conflicting-outputs
// before executing this suite.
import 'package:drift/native.dart';
import 'package:fittnes/core/database/app_database.dart';
import 'package:fittnes/features/bodyweight/data/body_weight_repository_drift.dart';
import 'package:fittnes/features/bodyweight/data/body_weight_repository_memory.dart';
import 'package:fittnes/features/bodyweight/domain/entities/body_weight_entry.dart';
import 'package:fittnes/features/bodyweight/domain/repositories/body_weight_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Both implementations must behave identically.
  final cases = <String, BodyWeightRepository Function()>{
    'memory': BodyWeightRepositoryMemory.new,
    'drift': () => BodyWeightRepositoryDrift(
          AppDatabase.forTesting(NativeDatabase.memory()),
        ),
  };

  for (final entry in cases.entries) {
    group(entry.key, () {
      late BodyWeightRepository repo;
      setUp(() => repo = entry.value());

      test('starts empty', () async {
        expect(await repo.all(), isEmpty);
        expect(await repo.latest(), isNull);
      });

      test('add assigns ids and lists newest first', () async {
        final a = await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 1, 1), kg: 85),
        );
        final b = await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 2, 1), kg: 84),
        );
        expect(a.id, isNot(0));
        expect(b.id, isNot(a.id));

        final all = await repo.all();
        expect(all.map((e) => e.kg), [84, 85]);
        expect((await repo.latest())!.kg, 84);
      });

      test('latest is by measurement date, not insertion order', () async {
        await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 3, 1), kg: 80),
        );
        await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 1, 1), kg: 86),
        );
        expect((await repo.latest())!.kg, 80);
      });

      test('delete removes one entry', () async {
        final a = await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 1, 1), kg: 85),
        );
        await repo.add(
          BodyWeightEntry(measuredAt: DateTime(2026, 1, 2), kg: 84.5),
        );
        await repo.delete(a.id);
        final all = await repo.all();
        expect(all, hasLength(1));
        expect(all.single.kg, 84.5);
      });
    });
  }
}
