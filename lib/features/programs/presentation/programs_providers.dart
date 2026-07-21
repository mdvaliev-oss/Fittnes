import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preset_programs.dart';
import '../domain/workout_program.dart';

/// All built-in programs.
final presetProgramsProvider =
    Provider<List<WorkoutProgram>>((ref) => PresetPrograms.all);

/// Look up a program by id.
final programByIdProvider = Provider.family<WorkoutProgram?, String>((ref, id) {
  for (final p in ref.watch(presetProgramsProvider)) {
    if (p.id == id) return p;
  }
  return null;
});
