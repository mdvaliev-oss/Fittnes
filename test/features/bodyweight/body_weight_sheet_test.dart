import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/features/bodyweight/data/body_weight_repository_memory.dart';
import 'package:fittnes/features/bodyweight/presentation/providers/body_weight_providers.dart';
import 'package:fittnes/features/bodyweight/presentation/widgets/body_weight_sheet.dart';
import 'package:fittnes/features/profile/presentation/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('a value typed in lb is stored in kg and mirrored to profile',
      (tester) async {
    final repo = BodyWeightRepositoryMemory();
    await pumpApp(
      tester,
      const BodyWeightSheet(),
      overrides: [bodyWeightRepositoryProvider.overrideWithValue(repo)],
      size: const Size(500, 900),
    );
    await tester.pumpAndSettle();

    // Switch the inline toggle to pounds, type 180 lb.
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '180');
    await tester.pumpAndSettle();

    // Live conversion hint shows the kilogram equivalent.
    expect(find.textContaining('= 81.6 кг'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final saved = await repo.all();
    expect(saved, hasLength(1));
    expect(saved.single.kg, closeTo(81.65, 0.01));

    final element = tester.element(find.byType(BodyWeightSheet));
    final container = ProviderScope.containerOf(element);
    expect(container.read(profileProvider).weightKg, closeTo(81.65, 0.01));
  });

  testWidgets('switching units re-expresses the typed value', (tester) async {
    await pumpApp(
      tester,
      const BodyWeightSheet(),
      overrides: [
        bodyWeightRepositoryProvider
            .overrideWithValue(BodyWeightRepositoryMemory()),
      ],
      size: const Size(500, 900),
    );
    await tester.pumpAndSettle();

    final element = tester.element(find.byType(BodyWeightSheet));
    expect(
      ProviderScope.containerOf(element).read(appSettingsProvider).unit,
      WeightUnit.kg,
    );

    await tester.enterText(find.byType(TextField), '80');
    await tester.pumpAndSettle();
    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '176');
  });
}
