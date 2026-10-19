import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/core/theme/app_theme.dart';
import 'package:fittnes/features/workout/domain/entities/workout_set.dart';
import 'package:fittnes/features/workout/presentation/providers/active_workout_controller.dart';
import 'package:fittnes/features/workout/presentation/widgets/set_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('tapping the unit suffix flips кг ⇄ lb and re-expresses weight',
      (tester) async {
    await pumpApp(
      tester,
      const SetRow(
        entryId: 1,
        index: 1,
        restSeconds: 90,
        set: WorkoutSet(id: 1, weight: 100, reps: 5),
      ),
      size: const Size(500, 300),
    );
    await tester.pumpAndSettle();

    final weightField = find.byType(TextField).first;
    expect(tester.widget<TextField>(weightField).controller!.text, '100');
    expect(find.text('кг'), findsOneWidget);

    await tester.tap(find.text('кг'));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(SetRow)));
    expect(container.read(appSettingsProvider).unit, WeightUnit.lb);
    expect(find.text('lb'), findsOneWidget);
    expect(tester.widget<TextField>(weightField).controller!.text, '220');
  });

  testWidgets('typing in lb stores canonical kg on the controller',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(appSettingsProvider.notifier).setUnit(WeightUnit.lb);
    container.read(activeWorkoutControllerProvider.notifier)
      ..start()
      ..addExerciseRef('bench', 'Жим');
    final entry =
        container.read(activeWorkoutControllerProvider)!.entries.single;

    tester.view.physicalSize = const Size(500, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SetRow(
              entryId: entry.id,
              index: 1,
              restSeconds: 90,
              set: entry.sets.single,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '220');
    await tester.pumpAndSettle();

    final saved = container
        .read(activeWorkoutControllerProvider)!
        .entries
        .single
        .sets
        .single
        .weight;
    expect(saved, closeTo(99.79, 0.01));
  });
}
