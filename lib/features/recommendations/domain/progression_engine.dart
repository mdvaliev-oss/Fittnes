import '../../workout/domain/entities/workout_exercise_entry.dart';
import '../../workout/domain/entities/workout_set.dart';
import 'progression_advice.dart';

/// A target repetition window for double-progression.
class RepRange {
  const RepRange(this.min, this.max);
  final int min;
  final int max;

  static const hypertrophy = RepRange(8, 12);
  static const strength = RepRange(3, 6);
}

/// Rule-based auto-progression coach.
///
/// Implements double progression modulated by effort (RPE/RIR): grow reps
/// within [target], then add load; back off when effort is maxed or reps fall
/// short. Pure and deterministic — the core of the "AI trainer".
abstract final class ProgressionEngine {
  const ProgressionEngine._();

  /// Smallest sensible load increment (kg).
  static const double increment = 2.5;

  static ProgressionAdvice recommend(
    WorkoutExerciseEntry? last, {
    RepRange target = RepRange.hypertrophy,
  }) {
    if (last == null) {
      return const ProgressionAdvice(
        action: ProgressionAction.start,
        message:
            'Первая тренировка упражнения — выбери вес на 8–10 повторений с запасом.',
      );
    }

    final working = last.sets
        .where((s) => s.type.countsForVolume && s.isFilled && s.isCompleted)
        .toList();

    if (working.isEmpty) {
      return const ProgressionAdvice(
        action: ProgressionAction.finishSets,
        message:
            'В прошлый раз не было завершённых рабочих подходов — повтори вес и закрой их.',
      );
    }

    final top = working.reduce((a, b) => a.weight! >= b.weight! ? a : b);
    final weight = top.weight!;
    final reps = top.reps!;
    final effort = _effort(top);

    // Systemic fatigue: high effort already on the first working set.
    final first = working.first;
    if (_effort(first) == _Effort.high && working.length >= 2) {
      return ProgressionAdvice(
        action: ProgressionAction.addRest,
        suggestedWeight: weight,
        suggestedReps: reps,
        message:
            'Усилие росло рано — увеличь отдых между подходами на 30–60 c.',
      );
    }

    if (reps >= target.max) {
      if (effort == _Effort.high) {
        return ProgressionAdvice(
          action: ProgressionAction.keepWeight,
          suggestedWeight: weight,
          suggestedReps: reps,
          message:
              'Повторы есть, но усилие максимальное — закрепи $weight кг ещё раз.',
        );
      }
      final next = _round(weight + increment);
      return ProgressionAdvice(
        action: ProgressionAction.increaseWeight,
        suggestedWeight: next,
        suggestedReps: target.min,
        message:
            'Верхняя граница диапазона взята с запасом — подними до $next кг.',
      );
    }

    if (reps < target.min) {
      if (effort == _Effort.high) {
        final next = _round(weight * 0.9);
        return ProgressionAdvice(
          action: ProgressionAction.reduceWeight,
          suggestedWeight: next,
          suggestedReps: target.min,
          message: 'Не добрал повторы на высоком усилии — снизь до $next кг.',
        );
      }
      return ProgressionAdvice(
        action: ProgressionAction.keepWeight,
        suggestedWeight: weight,
        suggestedReps: target.min,
        message: 'Оставь $weight кг и добери до ${target.min} повторений.',
      );
    }

    // Within the target window.
    if (effort == _Effort.low) {
      return ProgressionAdvice(
        action: ProgressionAction.addReps,
        suggestedWeight: weight,
        suggestedReps: reps + 1,
        message:
            'Есть запас — добавь повтор на $weight кг (цель ${target.max}).',
      );
    }
    return ProgressionAdvice(
      action: ProgressionAction.keepWeight,
      suggestedWeight: weight,
      suggestedReps: reps + 1,
      message: 'Закрепи $weight кг и постепенно добавляй повторы.',
    );
  }

  static _Effort _effort(WorkoutSet s) {
    if ((s.rpe != null && s.rpe! >= 9.5) || (s.rir != null && s.rir! <= 0)) {
      return _Effort.high;
    }
    if ((s.rpe != null && s.rpe! <= 8) || (s.rir != null && s.rir! >= 2)) {
      return _Effort.low;
    }
    return _Effort.medium;
  }

  /// Rounds to the nearest [increment] so suggestions are loadable.
  static double _round(double v) => (v / increment).round() * increment;
}

enum _Effort { low, medium, high }
