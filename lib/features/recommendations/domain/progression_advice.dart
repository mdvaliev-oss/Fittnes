import 'package:flutter/material.dart';

/// The recommended action after analysing the last performance of an exercise.
enum ProgressionAction {
  start('Стартовый вес', Icons.flag_rounded, Color(0xFF8B7CF6)),
  increaseWeight('Поднять вес', Icons.trending_up_rounded, Color(0xFF00E5A0)),
  addReps('Добавить повтор', Icons.add_rounded, Color(0xFF00E5A0)),
  keepWeight('Закрепить вес', Icons.remove_rounded, Color(0xFFA0A0B0)),
  reduceWeight('Снизить вес', Icons.trending_down_rounded, Color(0xFFFFB020)),
  deload('Разгрузка', Icons.self_improvement_rounded, Color(0xFFFFB020)),
  addRest('Больше отдыха', Icons.timer_rounded, Color(0xFFFFB020)),
  finishSets('Заверши подходы', Icons.checklist_rounded, Color(0xFFA0A0B0));

  const ProgressionAction(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// The engine's recommendation for the next session of an exercise.
@immutable
class ProgressionAdvice {
  const ProgressionAdvice({
    required this.action,
    required this.message,
    this.suggestedWeight,
    this.suggestedReps,
  });

  final ProgressionAction action;

  /// Coach-style explanation shown to the user.
  final String message;

  /// Weight to prefill for the next top set, if applicable.
  final double? suggestedWeight;
  final int? suggestedReps;
}
