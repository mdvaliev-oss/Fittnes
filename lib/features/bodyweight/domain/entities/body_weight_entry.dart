/// One body-weight measurement. [kg] is canonical — the UI converts to and
/// from the user's display unit at the input / render boundary only.
class BodyWeightEntry {
  const BodyWeightEntry({
    this.id = 0,
    required this.measuredAt,
    required this.kg,
  });

  /// Database id; `0` for a not-yet-persisted entry.
  final int id;
  final DateTime measuredAt;
  final double kg;

  BodyWeightEntry copyWith({int? id, DateTime? measuredAt, double? kg}) =>
      BodyWeightEntry(
        id: id ?? this.id,
        measuredAt: measuredAt ?? this.measuredAt,
        kg: kg ?? this.kg,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'measuredAt': measuredAt.toIso8601String(),
        'kg': kg,
      };

  factory BodyWeightEntry.fromJson(Map<String, dynamic> j) => BodyWeightEntry(
        id: (j['id'] as num?)?.toInt() ?? 0,
        measuredAt: DateTime.parse(j['measuredAt'] as String),
        kg: (j['kg'] as num).toDouble(),
      );
}
