import 'package:fittnes/core/widgets/pressable_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('scales down while pressed and fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: PressableScale(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 40, child: Text('go')),
          ),
        ),
      ),
    );

    AnimatedScale scaleOf() =>
        tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scaleOf().scale, 1);

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('go')));
    await tester.pump();
    expect(scaleOf().scale, 0.96);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf().scale, 1);
    expect(taps, 1);
  });

  testWidgets('renders the plain child when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PressableScale(enabled: false, child: Text('static')),
      ),
    );
    expect(find.byType(AnimatedScale), findsNothing);
    expect(find.text('static'), findsOneWidget);
  });

  testWidgets('honours reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PressableScale(onTap: () {}, child: const Text('calm')),
        ),
      ),
    );
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('calm')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
  });
}
