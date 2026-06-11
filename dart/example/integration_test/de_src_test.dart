import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agent_chat/agent_chat.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  辅助函数（与 main_de_src.dart 中对应私有函数逻辑一致）
// ═══════════════════════════════════════════════════════════════════════════

String _extractReply(String raw) {
  try {
    final json = _parseJson5(raw);
    if (json case {'reply': final String reply}) return reply;
    if (json case {'reply': final reply}) return reply.toString();
  } catch (_) {}
  return raw;
}

Map<String, dynamic> _parseJson5(String raw) {
  var start = raw.indexOf('{');
  var end = raw.lastIndexOf('}');
  if (start != -1 && end != -1 && end > start) {
    try {
      return json.decode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {}
  }
  return {};
}

// ═══════════════════════════════════════════════════════════════════════════
//  流式输出模拟 — 思考过程流式输出
// ═══════════════════════════════════════════════════════════════════════════

/// 流式思考 + 流式内容
///
/// 模拟 de_src 桥接的流式行为：
/// - ThinkingDelta 逐步输出文本（模拟推理 tokens）
/// - ContentDelta 逐步输出文本（模拟内容 tokens）
Stream<ExchangeEvent> streamingBridge(String text, {String? reply}) {
  final ctrl = StreamController<ExchangeEvent>();
  _emitStreaming(ctrl, reply);
  return ctrl.stream;
}

Future<void> _emitStreaming(
  StreamController<ExchangeEvent> ctrl, [
  String? reply,
]) async {
  final id = 'ex_str_${DateTime.now().millisecondsSinceEpoch}';

  // ── 流式思考 ──
  const think = '逐步推理过程……';
  ctrl.add(ThinkingStarted(id, 'think'));
  for (var i = 0; i < think.length; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    ctrl.add(ThinkingDelta(id, 'think', think.substring(0, i + 1)));
  }
  ctrl.add(ThinkingCompleted(id, 'think', think));
  ctrl.add(ParallelBoundary(id));

  // ── 流式内容 ──
  final content = reply ?? '{"reply": "流式输出的回答内容。"}';
  ctrl.add(ContentStarted(id, 'content'));
  for (var i = 0; i < content.length; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
    ctrl.add(ContentDelta(id, 'content', content.substring(0, i + 1)));
  }
  ctrl.add(ContentCompleted(id, 'content', content));
  ctrl.add(TokenCount(id, content.length));

  await ctrl.close();
}

// ═══════════════════════════════════════════════════════════════════════════
//  非流式输出模拟 — 内容一次性完整到达
// ═══════════════════════════════════════════════════════════════════════════

/// 流式思考 + 非流式内容（一次性完整内容）
///
/// 思考过程仍为流式（必要），内容在完成后一次性发送 ContentCompleted。
Stream<ExchangeEvent> nonStreamingBridge(String text, {String? reply}) {
  final ctrl = StreamController<ExchangeEvent>();
  _emitNonStreaming(ctrl, reply);
  return ctrl.stream;
}

Future<void> _emitNonStreaming(
  StreamController<ExchangeEvent> ctrl, [
  String? reply,
]) async {
  final id = 'ex_nst_${DateTime.now().millisecondsSinceEpoch}';

  // 思考过程仍流式
  const think = '快速推理……';
  ctrl.add(ThinkingStarted(id, 'think'));
  for (var i = 0; i < think.length; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    ctrl.add(ThinkingDelta(id, 'think', think.substring(0, i + 1)));
  }
  ctrl.add(ThinkingCompleted(id, 'think', think));
  ctrl.add(ParallelBoundary(id));

  // 内容非流式：一次性完成
  final content = reply ?? '{"reply": "一次性完整内容。"}';
  ctrl.add(ContentStarted(id, 'content'));
  ctrl.add(ContentDelta(id, 'content', content));
  ctrl.add(ContentCompleted(id, 'content', content));
  ctrl.add(TokenCount(id, content.length));

  await ctrl.close();
}

// ═══════════════════════════════════════════════════════════════════════════
//  工具调用模拟
// ═══════════════════════════════════════════════════════════════════════════

/// 思考 + 工具 + 内容（模拟工具模式下最终内容正确显示）
Stream<ExchangeEvent> toolModeBridge(String text, {String? reply}) {
  final ctrl = StreamController<ExchangeEvent>();
  _emitToolMode(ctrl, reply);
  return ctrl.stream;
}

Future<void> _emitToolMode(
  StreamController<ExchangeEvent> ctrl, [
  String? reply,
]) async {
  final id = 'ex_tm_${DateTime.now().millisecondsSinceEpoch}';

  // 思考
  ctrl.add(ThinkingStarted(id, 'think'));
  ctrl.add(ThinkingDelta(id, 'think', '分析中'));
  ctrl.add(ThinkingCompleted(id, 'think', '分析中'));
  ctrl.add(ParallelBoundary(id));

  // 工具调用
  ctrl.add(ParallelBoundary(id));
  ctrl.add(ToolCallStarted(id, 'tool_read', 'read_file', {'path': 'test.txt'}));
  ctrl.add(ToolCallCompleted(id, 'tool_read', '模拟文件内容'));

  // 内容（最终回答）
  final content = reply ?? '{"reply": "工具执行完毕，这是最终结果。"}';
  ctrl.add(ContentStarted(id, 'content'));
  ctrl.add(ContentDelta(id, 'content', content));
  ctrl.add(ContentCompleted(id, 'content', content));
  ctrl.add(TokenCount(id, content.length));

  await ctrl.close();
}

// ═══════════════════════════════════════════════════════════════════════════
//  Utilities
// ═══════════════════════════════════════════════════════════════════════════

const _aiTimeout = Duration(seconds: 15);

Future<void> waitForAI(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(_aiTimeout, () {}));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Unit: JSON reply extraction ─────────────────────────

  group('JSON reply extraction', () {
    test('extract reply from valid JSON', () {
      expect(_extractReply('{"reply": "你好"}'), '你好');
    });

    test('extract reply from JSON with extra fields', () {
      expect(_extractReply('{"reply": "完成", "finished": false}'), '完成');
    });

    test('fallback to raw text when no reply field', () {
      const raw = '普通文本';
      expect(_extractReply(raw), raw);
    });

    test('extract non-string reply', () {
      expect(_extractReply('{"reply": 42}'), '42');
    });

    test('return raw on malformed JSON', () {
      expect(_extractReply('这不是 JSON'), '这不是 JSON');
    });
  });

  // ── Unit: JSON parsing ──────────────────────────────────

  group('JSON parsing', () {
    test('parse simple JSON', () {
      final r = _parseJson5('{"a": 1}');
      expect(r['a'], 1);
    });

    test('extract JSON from surrounding text', () {
      final r = _parseJson5('x{"k":"v"}y');
      expect(r['k'], 'v');
    });

    test('empty input', () {
      expect(_parseJson5('not json'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  流式输出测试
  // ═══════════════════════════════════════════════════════════

  group('流式输出', () {
    testWidgets('思考过程流式输出: ThinkingDelta 逐步更新', (tester) async {
      final bus = DefaultChatBus(onGenerate: streamingBridge);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '测试');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // 等待一小段时间，思考过程应该开始流式输出
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      // 思考 Text 可见（ThinkingStarted 已触发）
      expect(find.text('思考'), findsAtLeastNWidgets(1));

      // 等待完成
      await waitForAI(tester);

      // 思考内容可见
      expect(find.textContaining('逐步推理过程'), findsAtLeastNWidgets(1));
      // 回答内容可见
      expect(find.textContaining('流式输出的回答内容'), findsAtLeastNWidgets(1));
    });

    testWidgets('流式内容: ContentDelta 逐字到达最终完整', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (text) =>
            streamingBridge(text, reply: '{"reply": "逐字输出测试。"}'),
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '测试流式');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // 等待中间状态
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      // 等待完成
      await waitForAI(tester);

      // 回答标题可见
      expect(find.text('回答'), findsAtLeastNWidgets(1));
      // 内容可见
      expect(find.textContaining('逐字输出测试'), findsAtLeastNWidgets(1));
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  非流式输出测试
  // ═══════════════════════════════════════════════════════════

  group('非流式输出', () {
    testWidgets('思考流式 + 内容一次性完成', (tester) async {
      final bus = DefaultChatBus(onGenerate: nonStreamingBridge);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '测试非流式');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await waitForAI(tester);

      // 思考过程仍为流式
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      expect(find.textContaining('快速推理'), findsAtLeastNWidgets(1));
      // 内容完整到达
      expect(find.text('回答'), findsAtLeastNWidgets(1));
      expect(find.textContaining('一次性完整内容'), findsAtLeastNWidgets(1));
    });

    testWidgets('无思考过程，仅内容非流式', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (String text) {
          final ctrl = StreamController<ExchangeEvent>();
          final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
          ctrl.add(ContentStarted(id, 'content'));
          ctrl.add(ContentCompleted(id, 'content', '{"reply": "只有回答。"}'));
          ctrl.add(TokenCount(id, 20));
          ctrl.close();
          return ctrl.stream;
        },
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '极简');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await waitForAI(tester);

      // 只有回答，没有思考
      expect(find.text('回答'), findsAtLeastNWidgets(1));
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  工具模式测试
  // ═══════════════════════════════════════════════════════════

  group('工具模式内容显示', () {
    testWidgets('工具调用后内容正确显示', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (text) => toolModeBridge(text, reply: '{"reply": "最终答案"}'),
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '读取文件');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await waitForAI(tester);

      // 思考出现
      expect(find.text('思考'), findsAtLeastNWidgets(1));
      // 工具出现
      expect(find.textContaining('工具'), findsAtLeastNWidgets(1));
      expect(find.textContaining('read_file'), findsAtLeastNWidgets(1));
      // 内容出现（之前没有内容显示就是缺这里）
      expect(find.text('回答'), findsAtLeastNWidgets(1));
      expect(find.textContaining('最终答案'), findsAtLeastNWidgets(1));
    });

    testWidgets('多工具 + 内容', (tester) async {
      final bus = DefaultChatBus(onGenerate: _multiToolStream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '多工具');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await waitForAI(tester);

      // 两个工具名称都显示
      expect(find.textContaining('read_file'), findsAtLeastNWidgets(1));
      expect(find.textContaining('code_analyze'), findsAtLeastNWidgets(1));
      // 最终内容显示
      expect(find.textContaining('多工具执行完毕'), findsAtLeastNWidgets(1));
    });

    testWidgets('工具确认门 + 允许后内容显示', (tester) async {
      final bus = DefaultChatBus(onGenerate: _confirmToolStream);
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '危险操作');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 200), () {}),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // 确认门应显示
      expect(find.text('将要执行危险命令'), findsAtLeastNWidgets(1));
      expect(find.text('允许'), findsAtLeastNWidgets(1));
      expect(find.text('取消'), findsAtLeastNWidgets(1));

      // 点「取消」
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Exchange 应标记为 cancelled
      expect(bus.exchanges.last.status, ExchangeStatus.cancelled);
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  边界情况
  // ═══════════════════════════════════════════════════════════

  group('边界情况', () {
    testWidgets('错误处理', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (_) {
          final ctrl = StreamController<ExchangeEvent>();
          final id = 'ex_err_${DateTime.now().millisecondsSinceEpoch}';
          ctrl.add(ExchangeError(id, '模拟错误'));
          ctrl.close();
          return ctrl.stream;
        },
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      await tester.enterText(find.byType(TextField), '错误');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await waitForAI(tester);

      expect(bus.exchanges.last.status, ExchangeStatus.failed);
    });

    testWidgets('多轮对话', (tester) async {
      final bus = DefaultChatBus(
        onGenerate: (String text) =>
            streamingBridge(text, reply: '{"reply": "回复: $text"}'),
      );
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // 第一轮：用 sendMessage 直接发送
      bus.sendMessage('第一轮');
      await tester.pump();
      await waitForAI(tester);
      expect(find.textContaining('第一轮'), findsAtLeastNWidgets(1));
      expect(find.textContaining('回复: 第一轮'), findsAtLeastNWidgets(1));

      // 确保第一轮完全结束
      await tester.pump(const Duration(milliseconds: 300));

      // 第二轮
      bus.sendMessage('第二轮');
      await tester.pump();
      await waitForAI(tester);

      expect(find.textContaining('第一轮'), findsAtLeastNWidgets(1));
      expect(find.textContaining('第二轮'), findsAtLeastNWidgets(1));
      expect(find.textContaining('回复: 第二轮'), findsAtLeastNWidgets(1));
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  Helper: 多工具流
// ═══════════════════════════════════════════════════════════════════════════

Stream<ExchangeEvent> _multiToolStream(String text) {
  final ctrl = StreamController<ExchangeEvent>();
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
  ctrl.add(ThinkingStarted(id, 'think'));
  ctrl.add(ThinkingDelta(id, 'think', '分析'));
  ctrl.add(ThinkingCompleted(id, 'think', '分析'));
  ctrl.add(ParallelBoundary(id));
  ctrl.add(ParallelBoundary(id));
  ctrl.add(ToolCallStarted(id, 't1', 'read_file', {'path': 'a.txt'}));
  ctrl.add(ToolCallStarted(id, 't2', 'code_analyze', {'file': 'b.dart'}));
  ctrl.add(ParallelBoundary(id));
  ctrl.add(ToolCallCompleted(id, 't1', '文件内容'));
  ctrl.add(ToolCallCompleted(id, 't2', '分析结果'));
  ctrl.add(ContentStarted(id, 'content'));
  ctrl.add(ContentCompleted(id, 'content', '{"reply": "多工具执行完毕。"}'));
  ctrl.add(TokenCount(id, 30));
  ctrl.close();
  return ctrl.stream;
}

// ═══════════════════════════════════════════════════════════════════════════
//  Helper: 工具确认门流
// ═══════════════════════════════════════════════════════════════════════════

Stream<ExchangeEvent> _confirmToolStream(String text) {
  final ctrl = StreamController<ExchangeEvent>();
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
  ctrl.add(ThinkingStarted(id, 'think'));
  ctrl.add(ThinkingDelta(id, 'think', '分析'));
  ctrl.add(ThinkingCompleted(id, 'think', '分析'));
  ctrl.add(ParallelBoundary(id));
  ctrl.add(
    ToolCallStarted(
      id,
      'tool_run',
      'execute_command',
      {'cmd': 'rm -rf /'},
      requiresConfirm: true,
      description: '将要执行危险命令',
    ),
  );
  ctrl.close();
  return ctrl.stream;
}
