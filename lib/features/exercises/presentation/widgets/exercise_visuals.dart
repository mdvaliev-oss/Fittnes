import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/exercise_enums.dart';
import '../../domain/entities/movement_pattern.dart';
import '../../domain/entities/muscle_group.dart';

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

  static IconData groupIcon(MuscleGroup g) => switch (g) {
        MuscleGroup.chest => Icons.favorite_rounded,
        MuscleGroup.back => Icons.view_week_rounded,
        MuscleGroup.shoulders => Icons.expand_rounded,
        MuscleGroup.arms => Icons.sports_martial_arts_rounded,
        MuscleGroup.legs => Icons.directions_walk_rounded,
        MuscleGroup.glutes => Icons.airline_seat_legroom_extra_rounded,
        MuscleGroup.core => Icons.grid_view_rounded,
      };

  static IconData patternIcon(MovementPattern p) => switch (p) {
        MovementPattern.squat ||
        MovementPattern.lunge ||
        MovementPattern.legPress =>
          Icons.airline_seat_legroom_reduced_rounded,
        MovementPattern.hinge ||
        MovementPattern.hipThrust =>
          Icons.swap_vert_rounded,
        MovementPattern.horizontalPress ||
        MovementPattern.pushUp ||
        MovementPattern.dip ||
        MovementPattern.fly =>
          Icons.open_in_full_rounded,
        MovementPattern.verticalPress ||
        MovementPattern.frontRaise ||
        MovementPattern.lateralRaise =>
          Icons.north_rounded,
        MovementPattern.horizontalPull ||
        MovementPattern.facePull ||
        MovementPattern.rearDeltFly =>
          Icons.west_rounded,
        MovementPattern.verticalPull ||
        MovementPattern.pullover ||
        MovementPattern.shrug ||
        MovementPattern.uprightRow =>
          Icons.south_rounded,
        MovementPattern.curl ||
        MovementPattern.wristCurl ||
        MovementPattern.tricepsExtension =>
          Icons.rotate_left_rounded,
        MovementPattern.calfRaise ||
        MovementPattern.legExtension ||
        MovementPattern.legCurl =>
          Icons.height_rounded,
        MovementPattern.crunch ||
        MovementPattern.legRaise ||
        MovementPattern.rollout =>
          Icons.unfold_less_rounded,
        MovementPattern.plank ||
        MovementPattern.carry ||
        MovementPattern.generic =>
          Icons.horizontal_rule_rounded,
      };

  static Color levelColor(ExperienceLevel l) => switch (l) {
        ExperienceLevel.beginner => AppColors.accent,
        ExperienceLevel.intermediate => AppColors.warning,
        ExperienceLevel.advanced => AppColors.danger,
      };
}
