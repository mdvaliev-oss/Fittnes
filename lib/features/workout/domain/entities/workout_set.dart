import '../../../../core/utils/one_rep_max.dart';
import 'set_type.dart';

/// A single logged set: weight × reps plus effort (RPE/RIR) and completion.
///
/// Immutable value object; the controller replaces sets via [copyWith].
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    this.weight,
    this.reps,
    this.rpe,
    this.rir,
    this.type = SetType.normal,
    this.isCompleted = false,
    this.note,
  });

  final int id;
  final double? weight;
  final int? reps;

  /// Rate of Perceived Exertion (6–10 scale).
  final double? rpe;

  /// Reps In Reserve.
  final int? rir;

  final SetType type;
  final bool isCompleted;
  final String? note;

  /// Tonnage of this set (0 unless it has weight, reps and counts for volume).
  double get volume {
    if (!type.countsForVolume || weight == null || reps == null) return 0;
    return weight! * reps!;
  }

  /// Estimated 1RM for this set (0 if not applicable).
  double get estimatedOneRepMax {
    if (!type.countsForVolume || weight == null || reps == null) return 0;
    return OneRepMax.epley(weight!, reps!);
  }

  /// A set is loggable once it has both weight and reps.
  bool get isFilled => weight != null && reps != null;

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    double? rpe,
    int? rir,
    SetType? type,
    bool? isCompleted,
    String? note,
    bool clearRpe = false,
    bool clearRir = false,
  }) {
    return WorkoutSet(
      id: id,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rpe: clearRpe ? null : (rpe ?? this.rpe),
      rir: clearRir ? null : (rir ?? this.rir),
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
    );
  }
}
