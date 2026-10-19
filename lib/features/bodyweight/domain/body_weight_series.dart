import 'entities/body_weight_entry.dart';

/// Headline numbers for the body-weight card: the latest value and how it
/// moved over the trailing [BodyWeightSummary.window].
class BodyWeightSummary {
  const BodyWeightSummary({required this.latest, required this.change});

  static const Duration window = Duration(days: 30);

  final BodyWeightEntry? latest;

  /// `latest − oldest measurement inside the window`, or `null` when fewer
  /// than two measurements fall inside it.
  final double? change;
}

/// Summarises [entries] (any order) relative to [now].
BodyWeightSummary summarizeBodyWeight(
  List<BodyWeightEntry> entries, {
  DateTime? now,
}) {
  if (entries.isEmpty) {
    return const BodyWeightSummary(latest: null, change: null);
  }
  final sorted = [...entries]
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  final latest = sorted.last;
  final since = (now ?? DateTime.now()).subtract(BodyWeightSummary.window);
  final inWindow = sorted.where((e) => !e.measuredAt.isBefore(since)).toList();
  final change = inWindow.length < 2 ? null : latest.kg - inWindow.first.kg;
  return BodyWeightSummary(latest: latest, change: change);
}

/// Points for the chart, oldest first. Keeps the trailing [days]; if that
/// leaves fewer than two points, falls back to the whole history so a sparse
/// log still draws a line.
List<BodyWeightEntry> bodyWeightChartPoints(
  List<BodyWeightEntry> entries, {
  int days = 90,
  DateTime? now,
}) {
  final sorted = [...entries]
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  final since = (now ?? DateTime.now()).subtract(Duration(days: days));
  final recent = sorted.where((e) => !e.measuredAt.isBefore(since)).toList();
  return recent.length >= 2 ? recent : sorted;
}
