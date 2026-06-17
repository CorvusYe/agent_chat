import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agent_chat_example/features/feature_hub.dart';

void main() {
  testWidgets('Feature hub opens drawer and shows features', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: const FeatureHub()));
    await tester.pump();

    // AppBar shows first feature title
    expect(find.text('流输出展示'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Open drawer via menu icon. pumpAndSettle handles the animation.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Drawer header visible after animation completes
    expect(find.text('Agent Chat'), findsOneWidget);
    expect(find.text('特性展示'), findsOneWidget);

    // Feature ListTiles should be visible in the drawer
    expect(find.byType(ListTile), findsAtLeast(5));
  });
}
