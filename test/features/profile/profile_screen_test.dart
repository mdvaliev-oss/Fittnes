import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/features/profile/presentation/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('edits the goal and reflects it in the header', (tester) async {
    await pumpApp(
      tester,
      const ProfileScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Профиль'), findsOneWidget);
    // Default goal · experience subtitle.
    expect(find.text('Набор мышц · Средний'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Сила'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Сила'));
    await tester.pumpAndSettle();

    expect(find.text('Сила · Средний'), findsOneWidget);
  });

  testWidgets('rest picker changes the default rest in settings',
      (tester) async {
    await pumpApp(tester, const ProfileScreen());
    await tester.pumpAndSettle();

    expect(find.text('Отдых между подходами'), findsOneWidget);
    expect(find.text('2:00'), findsWidgets); // value + preset chip

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '1:30'));
    await tester.tap(find.widgetWithText(ChoiceChip, '1:30'));
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)));
    expect(container.read(appSettingsProvider).defaultRestSeconds, 90);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(container.read(appSettingsProvider).defaultRestSeconds, 105);
  });
}
