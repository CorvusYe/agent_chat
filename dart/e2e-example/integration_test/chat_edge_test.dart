import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: edge cases and special scenarios.
///
/// Tests:
///   - Empty conversation state (placeholder)
///   - Tool confirmation dialog: "允许" flow
///   - Tool confirmation dialog: "始终允许" flow
///   - Tool confirmation dialog: "取消" flow
///   - Queue popup show/hide
///   - Queue badge during streaming
///   - Error recovery — exchange fails gracefully
///   - Rapid multiple sends with varied message lengths
///   - Very long user message (200+ chars)
///   - English-only message flow
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chat — Edge Cases (边界场景)', () {
    // ─────────────────────────────────────────────────────
    //  1. Empty state
    // ─────────────────────────────────────────────────────
    testWidgets('空对话状态 — 提示文本', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());
      // NOTE: ChatScreen disposes the bus automatically

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // No exchanges yet → empty placeholder visible
      expectEmptyPlaceholder(tester);
      expect(bus.exchanges.isEmpty, isTrue);
    });

    // ─────────────────────────────────────────────────────
    //  2. Confirm "允许"
    // ─────────────────────────────────────────────────────
    testWidgets('工具确认弹窗 — "允许" 流程', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send message that triggers confirmation
      bus.sendMessage('确认执行数据库迁移');
      await tester.pump();
      await waitForIntermediateState(tester);

      // Confirm gate UI should be visible
      expect(find.text('允许'), findsOneWidget);
      expect(find.text('始终允许'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('将要执行以下操作'), findsOneWidget);

      // Tap "允许"
      await tester.tap(find.text('允许'));
      await tester.pump();
      await waitForAICompletion(tester);

      // Exchange should have completed
      expect(bus.exchanges.length, 1);
      expect(bus.exchanges.first.status, ExchangeStatus.completed);
      expectUserMessageVisible('确认执行数据库迁移');
    });

    // ─────────────────────────────────────────────────────
    //  3. Confirm "始终允许"
    // ─────────────────────────────────────────────────────
    testWidgets('工具确认弹窗 — "始终允许" 流程', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      bus.sendMessage('确认执行系统更新');
      await tester.pump();
      await waitForIntermediateState(tester);

      // Confirm gate visible
      expect(find.text('始终允许'), findsOneWidget);

      // Tap "始终允许"
      await tester.tap(find.text('始终允许'));
      await tester.pump();
      await waitForAICompletion(tester);

      // Exchange completed
      expect(bus.exchanges.length, 1);
      expect(bus.exchanges.first.status, ExchangeStatus.completed);
    });

    // ─────────────────────────────────────────────────────
    //  4. Confirm "取消"
    // ─────────────────────────────────────────────────────
    testWidgets('工具确认弹窗 — "取消" 流程', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      bus.sendMessage('确认执行危险操作');
      await tester.pump();
      await waitForIntermediateState(tester);

      // Confirm gate visible
      expect(find.text('取消'), findsOneWidget);

      // Tap "取消"
      await tester.tap(find.text('取消'));
      await tester.pump();
      await waitForAICompletion(tester);

      // Exchange exists
      expect(bus.exchanges.length, 1);
      expectUserMessageVisible('确认执行危险操作');
    });

    // ─────────────────────────────────────────────────────
    //  5. Queue popup
    // ─────────────────────────────────────────────────────
    testWidgets('队列弹窗 — 显示与关闭', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Enqueue messages
      bus.enqueueMessage('待发消息一');
      bus.enqueueMessage('待发消息二');
      await tester.pump();

      // Badge shows count
      expectQueueBadge(2);

      // Tap the send/queue button to open popup
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await waitForIntermediateState(tester);

      // Queue popup visible
      expect(find.text('待发送消息'), findsAtLeastNWidgets(1));
      expect(find.text('待发消息一'), findsOneWidget);
      expect(find.text('待发消息二'), findsOneWidget);

      // Close popup by tapping the close icon
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();
    });

    // ─────────────────────────────────────────────────────
    //  6. Error recovery
    // ─────────────────────────────────────────────────────
    testWidgets('错误消息 — exchange 优雅降级', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send a normal message first to verify baseline
      bus.sendMessage('正常消息');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 1);
      expect(bus.exchanges[0].status, ExchangeStatus.completed);

      // Send error-triggering message
      bus.sendMessage('生成一个错误的测试请求');
      await tester.pump();
      await waitForAICompletion(tester);

      // Exchange should be in failed state
      expect(bus.exchanges.length, 2);
      expect(bus.exchanges[1].status, ExchangeStatus.failed);
      // User message still visible
      expectUserMessageVisible('生成一个错误的测试请求');
    });

    // ─────────────────────────────────────────────────────
    //  7. Rapid sends — varied message lengths
    // ─────────────────────────────────────────────────────
    testWidgets('快速发送长短不一的消息', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send 4 messages of different lengths rapidly
      bus.sendMessage('短');
      await tester.pump(const Duration(milliseconds: 30));
      bus.sendMessage('中等长度消息');
      await tester.pump(const Duration(milliseconds: 30));
      bus.sendMessage('这是一条比较长的消息，用于测试多行文本的显示效果如何');
      await tester.pump(const Duration(milliseconds: 30));
      bus.sendMessage(
        '很长很长的消息：Flutter 是 Google 开源的 UI 工具包，'
        '用于从单一代码库为移动、Web、桌面和嵌入式平台构建原生编译应用。'
        '它使用 Dart 语言，具有热重载、丰富的组件库和高性能渲染引擎等特点。'
        '本测试验证超长消息在聊天界面中的显示效果。',
      );
      await tester.pump(const Duration(milliseconds: 30));

      // Wait for all to complete
      await waitForAICompletion(tester);

      // All 4 exchanges present
      expect(bus.exchanges.length, 4);
      // User messages visible
      expectUserMessageVisible('短');
      expectUserMessageVisible('中等长度消息');
    });

    // ─────────────────────────────────────────────────────
    //  8. Very long user message (200+ chars)
    // ─────────────────────────────────────────────────────
    testWidgets('超长用户消息', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Build a 200+ char message
      final longMessage = StringBuffer();
      longMessage.write('这是一个超长消息测试。');
      for (var i = 0; i < 20; i++) {
        longMessage.write('这是第${i + 1}句。重复内容测试长文本显示效果。');
      }
      final msg = longMessage.toString();

      bus.sendMessage(msg);
      await tester.pump();
      await waitForAICompletion(tester);

      // User message visible
      expectUserMessageVisible(msg);
      expect(bus.exchanges.length, 1);
    });

    // ─────────────────────────────────────────────────────
    //  9. English-only message flow
    // ─────────────────────────────────────────────────────
    testWidgets('英文消息流', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      await sendViaBus(tester, bus, 'Hello, how are you?');
      await waitForAICompletion(tester);
      expectUserMessageVisible('Hello, how are you?');

      await sendViaBus(tester, bus, 'What is the weather today?');
      await waitForAICompletion(tester);
      expectUserMessageVisible('What is the weather today?');

      // Both exchanges completed
      expect(bus.exchanges.length, 2);
      expect(bus.exchanges[0].status, ExchangeStatus.completed);
      expect(bus.exchanges[1].status, ExchangeStatus.completed);
    });

    // ─────────────────────────────────────────────────────
    //  10. Combined — history + confirm + error
    // ─────────────────────────────────────────────────────
    testWidgets('综合场景 — 历史+确认+错误', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // 1. Normal message (exchange 0)
      await sendViaBus(tester, bus, '第一个正常消息');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 1);

      // 2. Error message (exchange 1)
      bus.sendMessage('生成一个错误');
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 2);
      expect(bus.exchanges[1].status, ExchangeStatus.failed);

      // 3. Confirm + allow (exchange 2)
      bus.sendMessage('确认执行小工具');
      await tester.pump();
      await waitForIntermediateState(tester);
      expect(find.text('允许'), findsOneWidget);
      await tester.tap(find.text('允许'));
      await tester.pump();
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 3);

      // 4. Normal message (exchange 3)
      await sendViaBus(tester, bus, '综合测试结束');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 4);

      // Total states: 3 completed + 1 failed
      final completed = bus.exchanges
          .where((e) => e.status == ExchangeStatus.completed)
          .length;
      final failed = bus.exchanges
          .where((e) => e.status == ExchangeStatus.failed)
          .length;
      expect(completed, 3);
      expect(failed, 1);
    });
  });
}
