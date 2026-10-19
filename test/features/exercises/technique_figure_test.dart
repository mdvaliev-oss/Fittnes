import 'package:fittnes/features/exercises/domain/entities/exercise_enums.dart';
import 'package:fittnes/features/exercises/domain/entities/movement_pattern.dart';
import 'package:fittnes/features/exercises/presentation/widgets/technique/keyframes.dart';
import 'package:fittnes/features/exercises/presentation/widgets/technique/rig.dart';
import 'package:fittnes/features/exercises/presentation/widgets/technique_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every pattern has a spec with two key poses', () {
    for (final p in MovementPattern.values) {
      final spec = PatternSpec.of(p);
      expect(
        spec.isFront
            ? spec.frontStart != null && spec.frontEnd != null
            : spec.sideStart != null && spec.sideEnd != null,
        isTrue,
        reason: p.name,
      );
    }
  });

  test('ease holds at both extremes and is monotonic in between', () {
    expect(Rig.ease(0), 0);
    expect(Rig.ease(0.05), 0);
    expect(Rig.ease(0.95), 1);
    expect(Rig.ease(1), 1);
    var prev = 0.0;
    for (var i = 0; i <= 20; i++) {
      final v = Rig.ease(i / 20);
      expect(v, greaterThanOrEqualTo(prev));
      prev = v;
    }
  });

  test('two-bone IK keeps bone lengths and respects the bend side', () {
    const root = Offset(50, 30);
    const target = Offset(60, 48);
    final right = Rig.solveJoint(root, target, 13, 12, 1);
    final left = Rig.solveJoint(root, target, 13, 12, -1);
    expect((right - root).distance, closeTo(13, 1e-6));
    expect((right - target).distance, closeTo(12, 1e-6));
    expect((left - root).distance, closeTo(13, 1e-6));
    // Mirror images across the root→target line.
    expect(right.dx + left.dx, isNot(closeTo(2 * right.dx, 1e-6)));
  });

  test('out-of-reach targets are clamped to a straight limb', () {
    const root = Offset(0, 0);
    final hand = Rig.clampReach(root, const Offset(100, 0), 25);
    expect(hand.dx, closeTo(25, 1e-9));
    // Reach is shaved by a hair so the IK never hits a degenerate triangle.
    final joint = Rig.solveJoint(root, hand, 13, 12, 1);
    expect(joint.dx, closeTo(13, 0.05));
    expect(joint.dy.abs(), lessThan(0.5));
  });

  testWidgets('every pattern × equipment paints without throwing',
      (tester) async {
    for (final p in MovementPattern.values) {
      for (final eq in [
        Equipment.barbell,
        Equipment.dumbbell,
        Equipment.cable,
        Equipment.bodyweight,
        Equipment.kettlebell,
      ]) {
        for (final t in [0.0, 0.5, 1.0]) {
          await tester.pumpWidget(
            MaterialApp(
              home: SizedBox(
                width: 320,
                height: 200,
                child: AnimatedTechniqueFigure(
                  progress: t,
                  pattern: p,
                  equipment: eq,
                  glow: 0.7,
                ),
              ),
            ),
          );
        }
      }
    }
    expect(tester.takeException(), isNull);
  });
}
