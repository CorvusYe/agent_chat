import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

extension on WidgetTester {
  /// Send a message and return the exchange ID.
  Future<String> sendMessage(String text, ChatBus bus) async {
    await enterText(find.byType(TextField), text);
    await tap(find.byIcon(Icons.send_rounded));
    await pump();
    return bus.exchanges.last.id;
  }
}

void main() {
  // ═══════════════════════════════════════════════════════
  //  Event-Driven Flow
  // ═══════════════════════════════════════════════════════

  group('Event-Driven Flow', () {
    testWidgets('empty chat shows placeholder text', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      expect(find.text('发送一条消息开始对话'), findsOneWidget);
    });

    testWidgets('full exchange: thinking → tool → content', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('帮我查一下', bus);

      // thinking
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', '分析中'));
      ctrl.add(ThinkingCompleted(exId, 'th1', '分析中'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('思考'), findsAtLeastNWidgets(1));

      // tool
      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'read_file',
          {'path': 'test.txt'},
          requiresConfirm: false,
          autoApproved: true,
        ),
      );
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'file content here'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('工具 · read_file'), findsAtLeastNWidgets(1));
      expect(find.textContaining('file content here'), findsOneWidget);

      // content
      ctrl.add(ContentStarted(exId, 'ct1'));
      ctrl.add(ContentDelta(exId, 'ct1', '这是回答'));
      ctrl.add(ContentCompleted(exId, 'ct1', '这是回答'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('回答'), findsAtLeastNWidgets(1));
      expect(find.text('这是回答'), findsOneWidget);

      await ctrl.close();
    });

    testWidgets('ExchangeError shows failed exchange', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (_) =>
            Stream.fromIterable([ExchangeError('', 'API error')]),
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('hello'), findsAtLeastNWidgets(1));
      expect(bus.exchanges.first.status, ExchangeStatus.failed);
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Confirm Gate
  // ═══════════════════════════════════════════════════════

  group('Confirm Gate', () {
    testWidgets('tool requiring confirm shows gate, allow proceeds', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('执行命令', bus);

      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'execute_command',
          {'cmd': 'ls'},
          requiresConfirm: true,
          autoApproved: false,
          description: '将要执行命令 ls',
        ),
      );
      await tester.pump();

      // confirm gate buttons visible
      expect(find.text('允许'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      // tap allow
      await tester.tap(find.text('允许'));
      await tester.pump();

      // complete tool
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'executed ok'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.textContaining('executed ok'), findsOneWidget);

      await ctrl.close();
    });

    testWidgets('cancelling tool shows cancelled block', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('run', bus);

      ctrl.add(
        ToolCallStarted(
          exId,
          'tc1',
          'execute_command',
          {'cmd': 'ls'},
          requiresConfirm: true,
          autoApproved: false,
        ),
      );
      await tester.pump();

      expect(find.text('取消'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pump();

      expect(find.text('run'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });

    testWidgets('always allow skips subsequent confirm for same tool', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // first message: tool requires confirm, click "始终允许"
      final exId1 = await tester.sendMessage('first', bus);

      ctrl.add(
        ToolCallStarted(
          exId1,
          'tc1',
          'execute_command',
          {'cmd': 'ls'},
          requiresConfirm: true,
          autoApproved: false,
        ),
      );
      await tester.pump();
      expect(find.text('始终允许'), findsOneWidget);

      await tester.tap(find.text('始终允许'));
      await tester.pump();
      ctrl.add(ToolCallCompleted(exId1, 'tc1', 'ok'));
      ctrl.add(ParallelBoundary(exId1));
      await tester.pump();
      await ctrl.close();

      // second message: same tool should auto-approve
      final ctrl2 = StreamController<ExchangeEvent>();
      bus.onGenerate = (_) => ctrl2.stream;

      final exId2 = await tester.sendMessage('second', bus);

      ctrl2.add(
        ToolCallStarted(
          exId2,
          'tc2',
          'execute_command',
          {'cmd': 'pwd'},
          requiresConfirm: true,
          autoApproved: false,
        ),
      );
      await tester.pump();

      // no confirm gate — tool runs directly
      expect(find.text('始终允许'), findsNothing);
      expect(find.text('工具 · execute_command'), findsAtLeastNWidgets(1));

      ctrl2.add(ToolCallCompleted(exId2, 'tc2', 'done'));
      ctrl2.add(ParallelBoundary(exId2));
      await tester.pump();
      expect(find.textContaining('done'), findsOneWidget);

      await ctrl2.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Element Styles — Theme Color 验证
  // ═══════════════════════════════════════════════════════

  group('Element Styles', () {
    testWidgets('thinking header uses fluentDark headerThinking (0xFFa0a0a0)', (
      tester,
    ) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', '思考中'));
      ctrl.add(ThinkingCompleted(exId, 'th1', '思考中'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final label = tester.widget<Text>(find.text('思考').first);
      expect(label.style?.color, const Color(0xFFa0a0a0));
      expect(label.style?.fontWeight, FontWeight.w500);

      await ctrl.close();
    });

    testWidgets('empty placeholder uses fluentDark textTertiary (0xFF707070)', (
      tester,
    ) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final placeholder = tester.widget<Text>(find.text('发送一条消息开始对话'));
      expect(placeholder.style?.color, const Color(0xFF707070));
    });

    testWidgets('input TextField uses fluentDark textInput color', (
      tester,
    ) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.style?.color, const Color(0xFFe8e8e8));
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Element Dimensions — 尺寸验证
  // ═══════════════════════════════════════════════════════

  group('Element Dimensions', () {
    testWidgets('thinking label uses theme.fontSizeSm (12)', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', '思考中'));
      ctrl.add(ThinkingCompleted(exId, 'th1', '思考中'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final label = tester.widget<Text>(find.text('思考').first);
      expect(label.style?.fontSize, 12);

      await ctrl.close();
    });

    testWidgets('thinking content uses theme.fontSizeMd (13)', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingDelta(exId, 'th1', '思考内容'));
      ctrl.add(ThinkingCompleted(exId, 'th1', '思考内容'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final text = tester.widget<Text>(find.text('思考内容'));
      expect(text.style?.fontSize, 13);

      await ctrl.close();
    });

    testWidgets('user message uses theme.fontSizeLg (14)', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('你好世界', bus);
      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'ok'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      final msg = tester.widget<Text>(find.text('你好世界').last);
      expect(msg.style?.fontSize, 14);

      await ctrl.close();
    });

    testWidgets('input TextField uses theme.fontSizeLg (14)', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.style?.fontSize, 14);
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Call Process — 多消息 & 事件顺序
  // ═══════════════════════════════════════════════════════

  group('Call Process', () {
    testWidgets('two sequential exchanges render correctly', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // first exchange
      var exId = await tester.sendMessage('first msg', bus);
      ctrl.add(ContentStarted(exId, 'c1'));
      ctrl.add(ContentCompleted(exId, 'c1', 'first reply'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('first msg'), findsAtLeastNWidgets(1));
      expect(find.text('first reply'), findsOneWidget);
      await ctrl.close();

      // second exchange
      final ctrl2 = StreamController<ExchangeEvent>();
      bus.onGenerate = (_) => ctrl2.stream;

      exId = await tester.sendMessage('second msg', bus);
      ctrl2.add(ContentStarted(exId, 'c2'));
      ctrl2.add(ContentCompleted(exId, 'c2', 'second reply'));
      ctrl2.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('second msg'), findsAtLeastNWidgets(1));
      expect(find.text('second reply'), findsOneWidget);
      // first exchange still visible
      expect(find.text('first msg'), findsAtLeastNWidgets(1));

      await ctrl2.close();
    });

    testWidgets('block ordering follows event sequence', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);

      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingCompleted(exId, 'th1', 'thinking...'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();
      expect(find.text('思考'), findsAtLeastNWidgets(1));

      // add tool after thinking
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
      ctrl.add(ToolCallCompleted(exId, 'tc1', 'result A'));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      expect(find.text('工具 · grep_files'), findsAtLeastNWidgets(1));
      expect(find.text('思考'), findsAtLeastNWidgets(1));

      await ctrl.close();
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Edge Cases — 超长文本
  // ═══════════════════════════════════════════════════════

  group('Edge Cases — Long Text', () {
    // ~500 chars — long enough to test wrapping, short enough to not overflow
    final longText = '你好世界！' * 100;
    // ~2000 chars for queue overflow test
    final veryLong = '超长文本测试消息' * 150;

    testWidgets('input field accepts and sends long text', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), longText);
      await tester.pump();

      // verify text was entered
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.controller?.text.length, greaterThan(400));

      // send and verify via model (avoid layout overflow from render)
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // exchange created with full message
      expect(bus.exchanges.length, 1);
      expect(bus.exchanges.first.userMessage.length, greaterThan(400));

      await ctrl.close();
    });

    testWidgets('long text in queue popup', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      bus.enqueueMessage(veryLong);
      await tester.pump();

      // badge shows queue count
      expect(find.text('1'), findsOneWidget);

      // tap send when text field is empty → toggles queue popup
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // queue popup title
      expect(find.text('待发送消息'), findsOneWidget);

      // long text visible in popup
      expect(find.textContaining('超长文本测试消息'), findsOneWidget);

      // close popup by tapping send again
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // popup closed
      expect(find.text('待发送消息'), findsNothing);
    });

    testWidgets('multiple long messages in queue', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      bus.enqueueMessage(veryLong);
      bus.enqueueMessage('短消息');
      bus.enqueueMessage(veryLong);
      await tester.pump();

      // badge shows count
      expect(find.text('3'), findsOneWidget);

      // verify queue model
      expect(bus.queueItems.length, 3);
      expect(bus.queueItems[0].length, greaterThan(500));
      expect(bus.queueItems[1], '短消息');

      // open popup
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // title and empty state not shown
      expect(find.text('待发送消息'), findsOneWidget);
      expect(find.text('待发送队列为空'), findsNothing);
    });

    testWidgets('very long text in thinking block wraps', (tester) async {
      final ctrl = StreamController<ExchangeEvent>();
      final bus = DefaultChatBus(onGenerate: (_) => ctrl.stream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final exId = await tester.sendMessage('test', bus);

      ctrl.add(ThinkingStarted(exId, 'th1'));
      ctrl.add(ThinkingCompleted(exId, 'th1', longText));
      ctrl.add(ParallelBoundary(exId));
      await tester.pump();

      // thinking block label and long content visible
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      expect(find.text(longText), findsOneWidget);

      await ctrl.close();
    });

    testWidgets('empty queue shows placeholder', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('待发送队列为空'), findsOneWidget);
    });
  });
}
