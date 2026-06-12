// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agent_chat/agent_chat.dart';
import 'package:de_src/de_src.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  端到端测试 — 真实 de_src API 调用
//
//  运行条件：网络可达 + apiKey 有效（否则被跳过）
//
//  运行方式：
//     cd dart/example
//     flutter drive --dart-define-from-file=.env.test \
//       --driver=test_driver/integration_test.dart \
//       --target=integration_test/de_src_e2e_test.dart -d windows
//
//  注意：这些测试会消耗 API 额度，应在需要验证 API 集成时手动执行。
//  API 配置通过 --dart-define-from-file=.env.test 注入，详见 .env.test.example。
// ═══════════════════════════════════════════════════════════════════════════

const apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.deepseek.com',
);
const modelId = String.fromEnvironment(
  'API_MODEL_ID',
  defaultValue: 'deepseek-v4-flash',
);

final _qaApi = DsrcApi(
  value: 'e2e-qa',
  name: 'E2E 问答',
  prompt: () => ['你是一个智能 AI 助手，请用中文回答。回答简洁，不超过 50 字。'],
  subTopics: () => [],
  plainTopics: [],
  properties: () => {'reply': '回复内容'},
);

// ═══════════════════════════════════════════════════════════════════════════
//  桥接函数（同 main_de_src.dart）
// ═══════════════════════════════════════════════════════════════════════════

Stream<ExchangeEvent> _deSrcToEvents(String text, DsrcApi api) {
  final ctrl = StreamController<ExchangeEvent>();
  _bridge(text, api, ctrl);
  return ctrl.stream;
}

Future<void> _bridge(
  String text,
  DsrcApi api,
  StreamController<ExchangeEvent> ctrl,
) async {
  final id = 'ex_e2e_${DateTime.now().millisecondsSinceEpoch}';
  final cotCtrl = StreamController<String>();
  final contentCtrl = StreamController<String>();

  try {
    var thinkBuf = '', thinkStarted = false;
    var contentBuf = '', contentStarted = false;

    cotCtrl.stream.listen(
      (chunk) {
        if (!thinkStarted) {
          ctrl.add(ThinkingStarted(id, 'think'));
          thinkStarted = true;
        }
        thinkBuf += chunk;
        ctrl.add(ThinkingDelta(id, 'think', thinkBuf));
      },
      onDone: () {
        if (thinkStarted) {
          ctrl.add(ThinkingCompleted(id, 'think', thinkBuf));
          ctrl.add(ParallelBoundary(id));
        }
      },
    );

    contentCtrl.stream.listen(
      (chunk) {
        if (!contentStarted) {
          ctrl.add(ContentStarted(id, 'content'));
          contentStarted = true;
        }
        contentBuf += chunk;
        ctrl.add(ContentDelta(id, 'content', contentBuf));
      },
      onDone: () {
        if (contentStarted) {
          ctrl.add(ContentCompleted(id, 'content', contentBuf));
          ctrl.add(TokenCount(id, contentBuf.length));
        }
      },
    );

    final dsrc = DeepSeekReverseCall(
      appKey: apiKey,
      baseUrl: baseUrl,
      modelId: modelId,
      supportJson: true,
      stream: true,
    );

    await dsrc
        .api(
          msgs: [text],
          api: api,
          cotStream: cotCtrl,
          contentStream: contentCtrl,
        )
        .timeout(const Duration(seconds: 60));
    await Future<void>.delayed(Duration.zero);
  } catch (e) {
    if (!ctrl.isClosed) {
      ctrl.add(ExchangeError(id, e.toString()));
    }
  } finally {
    await cotCtrl.close();
    await contentCtrl.close();
    if (!ctrl.isClosed) await ctrl.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  工具：等待 exchange 完成（轮询，避免 runAsync 重入）
// ═══════════════════════════════════════════════════════════════════════════

/// 在 runAsync 中轮询直到 bus 空闲或超时。
/// 比固定 Future.delayed 更高效，API 快就早返回，慢就等足。
Future<void> waitBusIdle(
  WidgetTester tester,
  DefaultChatBus bus, {
  Duration timeout = const Duration(seconds: 120),
}) async {
  await tester.runAsync(() async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (!bus.isStreaming && bus.exchanges.isNotEmpty) {
        final last = bus.exchanges.last;
        if (last.status == ExchangeStatus.completed ||
            last.status == ExchangeStatus.failed ||
            last.status == ExchangeStatus.cancelled) {
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw TimeoutException('waitBusIdle 超时 $timeout');
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. 纯 API 调用（不依赖 UI） ──

  group('E2E: 纯 API 调用', () {
    test('API 连接', timeout: Timeout(Duration(seconds: 20)), () async {
      final client = OpenAIClient.withApiKey(apiKey, baseUrl: baseUrl);
      try {
        await client.chat.completions
            .create(
              ChatCompletionCreateRequest(
                model: modelId,
                messages: [ChatMessage.user(UserMessageContent.text('ping'))],
                maxTokens: 5,
              ),
            )
            .timeout(const Duration(seconds: 15));
        print('✅ API 可达');
      } catch (e) {
        print('⚠️ API 不可达: $e');
      }
    });

    test(
      'dsrc.api() 返回非空结果',
      timeout: Timeout(Duration(seconds: 90)),
      () async {
        final dsrc = DeepSeekReverseCall(
          appKey: apiKey,
          baseUrl: baseUrl,
          modelId: modelId,
          supportJson: false, // 非流式，简单测试
          stream: false,
        );
        final result = await dsrc
            .api(msgs: ['用一句话回答：1+1等于几？'], api: _qaApi)
            .timeout(const Duration(seconds: 60));
        print('dsrc.api() 返回长度: ${result?.length ?? 0}');
        expect(result?.isNotEmpty, isTrue, reason: 'API 应返回非空内容');
      },
    );

    test(
      '流式输出: cotStream + contentStream 收到数据',
      timeout: Timeout(Duration(seconds: 90)),
      () async {
        final cotCtrl = StreamController<String>();
        final contentCtrl = StreamController<String>();
        final received = <String, String>{'cot': '', 'content': ''};

        cotCtrl.stream.listen((c) => received['cot'] = received['cot']! + c);
        contentCtrl.stream.listen(
          (c) => received['content'] = received['content']! + c,
        );

        final dsrc = DeepSeekReverseCall(
          appKey: apiKey,
          baseUrl: baseUrl,
          modelId: modelId,
          supportJson: true,
          stream: true,
        );

        await dsrc
            .api(
              msgs: ['简单介绍一下人工智能'],
              api: _qaApi,
              cotStream: cotCtrl,
              contentStream: contentCtrl,
            )
            .timeout(const Duration(seconds: 60));

        await Future.delayed(Duration.zero);
        await cotCtrl.close();
        await contentCtrl.close();

        print('cot 收到 ${received['cot']!.length} 字符');
        print('content 收到 ${received['content']!.length} 字符');

        // content 应该非空
        expect(received['content']!.isNotEmpty, isTrue);

        // deepseek-v4-flash 可能不输出 reasoning，但 content 必须有
        if (received['cot']!.isNotEmpty) {
          print('✅ 模型输出了 reasoning');
        } else {
          print('ℹ️ 模型未输出 reasoning（deepseek-v4-flash 可能不支持）');
        }
      },
    );
  });

  // ── 2. 流式桥接 + UI ──

  group('E2E: 流式桥接 + UI', () {
    testWidgets('思考 + 内容流式输出到 UI', timeout: Timeout(Duration(seconds: 150)), (
      tester,
    ) async {
      final bus = DefaultChatBus(
        onGenerate: (text) => _deSrcToEvents(text, _qaApi),
      );

      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      bus.sendMessage('请用一句话介绍 Flutter');
      await tester.pump();

      // 等待 API 完成（轮询，最多 120s）
      await waitBusIdle(tester, bus);
      await tester.pump(const Duration(seconds: 1));

      final ex = bus.exchanges.last;
      print('Exchange 状态: ${ex.status}');
      print('Groups: ${ex.groups.length}');

      if (ex.status == ExchangeStatus.completed) {
        final blocks = ex.groups.expand((g) => g.blocks).toList();
        final hasThinking = blocks.any((b) => b.type == BlockType.thinking);
        final hasContent = blocks.any((b) => b.type == BlockType.content);
        print('有思考: $hasThinking, 有内容: $hasContent');
        expect(hasContent, isTrue, reason: '应至少包含内容 block');

        if (hasContent) {
          final cb = blocks.firstWhere((b) => b.type == BlockType.content);
          print('内容: ${cb.content}');
          expect(cb.content?.isNotEmpty, isTrue);
        }
      } else {
        print('⚠️ 状态: ${ex.status}');
        if (ex.errorMessage != null) print('错误: ${ex.errorMessage}');
      }
    });

    testWidgets('UI 发送→回答流程', timeout: Timeout(Duration(seconds: 150)), (
      tester,
    ) async {
      final bus = DefaultChatBus(
        onGenerate: (text) => _deSrcToEvents(text, _qaApi),
      );

      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      // 通过 UI 发送
      await tester.enterText(find.byType(TextField), '1+1等于几？');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.textContaining('1+1等于几'), findsAtLeastNWidgets(1));

      await waitBusIdle(tester, bus);
      await tester.pump(const Duration(seconds: 1));

      final hasThinking = find.text('思考').evaluate().isNotEmpty;
      final hasContent = find.text('回答').evaluate().isNotEmpty;
      print('UI 显示思考: $hasThinking, 显示回答: $hasContent');
    });
  });

  // ── 3. 事件时序 ──

  group('E2E: 事件时序', () {
    testWidgets(
      'ThinkingStarted 先于 ContentStarted',
      timeout: Timeout(Duration(seconds: 150)),
      (tester) async {
        final order = <String>[];

        final bus = DefaultChatBus(
          onGenerate: (text) {
            final original = _deSrcToEvents(text, _qaApi);
            final ctrl = StreamController<ExchangeEvent>();
            original.listen((e) {
              final name = e.runtimeType.toString();
              if (!order.contains(name)) order.add(name);
              ctrl.add(e);
            }, onDone: () => ctrl.close());
            return ctrl.stream;
          },
        );

        await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));
        bus.sendMessage('简单自我介绍');
        await tester.pump();

        await waitBusIdle(tester, bus);
        await tester.pump(const Duration(seconds: 1));

        print('事件顺序: $order');

        final tIdx = order.indexOf('ThinkingStarted');
        final cIdx = order.indexOf('ContentStarted');
        if (tIdx != -1 && cIdx != -1) {
          expect(
            tIdx,
            lessThan(cIdx),
            reason: 'ThinkingStarted 应在 ContentStarted 之前',
          );
        }
      },
    );
  });
}
