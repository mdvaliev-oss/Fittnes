import 'package:fittnes/core/settings/app_settings.dart';
import 'package:fittnes/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/pump_app.dart';

void main() {
  testWidgets('edits the goal and reflects it in the header', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
}
