import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agent_chat_e2e_example/main.dart';

void main() {
  testWidgets('Mock AI Chat smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the chat screen is rendered
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
