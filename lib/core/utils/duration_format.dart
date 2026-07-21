/// Formats a [Duration] as `m:ss` (or `h:mm:ss` past an hour).
String formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Formats a whole number of seconds as `m:ss`.
String formatSeconds(int seconds) => formatClock(Duration(seconds: seconds));
