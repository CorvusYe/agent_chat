import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: verify the error banner renders on screen
/// when an exchange fails.
///
/// Run (Windows):
///   cd dart/example
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/chat_error_banner_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat — Error Banner', () {
    testWidgets('failed exchange shows error banner with icon and message',
        (tester) async {
      // Use a fixed-config mock AI that always produces an error.
      // This avoids relying on text-based routing (configForText).
      final bus = DefaultChatBus(
        onGenerate: createFixedMockAI(
          const MockConfig(hasError: true),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send any message — the mock AI will always error
      await tester.enterText(find.byType(TextField), '这条消息会触发错误');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Wait for the mock AI to finish (almost instant for error case)
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify exchange is in failed state
      expect(bus.exchanges.length, 1);
      expect(bus.exchanges.first.status, ExchangeStatus.failed);
      expect(bus.exchanges.first.errorMessage, '模拟错误：处理失败');

      // ── Verify the error banner UI elements ──
      // 1. "错误" header label (matches block header style)
      expect(find.text('错误'), findsOneWidget);

      // 2. Error icon
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // 3. Error message text (from MockConfig / mock_utils)
      expect(find.text('模拟错误：处理失败'), findsOneWidget);

      // 4. User message still visible
      expect(find.text('这条消息会触发错误'), findsAtLeastNWidgets(1));
    });
  });
}
