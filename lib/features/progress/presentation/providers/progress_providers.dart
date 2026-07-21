import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currently selected exercise id for the strength chart (null → first).
final selectedProgressExerciseProvider = StateProvider<String?>((ref) => null);
