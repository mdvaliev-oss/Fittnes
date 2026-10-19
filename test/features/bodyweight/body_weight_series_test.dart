import 'package:fittnes/features/bodyweight/domain/body_weight_series.dart';
import 'package:fittnes/features/bodyweight/domain/entities/body_weight_entry.dart';
import 'package:flutter_test/flutter_test.dart';

BodyWeightEntry _e(int id, DateTime at, double kg) =>
    BodyWeightEntry(id: id, measuredAt: at, kg: kg);

void main() {
  final now = DateTime(2026, 6, 30, 12);

  test('empty history yields an empty summary', () {
    final s = summarizeBodyWeight(const [], now: now);
    expect(s.latest, isNull);
    expect(s.change, isNull);
  });

  test('summary picks the latest by date and the 30-day change', () {
    final entries = [
      _e(1, DateTime(2026, 4, 1), 85), // outside the window — ignored
      _e(3, DateTime(2026, 6, 28), 81.6),
      _e(2, DateTime(2026, 6, 5), 83),
    ];
    final s = summarizeBodyWeight(entries, now: now);
    expect(s.latest!.id, 3);
    expect(s.change, closeTo(-1.4, 1e-9));
  });

  test('change is null with a single point in the window', () {
    final entries = [
      _e(1, DateTime(2026, 1, 1), 90),
      _e(2, DateTime(2026, 6, 20), 82),
    ];
    expect(summarizeBodyWeight(entries, now: now).change, isNull);
  });

  test('chart points are ascending and trimmed to the window', () {
    final entries = [
      _e(3, DateTime(2026, 6, 20), 82),
      _e(1, DateTime(2025, 1, 1), 95),
      _e(2, DateTime(2026, 5, 1), 84),
    ];
    final pts = bodyWeightChartPoints(entries, days: 90, now: now);
    expect(pts.map((p) => p.id), [2, 3]);
  });

  test('chart falls back to the whole history when the window is sparse', () {
    final entries = [
      _e(1, DateTime(2025, 1, 1), 95),
      _e(2, DateTime(2026, 6, 20), 82),
    ];
    final pts = bodyWeightChartPoints(entries, days: 90, now: now);
    expect(pts.map((p) => p.id), [1, 2]);
  });

  test('entry JSON round-trips', () {
    final e = _e(5, DateTime(2026, 3, 3, 8, 30), 77.25);
    final back = BodyWeightEntry.fromJson(e.toJson());
    expect(back.id, 5);
    expect(back.kg, 77.25);
    expect(back.measuredAt, e.measuredAt);
  });
}
