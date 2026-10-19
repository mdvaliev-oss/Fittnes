// Requires generated Drift code: run
//   dart run build_runner build --delete-conflicting-outputs
// before executing this suite.
import 'package:drift/native.dart';
import 'package:fittnes/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Builds an in-memory SQLite file shaped like schema v2 (workout tables +
/// the since-removed nutrition tables) with a little data in each.
sqlite.Database _legacyV2() {
  final db = sqlite.sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      started_at INTEGER NOT NULL,
      finished_at INTEGER
    );
    CREATE TABLE entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      exercise_id TEXT NOT NULL,
      exercise_name TEXT NOT NULL,
      position INTEGER NOT NULL,
      superset_group INTEGER,
      rest_seconds INTEGER NOT NULL DEFAULT 120,
      note TEXT
    );
    CREATE TABLE set_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entry_id INTEGER NOT NULL REFERENCES entries(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      type INTEGER NOT NULL DEFAULT 1,
      weight REAL,
      reps INTEGER,
      rpe REAL,
      rir INTEGER,
      is_completed INTEGER NOT NULL DEFAULT 0,
      note TEXT
    );
    CREATE TABLE custom_foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      kcal_per100 REAL NOT NULL,
      protein_per100 REAL NOT NULL,
      fat_per100 REAL NOT NULL,
      carb_per100 REAL NOT NULL
    );
    CREATE TABLE food_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      day INTEGER NOT NULL,
      meal INTEGER NOT NULL,
      name TEXT NOT NULL,
      grams REAL NOT NULL,
      kcal REAL NOT NULL,
      protein REAL NOT NULL,
      fat REAL NOT NULL,
      carb REAL NOT NULL,
      created_at INTEGER NOT NULL
    );
    INSERT INTO sessions (title, started_at, finished_at)
      VALUES ('Legacy push', 1700000000, 1700003600);
    INSERT INTO entries (session_id, exercise_id, exercise_name, position)
      VALUES (1, 'bench', 'Жим лёжа', 0);
    INSERT INTO set_entries (entry_id, position, weight, reps, is_completed)
      VALUES (1, 0, 100, 5, 1);
    INSERT INTO custom_foods VALUES (1, 'Протеин', 380, 75, 5, 8);
    INSERT INTO food_entries
      VALUES (1, 1700000000, 1, 'Гречка', 150, 138, 5, 1, 26, 1700000000);
    PRAGMA user_version = 2;
  ''');
  return db;
}

void main() {
  test('v2 → v3 drops nutrition tables, adds body_weights, keeps workouts',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.opened(_legacyV2()));
    addTearDown(db.close);

    final tables = (await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table'",
            )
            .get())
        .map((r) => r.read<String>('name'))
        .toSet();

    expect(tables, isNot(contains('custom_foods')));
    expect(tables, isNot(contains('food_entries')));
    expect(tables, contains('body_weights'));

    // Workout history survived untouched.
    final sessions = await db.select(db.sessions).get();
    expect(sessions.single.title, 'Legacy push');
    final sets = await db.select(db.setEntries).get();
    expect(sets.single.weight, 100);

    // And the new table is usable.
    await db.into(db.bodyWeights).insert(
          BodyWeightsCompanion.insert(
            measuredAt: DateTime(2026, 5, 1),
            kg: 81.6,
          ),
        );
    expect((await db.select(db.bodyWeights).get()).single.kg, 81.6);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      3,
    );
  });

  test('fresh database opens at v3 with body_weights only', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final tables = (await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table'",
            )
            .get())
        .map((r) => r.read<String>('name'))
        .toSet();

    expect(tables, containsAll(['sessions', 'entries', 'body_weights']));
    expect(tables, isNot(contains('food_entries')));
  });
}
