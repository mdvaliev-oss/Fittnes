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

/// One body-weight measurement. Stored canonically in kilograms; the UI
/// converts to/from the user's display unit at the edges.
@DataClassName('BodyWeightRow')
class BodyWeights extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get measuredAt => dateTime()();
  RealColumn get kg => real()();
}

/// The app's local-first SQLite database.
@DriftDatabase(tables: [Sessions, Entries, SetEntries, BodyWeights])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Testing constructor with an injected (e.g. in-memory) executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2 had nutrition tables; v3 removes the feature entirely and adds
          // body-weight tracking. Dropping is guarded so a v1 → v3 jump (which
          // never had those tables) is safe too.
          if (from < 3) {
            await customStatement('DROP TABLE IF EXISTS food_entries');
            await customStatement('DROP TABLE IF EXISTS custom_foods');
            await m.createTable(bodyWeights);
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
