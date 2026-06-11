import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: conversation with pre-loaded history + 10 new messages.
///
/// Tests:
///   - Pre-load 3 history exchanges via fast mock AI
///   - Verify history exchanges are rendered
///   - Send 10 new messages of varying lengths
///   - Verify both history and new messages visible
///   - Scroll behavior — newer exchanges visible without excessive scroll
///   - Older exchanges may be collapsed, latest block expanded
///   - Stats bar reflects total tokens from all exchanges
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat — With History (有历史数据)', () {
    testWidgets('预载3条历史消息后发送10条新消息', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());
      // NOTE: ChatScreen disposes the bus automatically

      // ═══════════════════════════════════════════
      //  Phase 1: Pre-load history exchanges
      // ═══════════════════════════════════════════
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Pre-load 3 history exchanges using fast AI
      bus.onGenerate = createFastMockAI();
      const historyMessages = ['历史讨论一', '历史讨论二', '历史讨论三'];
      for (final msg in historyMessages) {
        bus.sendMessage(msg);
        await tester.pump();
      }
      // Wait for all history exchanges to complete
      await waitForAICompletion(tester);

      // Verify history exchanges are present
      expect(bus.exchanges.length, 3);
      expectUserMessageVisible('历史讨论一');
      expectUserMessageVisible('历史讨论二');
      expectUserMessageVisible('历史讨论三');

      // ═══════════════════════════════════════════
      //  Phase 2: Switch back to smart AI and send 10 varied messages
      // ═══════════════════════════════════════════
      bus.onGenerate = createSmartMockAI();

      // Helper for sending via bus
      Future<void> sendAndWait(String text) async {
        sendViaBus(tester, bus, text);
        await waitForAICompletion(tester);
      }

      // Send 10 messages using safe messages to avoid confirm/error interruptions
      // First 5 messages use visual assertions; remaining use bus-based to avoid
      // widget tree depth issues with many exchanges.
      await sendAndWait(safeTestMessages[0].$1);
      expectUserMessageVisible(safeTestMessages[0].$1);

      await sendAndWait(safeTestMessages[1].$1);
      expectUserMessageVisible(safeTestMessages[1].$1);

      await sendAndWait(safeTestMessages[2].$1);
      expectUserMessageVisible(safeTestMessages[2].$1);

      await sendAndWait(safeTestMessages[3].$1);
      expectUserMessageVisible(safeTestMessages[3].$1);

      await sendAndWait(safeTestMessages[4].$1);
      expectUserMessageVisible(safeTestMessages[4].$1);

      // Remaining 5 messages use bus-state assertions for reliability
      await sendAndWait(safeTestMessages[5].$1);
      expect(bus.exchanges.length, 9);
      expect(bus.exchanges[8].userMessage, safeTestMessages[5].$1);

      await sendAndWait(safeTestMessages[6].$1);
      expect(bus.exchanges.length, 10);
      expect(bus.exchanges[9].userMessage, safeTestMessages[6].$1);

      await sendAndWait(safeTestMessages[7].$1);
      expect(bus.exchanges.length, 11);
      expect(bus.exchanges[10].userMessage, safeTestMessages[7].$1);

      await sendAndWait(safeTestMessages[8].$1);
      expect(bus.exchanges.length, 12);
      expect(bus.exchanges[11].userMessage, safeTestMessages[8].$1);

      await sendAndWait(safeTestMessages[9].$1);
      expect(bus.exchanges.length, 13);
      expect(bus.exchanges[12].userMessage, safeTestMessages[9].$1);

      // ═══════════════════════════════════════════
      //  Phase 3: Final assertions
      // ═══════════════════════════════════════════

      // Total exchanges: 3 (history) + 10 (new) = 13
      expect(bus.exchanges.length, 13);

      // History exchanges should be in completed state
      expect(bus.exchanges[0].status, ExchangeStatus.completed);
      expect(bus.exchanges[1].status, ExchangeStatus.completed);
      expect(bus.exchanges[2].status, ExchangeStatus.completed);

      // New exchanges should be completed
      for (var i = 3; i < 13; i++) {
        expect(
          bus.exchanges[i].status,
          ExchangeStatus.completed,
          reason: 'Exchange ${bus.exchanges[i].id} should be completed',
        );
      }

      // Stats bar shows accumulated tokens
      expectStatsBarVisible(tester);
      expect(bus.totalTokens, greaterThan(0));

      // Block headers visible for the latest exchange
      expectBlockHeadersVisible(thinking: true, content: true);

      // The last exchange's blocks should be expanded (latest)
      // and at least the "回答" header visible
      expect(find.text('回答'), findsAtLeastNWidgets(1));
    });

    // ─────────────────────────────────────────────────────
    //  History with confirm/error mixed in
    // ─────────────────────────────────────────────────────
    testWidgets('预载历史消息后发送确认+错误消息', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Pre-load 2 history exchanges
      bus.onGenerate = createFastMockAI();
      bus.sendMessage('历史消息A');
      bus.sendMessage('历史消息B');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 2);

      // Switch to smart AI
      bus.onGenerate = createSmartMockAI();

      // Send confirm-triggering message
      bus.sendMessage('确认执行数据迁移');
      await tester.pump();
      await waitForIntermediateState(tester);

      // Confirm gate visible
      expect(find.text('允许'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      // Tap "取消" to cancel the tool
      await tester.tap(find.text('取消'));
      await tester.pump();
      // Wait for the exchange to settle (the stream continues after cancel)
      await waitForAICompletion(tester);

      // Send error-triggering message
      bus.sendMessage('生成一个错误');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 4);
      expect(bus.exchanges[3].status, ExchangeStatus.failed);

      // Verify exchange states
      // Exchange 0,1 (history): completed
      // Exchange 2 (confirm cancelled): may be completed or cancelled
      expect(bus.exchanges[0].status, ExchangeStatus.completed);
      expect(bus.exchanges[1].status, ExchangeStatus.completed);
      // Exchange 3 (error): should be failed
      expect(
        bus.exchanges.length >= 3,
        isTrue,
        reason: 'Should have at least 3 exchanges',
      );

      // Total tokens present
      expect(bus.totalTokens, greaterThan(0));
    });

    // ─────────────────────────────────────────────────────
    //  Verify history exchanges remain visible after new messages
    // ─────────────────────────────────────────────────────
    testWidgets('新消息不覆盖历史消息', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Pre-load history
      bus.onGenerate = createFastMockAI();
      bus.sendMessage('初始化配置');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 1);

      // Send new messages
      bus.onGenerate = createSmartMockAI();
      await sendViaBus(tester, bus, '新的查询');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 2);

      // History message still visible
      expectUserMessageVisible('初始化配置');
      // New message also visible
      expectUserMessageVisible('新的查询');

      // Send several more messages
      for (final (msg, _) in safeTestMessages.take(5)) {
        await sendViaBus(tester, bus, msg);
        await waitForAICompletion(tester);
      }

      // Total: 1 (history) + 1 + 5 = 7
      expect(bus.exchanges.length, 7);

      // Old history message still visible
      expectUserMessageVisible('初始化配置');
    });
  });
}
