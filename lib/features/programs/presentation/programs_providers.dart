import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../data/custom_program_repository.dart';
import '../data/preset_programs.dart';
import '../domain/workout_program.dart';

/// All built-in programs.
final presetProgramsProvider =
    Provider<List<WorkoutProgram>>((ref) => PresetPrograms.all);

final customProgramRepositoryProvider =
    Provider<CustomProgramRepository>((ref) {
  return CustomProgramRepository(ref.watch(sharedPreferencesProvider));
});

/// User-created programs, with save/delete that refresh the list.
class CustomProgramsController extends Notifier<List<WorkoutProgram>> {
  CustomProgramRepository get _repo =>
      ref.read(customProgramRepositoryProvider);

  @override
  List<WorkoutProgram> build() => _repo.getAll();

  Future<void> save(WorkoutProgram program) async {
    await _repo.save(program);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }
}

final customProgramsProvider =
    NotifierProvider<CustomProgramsController, List<WorkoutProgram>>(
  CustomProgramsController.new,
);

/// Presets followed by the user's custom programs.
final allProgramsProvider = Provider<List<WorkoutProgram>>((ref) {
  return [
    ...ref.watch(presetProgramsProvider),
    ...ref.watch(customProgramsProvider),
  ];
});

/// Look up a program by id across presets and custom programs.
final programByIdProvider = Provider.family<WorkoutProgram?, String>((ref, id) {
  for (final p in ref.watch(allProgramsProvider)) {
    if (p.id == id) return p;
  }
  return null;
});
