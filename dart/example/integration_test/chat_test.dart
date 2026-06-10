import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agent_chat/agent_chat.dart';

/// How long to wait for mock AI to finish a full exchange (thinking + tools + content).
/// The mock AI takes ~1–4 seconds depending on random tool count and delays.
const _aiResponseTimeout = Duration(seconds: 15);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Agent Chat E2E', () {
    testWidgets('send a message and see user message appear', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // Enter text and send
      await tester.enterText(find.byType(TextField), '你好');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // User message visible
      expect(find.text('你好'), findsAtLeastNWidgets(1));
    });

    testWidgets('full AI exchange: thinking → tool → content',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ChatScreen(
          bus: DefaultChatBus(onGenerate: mockAI()),
        ),
      ));

      await tester.enterText(find.byType(TextField), '分析代码');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Wait for mock AI to complete
      await tester.runAsync(() => Future.delayed(_aiResponseTimeout));
      // Pump enough to complete AnimatedContainer (250ms) transition
      await tester.pump(const Duration(milliseconds: 300));

      // User message
      expect(find.text('分析代码'), findsAtLeastNWidgets(1));

      // All block headers visible — non-last blocks have inline headers
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      expect(find.text('回答'), findsAtLeastNWidgets(1));
    });

    testWidgets('enqueue message during active exchange', (tester) async {
      final bus = DefaultChatBus(onGenerate: mockAI());
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // Send first message
      await tester.enterText(find.byType(TextField), '第一轮');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // While streaming, enqueue a message via bus API
      bus.enqueueMessage('第二轮');
      await tester.pump();
      expect(bus.queueCount, 1);

      // Wait for first exchange to complete
      await tester.runAsync(() => Future.delayed(_aiResponseTimeout));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('第一轮'), findsAtLeastNWidgets(1));
    });

    testWidgets('queue popup shows queued messages', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // Enqueue messages directly via bus
      bus.enqueueMessage('待发消息1');
      bus.enqueueMessage('待发消息2');
      await tester.pump();

      // Badge shows count
      expect(find.text('2'), findsOneWidget);

      // Tap send to open queue popup
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Queue popup visible
      expect(find.text('待发送消息'), findsOneWidget);
      expect(find.textContaining('待发消息1'), findsOneWidget);
    });
  });
}

/// Factory for deterministic mock AI streams.
///
/// [requireConfirm] controls whether the tool call needs user confirmation.
/// [hasTool] can be set false to skip the tool block entirely.
/// [toolName] sets the tool name (default `grep_files`).
Stream<ExchangeEvent> Function(String) mockAI({
  bool requireConfirm = false,
  bool hasTool = true,
  String toolName = 'grep_files',
}) {
  return (String text) => _buildMockStream(
    requireConfirm: requireConfirm,
    hasTool: hasTool,
    toolName: toolName,
  );
}

/// Build a single deterministic mock exchange stream.
Stream<ExchangeEvent> _buildMockStream({
  required bool requireConfirm,
  required bool hasTool,
  required String toolName,
}) async* {
  final id = 'ex_int_${DateTime.now().millisecondsSinceEpoch}';

  yield ThinkingStarted(id, 'th1');
  const thinkText = '分析中……';
  for (var i = 0; i < thinkText.length; i += 2) {
    await Future.delayed(const Duration(milliseconds: 10));
    yield ThinkingDelta(id, 'th1',
        thinkText.substring(0, i + 2 > thinkText.length ? thinkText.length : i + 2));
  }
  yield ThinkingCompleted(id, 'th1', thinkText);
  yield ParallelBoundary(id);

  if (hasTool) {
    yield ToolCallStarted(id, 'tc1', toolName, {'pattern': 'TODO'},
        requiresConfirm: requireConfirm,
        autoApproved: !requireConfirm);
    await Future.delayed(const Duration(milliseconds: 100));
    yield ToolCallCompleted(id, 'tc1', 'src/main.dart:42');
    yield ParallelBoundary(id);
  }

  yield ContentStarted(id, 'ct1');
  const reply = '分析完成。发现一处 TODO。';
  for (var i = 0; i < reply.length; i += 2) {
    await Future.delayed(const Duration(milliseconds: 10));
    yield ContentDelta(id, 'ct1',
        reply.substring(0, i + 2 > reply.length ? reply.length : i + 2));
  }
  yield ContentCompleted(id, 'ct1', reply);
}
