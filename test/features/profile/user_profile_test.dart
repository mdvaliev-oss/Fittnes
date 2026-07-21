import 'dart:convert';

import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('round-trips through JSON', () {
      const profile = UserProfile(
        name: 'Марат',
        age: 30,
        heightCm: 180,
        weightKg: 82.5,
        sex: Sex.male,
        goal: TrainingGoal.strength,
        experience: ExperienceLevel.advanced,
        benchMax: 140,
        squatMax: 180,
        deadliftMax: 220,
        trainsAtHome: true,
      );

      final decoded =
          UserProfile.fromJson(jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>);

      expect(decoded.name, 'Марат');
      expect(decoded.age, 30);
      expect(decoded.weightKg, 82.5);
      expect(decoded.goal, TrainingGoal.strength);
      expect(decoded.experience, ExperienceLevel.advanced);
      expect(decoded.deadliftMax, 220);
      expect(decoded.trainsAtHome, isTrue);
    });

    test('defaults are applied for missing / unknown fields', () {
      final p = UserProfile.fromJson({'sex': 'unknown', 'goal': 'nope'});
      expect(p.sex, Sex.male);
      expect(p.goal, TrainingGoal.muscle);
      expect(p.experience, ExperienceLevel.intermediate);
      expect(p.age, isNull);
    });
  });
}
