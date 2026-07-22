/// Which side of the body a muscle is rendered on in the anatomy map.
enum BodySide { front, back }

/// Canonical muscle groups used both by exercise data and the anatomy map.
///
/// [label] is the Russian display name; [side] drives which figure
/// (front/back) highlights the muscle in [MuscleMap].
enum Muscle {
  chest('Грудь', BodySide.front),
  frontDelts('Передние дельты', BodySide.front),
  sideDelts('Средние дельты', BodySide.front),
  rearDelts('Задние дельты', BodySide.back),
  biceps('Бицепс', BodySide.front),
  triceps('Трицепс', BodySide.back),
  forearms('Предплечья', BodySide.front),
  abs('Пресс', BodySide.front),
  obliques('Косые', BodySide.front),
  traps('Трапеции', BodySide.back),
  lats('Широчайшие', BodySide.back),
  lowerBack('Поясница', BodySide.back),
  glutes('Ягодицы', BodySide.back),
  quads('Квадрицепс', BodySide.front),
  hamstrings('Бицепс бедра', BodySide.back),
  calves('Икры', BodySide.back),
  adductors('Приводящие', BodySide.front);

  const Muscle(this.label, this.side);

  final String label;
  final BodySide side;

  /// Maps a raw muscle name from the open dataset (free-exercise-db) onto a
  /// canonical [Muscle]. Returns `null` for names we don't map yet.
  static Muscle? fromDataset(String raw) =>
      _datasetMap[raw.toLowerCase().trim()];

  static const Map<String, Muscle> _datasetMap = {
    'chest': Muscle.chest,
    'shoulders': Muscle.frontDelts,
    'front delts': Muscle.frontDelts,
    'side delts': Muscle.sideDelts,
    'rear delts': Muscle.rearDelts,
    'traps': Muscle.traps,
    'neck': Muscle.traps,
    'lats': Muscle.lats,
    'middle back': Muscle.lats,
    'lower back': Muscle.lowerBack,
    'biceps': Muscle.biceps,
    'triceps': Muscle.triceps,
    'forearms': Muscle.forearms,
    'abdominals': Muscle.abs,
    'abs': Muscle.abs,
    'obliques': Muscle.obliques,
    'glutes': Muscle.glutes,
    'quadriceps': Muscle.quads,
    'quads': Muscle.quads,
    'hamstrings': Muscle.hamstrings,
    'calves': Muscle.calves,
    'adductors': Muscle.adductors,
    'abductors': Muscle.glutes,
  };
}

/// How strongly a muscle is involved — drives its color in the anatomy map.
enum MuscleActivation { primary, secondary, stabilizer }
