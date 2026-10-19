import 'exercise.dart';
import 'exercise_enums.dart';
import 'muscle.dart';

/// A recognizable movement pattern the technique figure can act out.
///
/// The seed states it explicitly (`pattern`), so what the animation shows is
/// curated, not guessed. [forExercise] remains as a fallback classifier for
/// imported data that lacks the field.
enum MovementPattern {
  squat('Присед'),
  lunge('Выпад'),
  hinge('Наклон / тяга с пола'),
  hipThrust('Разгибание таза'),
  legPress('Жим ногами'),
  horizontalPress('Горизонтальный жим'),
  pushUp('Отжимание'),
  dip('Брусья'),
  verticalPress('Жим над головой'),
  horizontalPull('Горизонтальная тяга'),
  verticalPull('Вертикальная тяга'),
  pullover('Пуловер'),
  facePull('Тяга к лицу'),
  shrug('Шраги'),
  uprightRow('Тяга к подбородку'),
  curl('Сгибание рук'),
  tricepsExtension('Разгибание рук'),
  wristCurl('Запястья'),
  lateralRaise('Махи в стороны'),
  frontRaise('Подъём перед собой'),
  fly('Разведение / сведение'),
  rearDeltFly('Разведение назад'),
  calfRaise('Подъём на носки'),
  legExtension('Разгибание ног'),
  legCurl('Сгибание ног'),
  crunch('Скручивание'),
  legRaise('Подъём ног'),
  plank('Статика кора'),
  rollout('Выкат'),
  carry('Переноска'),
  generic('Движение');

  const MovementPattern(this.label);

  /// Short Russian label for chips and cards.
  final String label;

  /// Parses the seed's `pattern` field; `null` for unknown / missing values.
  static MovementPattern? fromDataset(String? raw) =>
      raw == null ? null : values.asNameMap()[raw.trim()];

  /// Best-effort classification. Keyword match (RU + EN) first, then a
  /// fallback by [ForceType] + primary [Muscle]s.
  static MovementPattern forExercise(Exercise e) {
    final hay = '${e.name} ${e.altName ?? ''} ${e.id}'.toLowerCase();

    bool has(List<String> keys) => keys.any(hay.contains);

    if (has(['выпад', 'lunge', 'split squat', 'зашагиван', 'step-up'])) {
      return MovementPattern.lunge;
    }
    if (has(['жим ног', 'leg press'])) return MovementPattern.legPress;
    if (has(['присед', 'squat', 'goblet', 'hack', 'гакк', 'пистолет'])) {
      return MovementPattern.squat;
    }
    if (has(['мост', 'thrust', 'bridge'])) return MovementPattern.hipThrust;
    if (has([
      'становая',
      'deadlift',
      'румын',
      'rdl',
      'hinge',
      'good morning',
      'наклон',
      'гиперэкстен',
      'hyperextension',
      'back extension',
      'swing',
      'махи гирей',
    ])) {
      return MovementPattern.hinge;
    }
    if (has(['подъём на носк', 'подъем на носк', 'носки', 'calf', 'икр'])) {
      return MovementPattern.calfRaise;
    }
    if (has(['разгибание ног', 'leg extension'])) {
      return MovementPattern.legExtension;
    }
    if (has(['сгибание ног', 'leg curl', 'нордич', 'nordic'])) {
      return MovementPattern.legCurl;
    }
    if (has(['шраг', 'shrug'])) return MovementPattern.shrug;
    if (has(['к подбородку', 'upright'])) return MovementPattern.uprightRow;
    if (has(['к лицу', 'face pull'])) return MovementPattern.facePull;
    if (has(['пуловер', 'pullover', 'прямыми руками', 'straight-arm'])) {
      return MovementPattern.pullover;
    }
    if (has([
      'подтяг',
      'pull-up',
      'pullup',
      'pull up',
      'верхнего блока',
      'pulldown',
      'lat pulldown',
      'широчайш',
    ])) {
      return MovementPattern.verticalPull;
    }
    if (has(['тяга', 'row', 'к поясу', 'к животу'])) {
      return MovementPattern.horizontalPull;
    }
    if (has(['запяст', 'wrist'])) return MovementPattern.wristCurl;
    if (has([
      'french',
      'французс',
      'pushdown',
      'на трицепс',
      'разгибание рук',
      'triceps extension',
      'разгибания на трицепс',
      'kickback',
    ])) {
      return MovementPattern.tricepsExtension;
    }
    if (has(['curl', 'сгибан', 'на бицепс', 'бицепс'])) {
      return MovementPattern.curl;
    }
    if (has(['в наклоне', 'заднюю дельт', 'rear delt', 'pull-apart'])) {
      return MovementPattern.rearDeltFly;
    }
    if (has(['сведение', 'кроссовер', 'crossover', 'pec deck', 'бабочка']) ||
        (hay.contains('разведен') && hay.contains('лёж'))) {
      return MovementPattern.fly;
    }
    if (has(['перед собой', 'front raise'])) return MovementPattern.frontRaise;
    if (has(['махи', 'lateral', 'разведен', 'raise', 'в стороны'])) {
      return MovementPattern.lateralRaise;
    }
    if (has([
      'над головой',
      'overhead',
      'military',
      'жим стоя',
      'жим сидя',
      'shoulder press',
      'arnold',
      'арнольд',
      'швунг',
      'стойке на руках',
      'handstand',
      'уголком',
      'pike',
    ])) {
      return MovementPattern.verticalPress;
    }
    if (has(['брусь', 'dip'])) return MovementPattern.dip;
    if (has(['отжим', 'push-up', 'push up', 'бёрпи', 'burpee'])) {
      return MovementPattern.pushUp;
    }
    if (has(['жим лёжа', 'жим лежа', 'bench', 'chest press', 'fly'])) {
      return MovementPattern.horizontalPress;
    }
    if (has(['ролик', 'rollout', 'выкат'])) return MovementPattern.rollout;
    if (has(['планка', 'plank', 'лодочк', 'hollow', 'паллоф', 'pallof'])) {
      return MovementPattern.plank;
    }
    if (has(['подъём ног', 'подъем ног', 'leg raise', 'жук', 'dead bug'])) {
      return MovementPattern.legRaise;
    }
    if (has(['скручиван', 'crunch', 'sit-up', 'складка', 'v-up', 'пресс'])) {
      return MovementPattern.crunch;
    }
    if (has(['прогулка', 'walk', 'carry'])) return MovementPattern.carry;

    // Fallback: infer from anatomy + force.
    final primary = e.primaryMuscles.toSet();
    if (primary.contains(Muscle.calves)) return MovementPattern.calfRaise;
    if (primary.contains(Muscle.quads) || primary.contains(Muscle.glutes)) {
      return e.force == ForceType.pull
          ? MovementPattern.hinge
          : MovementPattern.squat;
    }
    if (primary.contains(Muscle.hamstrings) ||
        primary.contains(Muscle.lowerBack)) {
      return MovementPattern.hinge;
    }
    if (primary.contains(Muscle.chest)) return MovementPattern.horizontalPress;
    if (primary.contains(Muscle.lats) || primary.contains(Muscle.traps)) {
      return MovementPattern.horizontalPull;
    }
    if (primary.contains(Muscle.frontDelts) ||
        primary.contains(Muscle.sideDelts)) {
      return primary.contains(Muscle.sideDelts)
          ? MovementPattern.lateralRaise
          : MovementPattern.verticalPress;
    }
    if (primary.contains(Muscle.rearDelts)) return MovementPattern.rearDeltFly;
    if (primary.contains(Muscle.biceps)) return MovementPattern.curl;
    if (primary.contains(Muscle.triceps)) {
      return MovementPattern.tricepsExtension;
    }
    if (primary.contains(Muscle.abs) || primary.contains(Muscle.obliques)) {
      return MovementPattern.crunch;
    }
    return switch (e.force) {
      ForceType.push => MovementPattern.horizontalPress,
      ForceType.pull => MovementPattern.horizontalPull,
      _ => MovementPattern.generic,
    };
  }
}
