import '../../exercises/domain/entities/exercise_enums.dart' show ExperienceLevel;

enum Sex {
  male('Мужской'),
  female('Женский'),
  other('Другой');

  const Sex(this.label);
  final String label;
}

enum TrainingGoal {
  strength('Сила'),
  muscle('Набор мышц'),
  fatLoss('Снижение жира'),
  endurance('Выносливость'),
  general('Общая форма');

  const TrainingGoal(this.label);
  final String label;
}

/// The athlete's profile. Immutable; persisted as JSON.
class UserProfile {
  const UserProfile({
    this.name,
    this.age,
    this.heightCm,
    this.weightKg,
    this.sex = Sex.male,
    this.goal = TrainingGoal.muscle,
    this.experience = ExperienceLevel.intermediate,
    this.benchMax,
    this.squatMax,
    this.deadliftMax,
    this.trainsAtHome = false,
  });

  final String? name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final Sex sex;
  final TrainingGoal goal;
  final ExperienceLevel experience;
  final double? benchMax;
  final double? squatMax;
  final double? deadliftMax;
  final bool trainsAtHome;

  static const empty = UserProfile();

  UserProfile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? weightKg,
    Sex? sex,
    TrainingGoal? goal,
    ExperienceLevel? experience,
    double? benchMax,
    double? squatMax,
    double? deadliftMax,
    bool? trainsAtHome,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sex: sex ?? this.sex,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      benchMax: benchMax ?? this.benchMax,
      squatMax: squatMax ?? this.squatMax,
      deadliftMax: deadliftMax ?? this.deadliftMax,
      trainsAtHome: trainsAtHome ?? this.trainsAtHome,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'sex': sex.name,
        'goal': goal.name,
        'experience': experience.name,
        'benchMax': benchMax,
        'squatMax': squatMax,
        'deadliftMax': deadliftMax,
        'trainsAtHome': trainsAtHome,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String?,
        age: (json['age'] as num?)?.toInt(),
        heightCm: (json['heightCm'] as num?)?.toDouble(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        sex: Sex.values.asNameMap()[json['sex']] ?? Sex.male,
        goal: TrainingGoal.values.asNameMap()[json['goal']] ?? TrainingGoal.muscle,
        experience: ExperienceLevel.values.asNameMap()[json['experience']] ??
            ExperienceLevel.intermediate,
        benchMax: (json['benchMax'] as num?)?.toDouble(),
        squatMax: (json['squatMax'] as num?)?.toDouble(),
        deadliftMax: (json['deadliftMax'] as num?)?.toDouble(),
        trainsAtHome: json['trainsAtHome'] as bool? ?? false,
      );
}
