import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

// ═══════════════════════════════════════════════════════
//  Constants
// ═══════════════════════════════════════════════════════

/// Maximum time to wait for a mock AI exchange to complete entirely.
const aiCompletionTimeout = Duration(seconds: 10);

/// How long a thinking / content chunk delay in mock AI streams.
const _chunkDelay = Duration(milliseconds: 5);

// ═══════════════════════════════════════════════════════
//  MockConfig — controls per-exchange mock AI behavior
// ═══════════════════════════════════════════════════════

class MockConfig {
  final bool hasThinking;
  final bool hasTool;
  final bool requireConfirm;
  final bool autoApproved;
  final bool hasError;
  final int toolCount;
  final String thinkText;
  final String replyText;
  final String toolName;
  final String toolResult;

  const MockConfig({
    this.hasThinking = true,
    this.hasTool = false,
    this.requireConfirm = false,
    this.autoApproved = false,
    this.hasError = false,
    this.toolCount = 1,
    this.thinkText = '分析中……',
    this.replyText = '处理完成。',
    this.toolName = 'analyze',
    this.toolResult = '✓ 完成',
  });
}

// ═══════════════════════════════════════════════════════
//  Text routing — determine MockConfig from user message
// ═══════════════════════════════════════════════════════

MockConfig configForText(String text) {
  // Error trigger
  if (text.contains('错误') || text.contains('error') || text.contains('失败')) {
    return const MockConfig(hasError: true);
  }

  // Tool confirmation trigger
  if (text.contains('确认') && text.contains('执行')) {
    return MockConfig(
      hasThinking: true,
      hasTool: true,
      requireConfirm: true,
      toolName: 'execute_command',
      replyText: '操作需要您的确认。请审核后允许或取消。',
      toolResult: '等待用户确认…',
    );
  }

  // Code / performance analysis — triggers multiple tools
  if (text.contains('代码') || text.contains('性能') || text.contains('analysis')) {
    return const MockConfig(
      hasThinking: true,
      hasTool: true,
      toolCount: 2,
      toolName: 'grep_files',
      toolResult: 'src/main.dart:42: TODO\nsrc/utils.dart:15: FIXME',
      replyText: '代码分析完成，发现 2 处待改进点。',
    );
  }

  // Long messages — more elaborate response with multiple tools
  if (text.length > 80) {
    return const MockConfig(
      hasThinking: true,
      hasTool: true,
      toolCount: 3,
      thinkText: '正在深入分析您的详细请求……',
      toolName: 'analyze',
      toolResult: '深度分析结果：\n- 文件扫描完成\n- 依赖检查通过\n- 性能评估中等',
      replyText: '已处理您的长篇请求。以上是完整的分析结果与建议。',
    );
  }

  // English messages
  if (RegExp(r"^[a-zA-Z\s,?'!]+$").hasMatch(text.trim())) {
    return MockConfig(
      hasThinking: true,
      thinkText: 'Let me analyze your question...',
      replyText:
          'Thank you for your question. Here is the detailed analysis you requested.',
    );
  }

  // Default — thinking + content
  return MockConfig(
    hasThinking: true,
    replyText:
        '收到！已处理您的问题："${text.length > 20 ? '${text.substring(0, 20)}…' : text}"',
  );
}

// ═══════════════════════════════════════════════════════
//  Stream builders
// ═══════════════════════════════════════════════════════

/// Build a deterministic mock exchange event stream from [config].
Stream<ExchangeEvent> buildStreamFromConfig(MockConfig config) async* {
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

  if (config.hasError) {
    yield ExchangeError(id, '模拟错误：处理失败');
    return;
  }

  // 1. Thinking
  if (config.hasThinking && config.thinkText.isNotEmpty) {
    yield ThinkingStarted(id, 'think_1');
    final think = config.thinkText;
    for (var i = 0; i < think.length; i += 3) {
      await Future.delayed(_chunkDelay);
      yield ThinkingDelta(
        id,
        'think_1',
        think.substring(0, i + 3 > think.length ? think.length : i + 3),
      );
    }
    yield ThinkingCompleted(id, 'think_1', think);
    yield ParallelBoundary(id);
    yield TokenCount(id, think.length * 3);
  }

  // 2. Tool calls
  if (config.hasTool && config.toolCount > 0) {
    for (var i = 0; i < config.toolCount; i++) {
      yield ToolCallStarted(
        id,
        'tool_$i',
        config.toolName,
        {'arg': 'value_$i'},
        requiresConfirm: config.requireConfirm,
        autoApproved: config.autoApproved,
        description: config.requireConfirm ? '将要执行以下操作' : null,
      );
    }
    yield ParallelBoundary(id);

    for (var i = 0; i < config.toolCount; i++) {
      await Future.delayed(_chunkDelay);
      yield ToolCallCompleted(id, 'tool_$i', config.toolResult);
    }
    yield TokenCount(id, config.toolCount * 50);
  }

  // 3. Content / reply
  if (config.replyText.isNotEmpty) {
    yield ContentStarted(id, 'content_1');
    final reply = config.replyText;
    for (var i = 0; i < reply.length; i += 3) {
      await Future.delayed(_chunkDelay);
      yield ContentDelta(
        id,
        'content_1',
        reply.substring(0, i + 3 > reply.length ? reply.length : i + 3),
      );
    }
    yield ContentCompleted(id, 'content_1', reply);
    yield TokenCount(id, reply.length * 5);
  }
}

// ═══════════════════════════════════════════════════════
//  Mock AI factory — text-aware routing
// ═══════════════════════════════════════════════════════

/// Creates a mock AI that analyzes the input text and returns
/// an appropriate response (with tools, confirm, error, etc.).
Stream<ExchangeEvent> Function(String) createSmartMockAI() {
  return (String text) => buildStreamFromConfig(configForText(text));
}

/// Creates a fast mock AI for pre-loading history exchanges.
/// Uses minimal config (thinking + content only, no tool, no delay).
Stream<ExchangeEvent> Function(String) createFastMockAI() {
  return (String text) => _fastHistoryStream(text);
}

Stream<ExchangeEvent> _fastHistoryStream(String text) async* {
  final id = 'hist_${DateTime.now().millisecondsSinceEpoch}';
  yield ThinkingStarted(id, 'th');
  yield ThinkingDelta(id, 'th', '分析历史');
  yield ThinkingCompleted(id, 'th', '分析历史');
  yield ParallelBoundary(id);
  yield ContentStarted(id, 'ct');
  final reply = '关于"$text"的历史回复。';
  yield ContentDelta(id, 'ct', reply);
  yield ContentCompleted(id, 'ct', reply);
  yield TokenCount(id, 42);
}

/// Creates a fixed-config mock AI for deterministic tests.
Stream<ExchangeEvent> Function(String) createFixedMockAI(MockConfig config) {
  return (_) => buildStreamFromConfig(config);
}

// ═══════════════════════════════════════════════════════
//  Test utilities
// ═══════════════════════════════════════════════════════

/// Wait for the AI to finish processing by letting real time elapse.
Future<void> waitForAICompletion(WidgetTester tester) async {
  await tester.runAsync(() => Future.delayed(aiCompletionTimeout));
  // Pump enough for AnimatedContainer / AnimatedSize transitions (250ms) + stats bar (600ms)
  await tester.pump(const Duration(milliseconds: 700));
}

/// Wait a short period for intermediate states (e.g. confirm gate to appear).
Future<void> waitForIntermediateState(WidgetTester tester) async {
  await tester.runAsync(
    () => Future.delayed(const Duration(milliseconds: 800)),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Send a message via bus API and pump once to trigger initial frame.
Future<void> sendViaBus(
  WidgetTester tester,
  DefaultChatBus bus,
  String text,
) async {
  bus.sendMessage(text);
  await tester.pump();
}

/// Pre-load [count] history exchanges into the bus using a fast mock AI.
Future<void> preloadHistory(
  WidgetTester tester,
  DefaultChatBus bus, {
  int count = 3,
}) async {
  final historyMessages = <String>[
    '上次讨论的项目进展',
    'API 接口设计方案',
    '数据库表结构优化',
    '用户权限管理',
    '日志系统改造',
  ];
  bus.onGenerate = createFastMockAI();
  for (var i = 0; i < count && i < historyMessages.length; i++) {
    bus.sendMessage(historyMessages[i]);
    await tester.pump();
  }
  // Wait for all history exchanges to complete
  await waitForAICompletion(tester);
}

// ═══════════════════════════════════════════════════════
//  Test message fixtures — 10 messages of varying lengths
// ═══════════════════════════════════════════════════════

/// 10 test messages covering different scenarios.
///
/// Each entry: (message, label)
const List<(String, String)> testMessages = [
  ('你好', '短问候'),
  ('分析项目的代码质量', '代码分析（含工具）'),
  ('帮我检查这些性能问题：数据库查询优化、缓存策略、API 响应时间，以及内存使用情况。', '性能检查（较长）'),
  ('什么是微服务架构？它与单体架构有什么区别？各自有什么优缺点？', '概念解释'),
  ('确认执行数据库结构变更迁移工具', '确认弹窗'),
  ('查询系统当前运行状态', '状态查询'),
  (
    'What are the key differences between StatefulWidget and StatelessWidget?',
    '英文问题',
  ),
  ('生成一个错误的测试请求来模拟异常', '错误场景'),
  ('请给我一些关于代码重构的建议', '重构建议'),
  ('总结一下以上所有操作的结果', '总结'),
];

/// Messages that are guaranteed to NOT trigger confirm or error.
/// Used when we want a predictable flow.
const List<(String, String)> safeTestMessages = [
  ('你好，很高兴认识你', '问候'),
  ('今天天气如何', '简单查询'),
  ('帮我写一个简单的 Flutter 组件', '代码生成'),
  ('什么是依赖注入', '概念查询'),
  ('如何优化 Flutter 列表性能', '性能建议'),
  ('请介绍一下 BLoC 模式', '架构介绍'),
  ('What is the difference between const and final in Dart?', 'Dart 概念'),
  ('写一段 REST API 调用示例代码', '代码示例'),
  ('帮我解释一下异步编程', '异步概念'),
  ('总结今天的学习内容', '总结'),
];

// ═══════════════════════════════════════════════════════
//  Common assertions
// ═══════════════════════════════════════════════════════

/// Assert that the user message text is visible on screen.
void expectUserMessageVisible(String message) {
  // The text may appear multiple times (in the sticky header + dialog trigger etc.)
  // Use findsAtLeastNWidgets(1) to be lenient.
  expect(find.text(message), findsAtLeastNWidgets(1));
}

/// Assert that standard block headers are visible.
void expectBlockHeadersVisible({
  bool thinking = false,
  bool tool = false,
  bool content = false,
}) {
  if (thinking) {
    expect(find.text('思考'), findsAtLeastNWidgets(1));
  }
  if (tool) {
    expect(find.textContaining('工具'), findsAtLeastNWidgets(1));
  }
  if (content) {
    expect(find.text('回答'), findsAtLeastNWidgets(1));
  }
}

/// Assert the empty placeholder is shown.
void expectEmptyPlaceholder(WidgetTester tester) {
  expect(find.text('发送一条消息开始对话'), findsOneWidget);
}

/// Assert the queue badge shows a specific count.
void expectQueueBadge(int count) {
  expect(find.text('$count'), findsOneWidget);
}

/// Assert the stats bar shows a token count.
void expectStatsBarVisible(WidgetTester tester) {
  // Token count text uses suffix "词元"
  expect(find.textContaining('词元'), findsAtLeastNWidgets(1));
}

/// Assert loading indicator is shown.
void expectLoadingIndicator(WidgetTester tester) {
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
}
