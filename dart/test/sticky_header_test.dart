import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

extension on WidgetTester {
  Future<String> sendMessage(String text, ChatBus bus) async {
    await enterText(find.byType(TextField), text);
    await tap(find.byIcon(Icons.send_rounded));
    await pump();
    return bus.exchanges.last.id;
  }
}

void main() {
  // ═══════════════════════════════════════════════════════
  //  Pinned Header — block header visual & behavior
  // ═══════════════════════════════════════════════════════

  group('Pinned Header', () {
    testWidgets('pinned header shows block header for active block', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);

      // Add thinking block
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', 'thinking...'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'thinking...'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // The pinned header should contain the 思考 label
      // (appears both in timeline and pinned header)
      expect(find.text('思考'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });

    testWidgets('pinned header block header uses bgPrimary color', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'ok'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // Find the 思考 text and verify its style matches the theme
      final thinkingLabels = find.text('思考');
      expect(thinkingLabels, findsAtLeastNWidgets(1));

      // Should use fluentDark headerThinking color
      final firstLabel = tester.widget<Text>(thinkingLabels.first);
      expect(firstLabel.style?.color, const Color(0xFFa0a0a0));
      expect(firstLabel.style?.fontSize, 12);
      expect(firstLabel.style?.fontWeight, FontWeight.w500);

      await ctrl.close();
    });

    testWidgets('pinned header 回答 block uses headerContent color', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ContentStarted(exId, 'ct1'));
      ctrl.add(ContentDelta(exId, 'ct1', 'reply'));
      ctrl.add(ContentCompleted(exId, 'ct1', 'reply'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final replyLabels = find.text('回答');
      expect(replyLabels, findsAtLeastNWidgets(1));

      final label = tester.widget<Text>(replyLabels.first);
      expect(label.style?.color, const Color(0xFF479ef5));

      await ctrl.close();
    });

    testWidgets('pinned header 工具 block uses headerTool color', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'read_file',
          {},
          requiresConfirm: false,
          autoApproved: true,
        ),
      );
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'file content'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final toolLabels = find.text('工具 · read_file');
      expect(toolLabels, findsAtLeastNWidgets(1));

      final label = tester.widget<Text>(toolLabels.first);
      expect(label.style?.color, const Color(0xFFa090d0));

      await ctrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Collapsed Blocks — skip in sticky header
  // ═══════════════════════════════════════════════════════

  group('Collapsed Blocks', () {
    testWidgets('collapsed block does not pin above expanded block', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);

      // Two blocks: thinking (collapsed by default) + tool (expanded = last)
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'thinking...'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'execute_command',
          {},
          requiresConfirm: false,
          autoApproved: true,
        ),
      );
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'done'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // Both blocks visible; only last block (tool) has sticky pinned header
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      expect(find.text('工具 · execute_command'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Theme Consistency — 共用样式验证
  // ═══════════════════════════════════════════════════════

  group('Theme Consistency', () {
    testWidgets('block header uses letterSpacing 0.24', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ContentStarted(exId, 'ct1'));
      ctrl.add(ContentCompleted(exId, 'ct1', 'reply'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final labels = find.text('回答');
      final label = tester.widget<Text>(labels.first);
      expect(label.style?.letterSpacing, 0.24);

      await ctrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  No Geometry Errors — 验证不抛出异常
  // ═══════════════════════════════════════════════════════

  group('No Geometry Errors', () {
    testWidgets('single block exchange does not throw', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('hello', bus);
      ctrl.add(ContentStarted(exId, 'c1'));
      ctrl.add(ContentDelta(exId, 'c1', 'Hello! How can I help you?'));
      ctrl.add(ContentCompleted(exId, 'c1', 'Hello! How can I help you?'));
      ctrl.add(ParallelBoundary(exId));

      // Should not throw any SliverGeometry errors
      await tester.pump();
      expect(find.text('回答'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });

    testWidgets('exchange with all three block types', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('analyze', bus);

      // thinking
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', 'analyzing...'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'analyzing...'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // tool
      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'grep_files',
          {},
          requiresConfirm: false,
          autoApproved: true,
        ),
      );
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'result'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // content
      ctrl.add(ContentStarted(exId, 'ct1'));
      ctrl.add(ContentDelta(exId, 'ct1', 'Analysis complete'));
      ctrl.add(ContentCompleted(exId, 'ct1', 'Analysis complete'));
      ctrl.add(ParallelBoundary(exId));

      // Should not throw — all blocks visible, only content has sticky pinned header
      await tester.pump();
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      expect(find.text('工具 · grep_files'), findsAtLeastNWidgets(1));
      expect(find.text('回答'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });

    testWidgets('multiple sequential exchanges', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // Exchange 1
      var exId = await tester.sendMessage('msg1', bus);
      ctrl.add(ContentStarted(exId, 'c1'));
      ctrl.add(ContentCompleted(exId, 'c1', 'reply1'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      await ctrl.close();

      // Exchange 2
      final ctrl2 = StreamController<ExchangeEvent>();
      bus.onGenerate = (_) => ctrl2.stream;
      exId = await tester.sendMessage('msg2', bus);
      ctrl2.add(ContentStarted(exId, 'c2'));
      ctrl2.add(ContentCompleted(exId, 'c2', 'reply2'));
      ctrl2.add(ParallelBoundary(exId));

      // Should not throw
      await tester.pump();
      expect(find.text('回答'), findsAtLeastNWidgets(1));
      expect(find.text('msg1'), findsAtLeastNWidgets(1));
      expect(find.text('msg2'), findsAtLeastNWidgets(1));

      await ctrl2.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Multi-Exchange Scroll — 验证多条消息下覆盖层头部正确追踪
  // ═══════════════════════════════════════════════════════

  group('Multi-Exchange Scroll', () {
    /// Long user message to ensure each exchange takes ~80px (viewPort ~480px,
    /// need enough content to scroll past the viewport).
    String msg(int i) =>
        '这是第 $i 条消息，用来产生足够的滚动高度以验证覆盖层固定头部在滚动多条消息时能正确追踪当前活跃的交换。';

    testWidgets('scrolling past 40 exchanges unpins first message', (
      tester,
    ) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      for (int i = 1; i <= 40; i++) {
        bus.sendMessage(msg(i));
      }
      await tester.pump();

      // Initially msg 1 appears in the sliver
      expect(find.text(msg(1)), findsOneWidget);

      // Jump past all exchanges
      final sv = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      sv.controller?.jumpTo(sv.controller!.position.maxScrollExtent);
      await tester.pump();
      expect(sv.controller!.offset, greaterThan(0.0));
    });

    testWidgets('scrolling back to top repins first message', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      for (int i = 1; i <= 40; i++) {
        bus.sendMessage(msg(i));
      }
      await tester.pump();

      // Jump to bottom then back to top
      final sv = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
      sv.controller?.jumpTo(sv.controller!.position.maxScrollExtent);
      await tester.pump();
      sv.controller?.jumpTo(0);
      await tester.pump();

      // msg 1 should be visible again
      expect(find.text(msg(1)), findsOneWidget);
    });
  });
}
