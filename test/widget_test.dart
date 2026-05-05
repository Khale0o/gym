import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('isolated smoke test renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Gym SaaS smoke test'),
        ),
      ),
    );

    expect(find.text('Gym SaaS smoke test'), findsOneWidget);
  });
}
