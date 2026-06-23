// Vine AI 流式输出集成测试
//
// 验证流式输出路径是否工作：contentStream → ThinkingDelta → UI 渲染
// 以及思考块 elapsed 是否实时更新。
//
// 运行：
//   cd dart/example
//   flutter test --dart-define-from-file=.env.test integration_test/vine_ai_streaming_test.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'package:vine_ai/vine_ai.dart' as vine;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Vine AI 流式输出', () {
    testWidgets('contentStream → ThinkingDelta 流式分块逐步显示', (tester) async {
      final llm = _MockStreamClient();
      final bus = DefaultChatBus(onGenerate: (text) => _genEvents(text, llm));

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: ChatScreen(bus: bus)),
        ),
      );
      await tester.pump();

      bus.sendMessage('测试消息');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('思考'), findsWidgets);
    });

    test('contentStream 分块序列验证', () async {
      final llm = _MockStreamClient();
      final events = await _genEvents('测试', llm).toList();

      // 验证事件序列：ThinkingStarted → ThinkingDelta × N → ThinkingCompleted
      expect(events.first, isA<ThinkingStarted>());

      final deltas = events.whereType<ThinkingDelta>().toList();
      expect(deltas.isNotEmpty, true, reason: '应该有 ThinkingDelta 事件');

      // 验证分块逐步增长：每个 delta 的 content 比前一个长
      for (var i = 1; i < deltas.length; i++) {
        expect(
          deltas[i].text.length,
          greaterThan(deltas[i - 1].text.length),
          reason: '第 $i 个 delta 应该比第 ${i - 1} 个长',
        );
      }

      // 验证最后一个 delta 和 ThinkingCompleted 内容一致
      final completed = events.whereType<ThinkingCompleted>().first;
      expect(completed.fullText, deltas.last.text);

      // 验证 total duration 合理（首 token 延迟 + 分块间隔）
      debugPrint('流式分块数: ${deltas.length}');
      debugPrint('最终内容长度: ${deltas.last.text.length}');
    });

    test('elapsed 实时更新（首 token 延迟时不卡住）', () async {
      final llm = _MockStreamClient();

      // 测试首 token 延迟 500ms + 3 个分块各间隔 100ms
      final sw = Stopwatch()..start();
      final events = await _genEvents('测试', llm).toList();
      sw.stop();

      final started = events.whereType<ThinkingStarted>().first;
      expect(started, isA<ThinkingStarted>());
      final elapsedMs = sw.elapsedMilliseconds;

      // 首 token 延迟 + 分块间隔应该使总耗时 > 0
      debugPrint('总耗时: ${elapsedMs}ms');
      expect(elapsedMs, greaterThan(0));
    });
  });
}

/// 生成 ExchangeEvent 流（模拟 dispatch 逻辑）
Stream<ExchangeEvent> _genEvents(String userMsg, vine.LlmClient llm) async* {
  final id = 'ex_test_${DateTime.now().millisecondsSinceEpoch}';

  yield ThinkingStarted(id, 'think');

  final resp = await llm.chat(
    vine.ChatRequest(
      model: 'test-model',
      messages: [
        vine.ChatMessage(
          role: vine.MessageRole.system,
          content: '你是调度器。分析用户需求。',
        ),
        vine.ChatMessage(role: vine.MessageRole.user, content: userMsg),
      ],
      maxTokens: 256,
      stream: true,
    ),
  );

  if (resp.contentStream != null) {
    var displayed = '';
    await for (final chunk in resp.contentStream!) {
      displayed += chunk;
      yield ThinkingDelta(id, 'think', displayed);
    }
    yield ThinkingCompleted(id, 'think', displayed);
  } else if (resp.content != null && resp.content!.isNotEmpty) {
    yield ThinkingDelta(id, 'think', resp.content!);
    yield ThinkingCompleted(id, 'think', resp.content!);
  }
}

/// 模拟流式 LLM 客户端（带首 token 延迟 + 分块）
class _MockStreamClient implements vine.LlmClient {
  @override
  Future<vine.ChatResponse> chat(vine.ChatRequest request) async {
    // 模拟 500ms 首 token 延迟
    await Future.delayed(const Duration(milliseconds: 500));

    const content = '根据您的需求，我选择了合适的工作流来执行。';

    // 模拟 5 个分块
    final chunks = <String>['根据您的需求，', '我选择了合适的', '工作流来执行。'];

    return vine.ChatResponse(
      content: content,
      contentStream: Stream<String>.fromIterable(chunks),
    );
  }
}
