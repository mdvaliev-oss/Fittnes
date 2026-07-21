import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exercise_enums.dart';

/// Maps exercise enums onto icons and colors — one place so cards, detail and
/// filters stay visually consistent.
abstract final class ExerciseVisuals {
  const ExerciseVisuals._();

  static IconData equipmentIcon(Equipment e) => switch (e) {
        Equipment.barbell => Icons.fitness_center_rounded,
        Equipment.dumbbell => Icons.sports_gymnastics_rounded,
        Equipment.machine => Icons.precision_manufacturing_rounded,
        Equipment.cable => Icons.cable_rounded,
        Equipment.bodyweight => Icons.accessibility_new_rounded,
        Equipment.kettlebell => Icons.sports_kabaddi_rounded,
        Equipment.bands => Icons.waves_rounded,
        Equipment.smithMachine => Icons.view_column_rounded,
        Equipment.ezBar => Icons.fitness_center_rounded,
        Equipment.other => Icons.category_rounded,
      };

  static IconData categoryIcon(ExerciseCategory c) => switch (c) {
        ExerciseCategory.strength => Icons.bolt_rounded,
        ExerciseCategory.hypertrophy => Icons.fitness_center_rounded,
        ExerciseCategory.powerlifting => Icons.emoji_events_rounded,
        ExerciseCategory.olympic => Icons.sports_martial_arts_rounded,
        ExerciseCategory.cardio => Icons.directions_run_rounded,
        ExerciseCategory.stretching => Icons.self_improvement_rounded,
        ExerciseCategory.plyometrics => Icons.rocket_launch_rounded,
      };

  static Color levelColor(ExperienceLevel l) => switch (l) {
        ExperienceLevel.beginner => AppColors.accent,
        ExperienceLevel.intermediate => AppColors.warning,
        ExperienceLevel.advanced => AppColors.danger,
      };
}
