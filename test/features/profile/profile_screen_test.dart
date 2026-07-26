import 'package:fittnes/features/profile/presentation/profile_screen.dart';
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
}
