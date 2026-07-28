import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// A finished (or in-progress) training session.
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}

/// One exercise inside a session.
@DataClassName('EntryRow')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseName => text()();
  IntColumn get position => integer()();
  IntColumn get supersetGroup => integer().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(120))();
  TextColumn get note => text().nullable()();
}

/// One logged set inside an entry.
@DataClassName('SetRow')
class SetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  /// Index of [SetType].
  IntColumn get type => integer().withDefault(const Constant(1))();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  RealColumn get rpe => real().nullable()();
  IntColumn get rir => integer().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
}

/// A user-created food product (macros per 100 g). Catalog foods ship as a
/// bundled JSON asset; only user-authored ones live in the database.
@DataClassName('CustomFoodRow')
class CustomFoods extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get kcalPer100 => real()();
  RealColumn get proteinPer100 => real()();
  RealColumn get fatPer100 => real()();
  RealColumn get carbPer100 => real()();
}

/// One logged food in the nutrition diary. Macros are snapshotted at add-time
/// so history stays stable even if the source product is later edited/removed.
@DataClassName('FoodEntryRow')
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Date-only (midnight) the entry belongs to.
  DateTimeColumn get day => dateTime()();

  /// Index of [MealType].
  IntColumn get meal => integer()();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get protein => real()();
  RealColumn get fat => real()();
  RealColumn get carb => real()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The app's local-first SQLite database.
@DriftDatabase(
  tables: [Sessions, Entries, SetEntries, CustomFoods, FoodEntries],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Testing constructor with an injected (e.g. in-memory) executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 adds the nutrition tracker tables.
          if (from < 2) {
            await m.createTable(customFoods);
            await m.createTable(foodEntries);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Opens the on-device SQLite file lazily on a background isolate.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fittnes.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
