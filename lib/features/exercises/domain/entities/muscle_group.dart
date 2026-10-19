import 'muscle.dart';

/// Coarse body regions for quick catalog filtering and grouping — the way
/// lifters actually think ("chest day"), as opposed to the anatomical
/// [Muscle] list used for the body map.
enum MuscleGroup {
  chest('Грудь', {Muscle.chest}),
  back(
    'Спина',
    {Muscle.lats, Muscle.traps, Muscle.lowerBack, Muscle.rearDelts},
  ),
  shoulders('Плечи', {Muscle.frontDelts, Muscle.sideDelts}),
  arms('Руки', {Muscle.biceps, Muscle.triceps, Muscle.forearms}),
  legs(
    'Ноги',
    {Muscle.quads, Muscle.hamstrings, Muscle.calves, Muscle.adductors},
  ),
  glutes('Ягодицы', {Muscle.glutes}),
  core('Пресс', {Muscle.abs, Muscle.obliques});

  const MuscleGroup(this.label, this.muscles);

  final String label;
  final Set<Muscle> muscles;

  /// The group a muscle belongs to (rear delts count as back — they are
  /// trained with pulls, not presses).
  static MuscleGroup of(Muscle m) =>
      values.firstWhere((g) => g.muscles.contains(m));
}
