import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workout_program.dart';

/// Persists user-created programs as a JSON array in SharedPreferences.
class CustomProgramRepository {
  CustomProgramRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'programs.custom';

  List<WorkoutProgram> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(WorkoutProgram program) {
    final all = getAll().where((p) => p.id != program.id).toList()
      ..add(program);
    return _persist(all);
  }

  Future<void> delete(String id) =>
      _persist(getAll().where((p) => p.id != id).toList());

  Future<void> _persist(List<WorkoutProgram> programs) => _prefs.setString(
        _key,
        jsonEncode(programs.map((p) => p.toJson()).toList()),
      );
}
