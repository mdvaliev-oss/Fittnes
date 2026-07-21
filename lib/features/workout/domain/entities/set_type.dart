/// The role of a set within an exercise.
enum SetType {
  warmup('Разминочный', 'W'),
  normal('Рабочий', ''),
  dropset('Дропсет', 'D'),
  failure('До отказа', 'F');

  const SetType(this.label, this.badge);

  final String label;

  /// Short badge shown in the set row (empty for normal sets, where the
  /// running set number is shown instead).
  final String badge;

  /// Warm-up sets are excluded from working volume and PR calculations.
  bool get countsForVolume => this != SetType.warmup;
}
