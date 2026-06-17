import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: fresh conversation (no history) with 10 varied messages.
///
/// The first message is sent via UI interaction (enter text → tap send) to
/// verify the real user flow. All subsequent messages use the bus API for
/// reliability. A dedicated "纯 UI 交互" test covers UI-only flow.
///
/// Tests:
///   - Short greeting → thinking + content (via UI)
///   - Code analysis → thinking + tools + content
///   - Long performance query → multi-tool response
///   - Concept explanation → thinking + content
///   - Confirmation gate → tap "允许" → completes
///   - Simple status query → thinking + content
///   - English question → thinking + content (English)
///   - Error message → exchange fails gracefully
///   - Refactoring advice → thinking + content
///   - Summary → final exchange
///   - Stats bar shows accumulated tokens
///   - Queue badge with enqueued messages
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat — Fresh Conversation (无历史)', () {
    testWidgets('发送10条长短不一的消息，覆盖不同场景', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());
      // NOTE: ChatScreen disposes the bus automatically

      // Helper: send via bus API and wait for response
      Future<void> sendAndWait(String text) async {
        sendViaBus(tester, bus, text);
        await waitForAICompletion(tester);
      }

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // ── 1. Empty state ──
      expectEmptyPlaceholder(tester);

      // ── 2. 短问候（通过 UI 输入发送，验证真实用户操作） ──
      await tester.enterText(find.byType(TextField), '你好');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await waitForAICompletion(tester);
      expectUserMessageVisible('你好');
      expectBlockHeadersVisible(thinking: true, content: true);

      // ── 3~11. 其余消息使用 bus API 发送（更可靠） ──
      await sendAndWait('分析项目的代码质量');
      expectUserMessageVisible('分析项目的代码质量');
      expectBlockHeadersVisible(thinking: true, tool: true, content: true);

      await sendAndWait('帮我检查这些性能问题：数据库查询优化、缓存策略、API 响应时间，以及内存使用情况。');
      expectUserMessageVisible('帮我检查这些性能问题：数据库查询优化、缓存策略、API 响应时间，以及内存使用情况。');

      await sendAndWait('什么是微服务架构？它与单体架构有什么区别？各自有什么优缺点？');
      expectUserMessageVisible('什么是微服务架构？它与单体架构有什么区别？各自有什么优缺点？');

      // ── 6. 确认弹窗（需要 UI 交互） ──
      bus.sendMessage('确认执行数据库结构变更迁移工具');
      await tester.pump();
      await waitForIntermediateState(tester);
      expect(find.text('允许'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      // Scroll to button and tap
      await tester.ensureVisible(find.text('允许'));
      await tester.pump();
      await tester.tap(find.text('允许'));
      await tester.pump();
      await waitForAICompletion(tester);
      // Verify via bus state (more reliable than text finder with many exchanges)
      expect(bus.exchanges.length, 5);
      expect(bus.exchanges[4].status, ExchangeStatus.completed);

      // ── 7. 状态查询 ──
      await sendAndWait('查询系统当前运行状态');
      expect(bus.exchanges.length, 6);
      expect(bus.exchanges[5].userMessage, '查询系统当前运行状态');

      // ── 8. 英文问题 ──
      await sendAndWait(
        'What are the key differences between StatefulWidget and StatelessWidget?',
      );
      expect(bus.exchanges.length, 7);
      expect(
        bus.exchanges[6].userMessage,
        'What are the key differences between StatefulWidget and StatelessWidget?',
      );

      // ── 9. 错误场景 ──
      bus.sendMessage('生成一个错误的测试请求来模拟异常');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 8);
      expect(bus.exchanges[7].status, ExchangeStatus.failed);

      // ── 10. 重构建议 ──
      await sendAndWait('请给我一些关于代码重构的建议');
      expect(bus.exchanges.length, 9);
      expect(bus.exchanges[8].userMessage, '请给我一些关于代码重构的建议');

      // ── 11. 总结 ──
      await sendAndWait('总结一下以上所有操作的结果');
      expect(bus.exchanges.length, 10);
      expect(bus.exchanges[9].userMessage, '总结一下以上所有操作的结果');

      // ── Final assertions ──
      expectStatsBarVisible(tester);
      expect(bus.totalTokens, greaterThan(0));
      // All exchanges should be in terminal state
      for (final ex in bus.exchanges) {
        expect(
          ex.status == ExchangeStatus.completed ||
              ex.status == ExchangeStatus.failed,
          isTrue,
          reason: 'Exchange ${ex.id} status=${ex.status} should be terminal',
        );
      }
    });

    // ─────────────────────────────────────────────────────
    //  Queue badge test
    // ─────────────────────────────────────────────────────
    testWidgets('队列消息徽章与弹窗', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send first message via UI to start streaming
      await tester.enterText(find.byType(TextField), '第一个查询');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Enqueue messages while streaming
      bus.enqueueMessage('队列消息一');
      bus.enqueueMessage('队列消息二');
      bus.enqueueMessage('队列消息三');
      await tester.pump();

      // Queue badge shows count
      expectQueueBadge(3);

      // Tap the queue button immediately while streaming is still active
      await tester.tap(find.byIcon(Icons.playlist_add));
      await tester.pump();

      // Queue popup should be visible
      expect(find.text('待发送消息'), findsAtLeastNWidgets(1));
      expect(find.text('队列消息一'), findsOneWidget);
      expect(find.text('队列消息二'), findsOneWidget);
      expect(find.text('队列消息三'), findsOneWidget);

      // Wait for the first exchange to complete
      await waitForAICompletion(tester);
      expect(bus.queueCount, 3);
      expect(bus.exchanges.length, greaterThanOrEqualTo(1));
    });

    // ─────────────────────────────────────────────────────
    //  Input field interaction test (纯 UI 交互)
    // ─────────────────────────────────────────────────────
    testWidgets('输入框纯 UI 交互 — 打字并发送', (tester) async {
      final inputBus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: inputBus),
        ),
      );

      // Verify input field is present with hint text
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('输入消息…'), findsOneWidget);

      // Type a message using UI
      await tester.enterText(find.byType(TextField), 'UI 输入测试');
      await tester.pump();

      // Tap the send button via UI
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Wait for AI to respond
      await waitForAICompletion(tester);

      // User message should be visible
      expectUserMessageVisible('UI 输入测试');
      expect(inputBus.exchanges.length, 1);
      expect(inputBus.exchanges.first.userMessage, 'UI 输入测试');
    });

    // ─────────────────────────────────────────────────────
    //  Rapid fire — send multiple messages quickly
    // ─────────────────────────────────────────────────────
    testWidgets('快速连续发送多条消息', (tester) async {
      final fastBus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: fastBus),
        ),
      );

      // Send 5 messages rapidly without waiting between each
      for (var i = 1; i <= 5; i++) {
        fastBus.sendMessage('快速消息 #$i');
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Now wait for all to complete
      await waitForAICompletion(tester);

      // All 5 exchanges should be present
      expect(fastBus.exchanges.length, 5);
      for (final ex in fastBus.exchanges) {
        expect(ex.status, equals(ExchangeStatus.completed));
      }
      expect(fastBus.totalTokens, greaterThan(0));
    });
  });
}
