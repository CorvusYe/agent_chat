import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: visual themes rendering.
///
/// Verifies that different [ChatTheme] values render correctly:
///   - Fluent Dark theme (default)
///   - Default Dark theme (original purple)
///   - Fluent Light theme
///
/// Each theme test sends 3-4 messages and verifies:
///   - Messages render correctly
///   - Block headers visible (思考 / 回答 / 工具)
///   - Exchange completes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat — Visual Themes (视觉主题)', () {
    Future<void> sendTestMessages(
      WidgetTester tester,
      DefaultChatBus bus,
    ) async {
      // Send 4 safe messages
      for (final (msg, _) in safeTestMessages.take(4)) {
        await sendViaBus(tester, bus, msg);
        await waitForAICompletion(tester);
      }
    }

    // ─────────────────────────────────────────────────────
    //  Fluent Dark (default theme in ChatScreen)
    // ─────────────────────────────────────────────────────
    testWidgets('Fluent Dark 主题 — 默认', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());
      // NOTE: ChatScreen disposes the bus automatically

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus, theme: ChatThemes.fluentDark),
        ),
      );

      // Empty state
      expectEmptyPlaceholder(tester);

      // Send messages
      await sendTestMessages(tester, bus);

      // 4 exchanges completed
      expect(bus.exchanges.length, 4);
      // User messages visible
      expectUserMessageVisible(safeTestMessages[0].$1);
      expectUserMessageVisible(safeTestMessages[3].$1);
      // Block headers
      expectBlockHeadersVisible(thinking: true, content: true);
      // Stats bar
      expectStatsBarVisible(tester);
    });

    // ─────────────────────────────────────────────────────
    //  Default Dark (original purple theme)
    // ─────────────────────────────────────────────────────
    testWidgets('Default Dark 主题 — 紫色', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus, theme: ChatThemes.dark),
        ),
      );

      // Empty state
      expectEmptyPlaceholder(tester);

      // Send messages
      await sendTestMessages(tester, bus);

      expect(bus.exchanges.length, 4);
      expectUserMessageVisible(safeTestMessages[0].$1);
      expectUserMessageVisible(safeTestMessages[2].$1);
      expectStatsBarVisible(tester);
    });

    // ─────────────────────────────────────────────────────
    //  Fluent Light
    // ─────────────────────────────────────────────────────
    testWidgets('Fluent Light 主题', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.light),
          home: ChatScreen(bus: bus, theme: ChatThemes.fluent),
        ),
      );

      // Empty state
      expectEmptyPlaceholder(tester);

      // Send messages
      await sendTestMessages(tester, bus);

      expect(bus.exchanges.length, 4);
      expectUserMessageVisible(safeTestMessages[0].$1);
      expectStatsBarVisible(tester);
    });

    // ─────────────────────────────────────────────────────
    //  No theme override — uses ChatScreen default (fluentDark)
    // ─────────────────────────────────────────────────────
    testWidgets('无主题覆盖 — 使用默认主题', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus), // no theme param → ChatThemes.fluentDark
        ),
      );

      expectEmptyPlaceholder(tester);

      await sendTestMessages(tester, bus);
      expect(bus.exchanges.length, 4);
      expectUserMessageVisible(safeTestMessages[0].$1);
      expectStatsBarVisible(tester);
    });
  });
}
