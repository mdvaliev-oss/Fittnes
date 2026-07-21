import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

/// The app's local-first SQLite database.
@DriftDatabase(tables: [Sessions, Entries, SetEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'fittnes'));

  /// Testing constructor with an injected (e.g. in-memory) executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
