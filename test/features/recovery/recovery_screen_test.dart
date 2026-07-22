import 'package:fittnes/features/exercises/domain/entities/muscle.dart';
import 'package:fittnes/features/recovery/domain/recovery_model.dart';
import 'package:fittnes/features/recovery/presentation/recovery_providers.dart';
import 'package:fittnes/features/recovery/presentation/recovery_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('empty recovery shows the fresh-muscles state', (tester) async {
    await pumpApp(
      tester,
      const RecoveryScreen(),
      overrides: [
        muscleRecoveryProvider
            .overrideWith((ref) async => const MuscleRecovery({})),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Мышцы свежие'), findsOneWidget);
  });

  testWidgets('with fatigue shows readiness, heat map and muscle rows',
      (tester) async {
    await pumpApp(
      tester,
      const RecoveryScreen(),
      overrides: [
        muscleRecoveryProvider.overrideWith(
          (ref) async =>
              const MuscleRecovery({Muscle.chest: 0.6, Muscle.quads: 0.3}),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Готовность тела'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget); // 1 - (0.6+0.3)/2
    expect(find.text('Грудь'), findsOneWidget);
    expect(find.text('Квадрицепс'), findsOneWidget);
  });
}
