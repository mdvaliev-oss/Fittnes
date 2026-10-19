import 'dart:ui';

import '../../../domain/entities/movement_pattern.dart';
import 'rig.dart';

/// Everything a painter needs to act out one pattern: the two key poses,
/// which view reads best, what the figure rests on and which muscles to glow.
class PatternSpec {
  const PatternSpec.side({
    required SidePose start,
    required SidePose end,
    this.fixture = Fixture.ground,
    this.emphasis = Emphasis.arms,
    this.focusHand = true,
    this.liftsForward = false,
    this.isStatic = false,
  })  : sideStart = start,
        sideEnd = end,
        frontStart = null,
        frontEnd = null;

  const PatternSpec.front({
    required FrontPose start,
    required FrontPose end,
    this.fixture = Fixture.ground,
    this.emphasis = Emphasis.arms,
    this.focusHand = true,
    this.liftsForward = false,
    this.isStatic = false,
  })  : sideStart = null,
        sideEnd = null,
        frontStart = start,
        frontEnd = end;

  final SidePose? sideStart, sideEnd;
  final FrontPose? frontStart, frontEnd;
  final Fixture fixture;
  final Emphasis emphasis;

  /// Whether the motion guide traces the hand (true) or the hip (false).
  final bool focusHand;

  /// True when start → end is the lifting (concentric) half of the rep —
  /// e.g. a curl starts with the arm down. Presses and squats start at the
  /// top, so their forward half is the lowering.
  final bool liftsForward;

  /// Holds (plank, carry) have no lowering / lifting phase to label.
  final bool isStatic;

  bool get isFront => frontStart != null;

  static PatternSpec of(MovementPattern p) => _specs[p]!;
}

const _ground = Rig.groundY;

// ── Standing anchors ───────────────────────────────────────────────────
const _standHip = Offset(50, 54);

final Map<MovementPattern, PatternSpec> _specs = {
  // ── Legs ─────────────────────────────────────────────────────────────
  MovementPattern.squat: const PatternSpec.front(
    start: FrontPose(
      shoulderY: 31,
      hipY: 50,
      handL: Offset(33, 30),
      handR: Offset(67, 30),
      ankleL: Offset(39, _ground),
      ankleR: Offset(61, _ground),
    ),
    end: FrontPose(
      shoulderY: 46,
      hipY: 66,
      handL: Offset(33, 45),
      handR: Offset(67, 45),
      ankleL: Offset(38, _ground),
      ankleR: Offset(62, _ground),
    ),
    emphasis: Emphasis.legs,
    focusHand: false,
  ),
  MovementPattern.lunge: const PatternSpec.side(
    start: SidePose(
      hip: _standHip,
      hand: Offset(52, 58),
      farHand: Offset(48, 58),
      ankle: Offset(50, _ground),
      farAnkle: Offset(50, _ground),
    ),
    end: SidePose(
      hip: Offset(50, 70),
      lean: 4,
      hand: Offset(53, 72),
      farHand: Offset(47, 72),
      ankle: Offset(66, _ground),
      farAnkle: Offset(30, _ground),
      farKneeBend: -1,
    ),
    emphasis: Emphasis.legs,
    focusHand: false,
  ),
  MovementPattern.hinge: const PatternSpec.side(
    start: SidePose(hip: Offset(50, 54), lean: 3, hand: Offset(53, 60)),
    end: SidePose(
      hip: Offset(43, 58),
      lean: 68,
      hand: Offset(62, 80),
      ankle: Offset(50, _ground),
    ),
    emphasis: Emphasis.back,
  ),
  MovementPattern.hipThrust: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 74),
      lean: -45,
      hand: Offset(47, 68),
      armBend: 1,
      ankle: Offset(62, _ground),
    ),
    end: SidePose(
      hip: Offset(48, 60),
      lean: -84,
      hand: Offset(49, 54),
      armBend: 1,
      ankle: Offset(62, _ground),
    ),
    fixture: Fixture.bench,
    emphasis: Emphasis.legs,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.legPress: const PatternSpec.side(
    start: SidePose(
      hip: Offset(34, 62),
      lean: -40,
      hand: Offset(28, 62),
      armBend: 1,
      ankle: Offset(52, 52),
    ),
    end: SidePose(
      hip: Offset(34, 62),
      lean: -40,
      hand: Offset(28, 62),
      armBend: 1,
      ankle: Offset(66, 46),
    ),
    fixture: Fixture.legPressSled,
    emphasis: Emphasis.legs,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.legExtension: const PatternSpec.side(
    start: SidePose(
      hip: Offset(44, 60),
      lean: -12,
      hand: Offset(50, 62),
      armBend: 1,
      ankle: Offset(60, 80),
    ),
    end: SidePose(
      hip: Offset(44, 60),
      lean: -12,
      hand: Offset(50, 62),
      armBend: 1,
      ankle: Offset(78, 62),
    ),
    fixture: Fixture.seat,
    emphasis: Emphasis.legs,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.legCurl: const PatternSpec.side(
    start: SidePose(
      hip: Offset(44, 62),
      lean: 90,
      hand: Offset(78, 62),
      armBend: 1,
      ankle: Offset(10, 64),
      kneeBend: 1,
    ),
    end: SidePose(
      hip: Offset(44, 62),
      lean: 90,
      hand: Offset(78, 62),
      armBend: 1,
      ankle: Offset(28, 40),
      kneeBend: 1,
    ),
    fixture: Fixture.bench,
    emphasis: Emphasis.legs,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.calfRaise: const PatternSpec.side(
    start: SidePose(hip: _standHip, hand: Offset(52, 58)),
    end: SidePose(
      hip: Offset(50, 48),
      hand: Offset(52, 52),
      ankle: Offset(50, _ground - 6),
      heelLift: 1,
    ),
    emphasis: Emphasis.legs,
    focusHand: false,
    liftsForward: true,
  ),

  // ── Pushes ───────────────────────────────────────────────────────────
  MovementPattern.horizontalPress: const PatternSpec.side(
    start: SidePose(
      hip: Offset(56, 58),
      lean: -90,
      hand: Offset(36, 33),
      armBend: -1,
      ankle: Offset(70, _ground),
    ),
    end: SidePose(
      hip: Offset(56, 58),
      lean: -90,
      hand: Offset(40, 48),
      armBend: -1,
      ankle: Offset(70, _ground),
    ),
    fixture: Fixture.bench,
    emphasis: Emphasis.chest,
  ),
  MovementPattern.fly: const PatternSpec.front(
    start: FrontPose(
      handL: Offset(26, 32),
      handR: Offset(74, 32),
      elbowOut: 1,
    ),
    end: FrontPose(
      handL: Offset(46, 38),
      handR: Offset(54, 38),
      elbowOut: 1,
    ),
    emphasis: Emphasis.chest,
    liftsForward: true,
  ),
  MovementPattern.pushUp: const PatternSpec.side(
    start: SidePose(
      hip: Offset(44, 65),
      lean: 90,
      hand: Offset(66, _ground),
      armBend: 1,
      ankle: Offset(14, _ground - 3),
      kneeBend: -1,
    ),
    end: SidePose(
      hip: Offset(46, 78),
      lean: 90,
      hand: Offset(66, _ground),
      armBend: 1,
      ankle: Offset(16, _ground - 1),
      kneeBend: -1,
    ),
    emphasis: Emphasis.chest,
    focusHand: false,
  ),
  MovementPattern.dip: const PatternSpec.side(
    start: SidePose(
      hip: Offset(56, 54),
      lean: 6,
      hand: Offset(57, 56),
      armBend: -1,
      ankle: Offset(42, 78),
      kneeBend: -1,
    ),
    end: SidePose(
      hip: Offset(54, 68),
      lean: 14,
      hand: Offset(57, 56),
      armBend: -1,
      ankle: Offset(40, 86),
      kneeBend: -1,
    ),
    fixture: Fixture.parallelBars,
    emphasis: Emphasis.chest,
    focusHand: false,
  ),
  MovementPattern.verticalPress: const PatternSpec.side(
    start: SidePose(hip: _standHip, hand: Offset(54, 30), armBend: 1),
    end: SidePose(hip: _standHip, hand: Offset(50, 8), armBend: 1),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),
  MovementPattern.tricepsExtension: const PatternSpec.side(
    start: SidePose(hip: _standHip, shoulderAng: 14, elbowAng: 112),
    end: SidePose(hip: _standHip, shoulderAng: 14, elbowAng: 6),
    emphasis: Emphasis.arms,
    liftsForward: true,
  ),

  // ── Pulls ────────────────────────────────────────────────────────────
  MovementPattern.horizontalPull: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 56),
      lean: 52,
      hand: Offset(66, 70),
      armBend: -1,
    ),
    end: SidePose(
      hip: Offset(46, 56),
      lean: 52,
      hand: Offset(56, 54),
      armBend: -1,
    ),
    emphasis: Emphasis.back,
    liftsForward: true,
  ),
  MovementPattern.verticalPull: const PatternSpec.front(
    start: FrontPose(
      shoulderY: 36,
      hipY: 58,
      handL: Offset(34, 12),
      handR: Offset(66, 12),
      elbowOut: 1,
      ankleL: Offset(44, 92),
      ankleR: Offset(56, 92),
    ),
    end: FrontPose(
      shoulderY: 22,
      hipY: 44,
      handL: Offset(34, 12),
      handR: Offset(66, 12),
      elbowOut: 1,
      ankleL: Offset(44, 78),
      ankleR: Offset(56, 78),
    ),
    fixture: Fixture.overheadBar,
    emphasis: Emphasis.back,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.pullover: const PatternSpec.side(
    start: SidePose(
      hip: Offset(56, 58),
      lean: -90,
      hand: Offset(12, 48),
      armBend: 1,
      ankle: Offset(70, _ground),
    ),
    end: SidePose(
      hip: Offset(56, 58),
      lean: -90,
      hand: Offset(36, 33),
      armBend: 1,
      ankle: Offset(70, _ground),
    ),
    fixture: Fixture.bench,
    emphasis: Emphasis.back,
    liftsForward: true,
  ),
  MovementPattern.facePull: const PatternSpec.side(
    start: SidePose(hip: _standHip, hand: Offset(76, 32), armBend: -1),
    end: SidePose(hip: _standHip, hand: Offset(58, 28), armBend: -1),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),
  MovementPattern.rearDeltFly: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 56),
      lean: 60,
      hand: Offset(66, 70),
      armBend: -1,
    ),
    end: SidePose(
      hip: Offset(46, 56),
      lean: 60,
      hand: Offset(56, 44),
      armBend: -1,
    ),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),
  MovementPattern.shrug: const PatternSpec.front(
    start: FrontPose(
      shoulderY: 32,
      handL: Offset(36, 58),
      handR: Offset(64, 58),
      elbowOut: 1,
    ),
    end: FrontPose(
      shoulderY: 26,
      headY: 16,
      handL: Offset(36, 52),
      handR: Offset(64, 52),
      elbowOut: 1,
    ),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),
  MovementPattern.uprightRow: const PatternSpec.front(
    start: FrontPose(
      handL: Offset(45, 58),
      handR: Offset(55, 58),
      elbowOut: 1,
    ),
    end: FrontPose(
      handL: Offset(45, 34),
      handR: Offset(55, 34),
      elbowOut: 1,
    ),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),

  // ── Arms / shoulders (FK arcs) ───────────────────────────────────────
  MovementPattern.curl: const PatternSpec.side(
    start: SidePose(hip: _standHip, shoulderAng: 14, elbowAng: 8),
    end: SidePose(hip: _standHip, shoulderAng: 20, elbowAng: 134),
    emphasis: Emphasis.arms,
    liftsForward: true,
  ),
  MovementPattern.wristCurl: const PatternSpec.side(
    start: SidePose(
      hip: Offset(44, 60),
      lean: 14,
      shoulderAng: 52,
      elbowAng: 96,
      ankle: Offset(58, _ground),
    ),
    end: SidePose(
      hip: Offset(44, 60),
      lean: 14,
      shoulderAng: 52,
      elbowAng: 104,
      ankle: Offset(58, _ground),
    ),
    fixture: Fixture.seat,
    emphasis: Emphasis.arms,
    liftsForward: true,
  ),
  MovementPattern.lateralRaise: const PatternSpec.front(
    start: FrontPose(handL: Offset(36, 58), handR: Offset(64, 58)),
    end: FrontPose(handL: Offset(14, 30), handR: Offset(86, 30)),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),
  MovementPattern.frontRaise: const PatternSpec.side(
    start: SidePose(hip: _standHip, shoulderAng: 8, elbowAng: 8),
    end: SidePose(hip: _standHip, shoulderAng: 92, elbowAng: 8),
    emphasis: Emphasis.shoulders,
    liftsForward: true,
  ),

  // ── Core ─────────────────────────────────────────────────────────────
  MovementPattern.crunch: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 84),
      lean: -90,
      hand: Offset(14, 78),
      armBend: 1,
      ankle: Offset(66, _ground),
    ),
    end: SidePose(
      hip: Offset(46, 84),
      lean: -58,
      hand: Offset(22, 62),
      armBend: 1,
      ankle: Offset(66, _ground),
    ),
    emphasis: Emphasis.torso,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.legRaise: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 84),
      lean: -90,
      hand: Offset(30, 88),
      armBend: 1,
      ankle: Offset(82, _ground),
    ),
    end: SidePose(
      hip: Offset(46, 84),
      lean: -90,
      hand: Offset(30, 88),
      armBend: 1,
      ankle: Offset(50, 48),
    ),
    emphasis: Emphasis.torso,
    focusHand: false,
    liftsForward: true,
  ),
  MovementPattern.plank: const PatternSpec.side(
    start: SidePose(
      hip: Offset(46, 78),
      lean: 88,
      hand: Offset(80, _ground),
      armBend: 1,
      ankle: Offset(14, _ground - 1),
      kneeBend: -1,
    ),
    end: SidePose(
      hip: Offset(46, 79),
      lean: 88,
      hand: Offset(80, _ground),
      armBend: 1,
      ankle: Offset(14, _ground - 1),
      kneeBend: -1,
    ),
    emphasis: Emphasis.torso,
    focusHand: false,
    isStatic: true,
  ),
  MovementPattern.rollout: const PatternSpec.side(
    start: SidePose(
      hip: Offset(48, 72),
      lean: 28,
      hand: Offset(64, 82),
      armBend: -1,
      ankle: Offset(26, _ground),
      kneeBend: 1,
    ),
    end: SidePose(
      hip: Offset(54, 76),
      lean: 80,
      hand: Offset(88, 86),
      armBend: -1,
      ankle: Offset(26, _ground),
      kneeBend: 1,
    ),
    fixture: Fixture.wheel,
    emphasis: Emphasis.torso,
  ),
  MovementPattern.carry: const PatternSpec.side(
    start: SidePose(
      hip: Offset(50, 54),
      shoulderAng: 4,
      elbowAng: 2,
      ankle: Offset(58, _ground),
      farAnkle: Offset(42, _ground),
    ),
    end: SidePose(
      hip: Offset(50, 55),
      shoulderAng: 4,
      elbowAng: 2,
      ankle: Offset(42, _ground),
      farAnkle: Offset(58, _ground),
    ),
    emphasis: Emphasis.torso,
    focusHand: false,
    isStatic: true,
  ),
  MovementPattern.generic: const PatternSpec.side(
    start: SidePose(hip: Offset(50, 54), shoulderAng: 26, elbowAng: 34),
    end: SidePose(hip: Offset(50, 58), shoulderAng: 34, elbowAng: 50),
    emphasis: Emphasis.torso,
  ),
};
