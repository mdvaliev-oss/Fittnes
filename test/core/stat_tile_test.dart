import 'package:fittnes/core/theme/app_theme.dart';
import 'package:fittnes/core/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Center(child: child)),
      );

  group('StatTile', () {
    testWidgets('renders value, unit and label', (tester) async {
      await tester.pumpWidget(
        wrap(const StatTile(label: 'Тоннаж', value: '18.4', unit: 'т')),
      );

      expect(find.text('18.4'), findsOneWidget);
      expect(find.text('т'), findsOneWidget);
      expect(find.text('Тоннаж'), findsOneWidget);
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StatTile(
            label: 'Серия',
            value: '12',
            icon: Icons.local_fire_department_rounded,
          ),
        ),
      );

      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });
  });
}
