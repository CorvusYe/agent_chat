// Copyright (c) 2025 All project authors. All rights reserved.
//
// This source code is licensed under Apache 2.0 License.

// Agent Chat × de_src — 用真实 AI 调用替换 Mock
//
// 本文件展示了如何将 agent_chat 的 UI 对接 de_src 库的真实 LLM API：
//
// 1. 定义 DsrcApi（AI 能力契约）
// 2. 桥接 de_src 的流式输出 → agent_chat 的 ExchangeEvent 流
// 3. 处理流式推理过程（reasoning）和内容输出
// 4. 支持工具调用（subTopics + answerSettings）
//
// ⚠️ API 配置通过 --dart-define-from-file=.env.test 注入，详见 .env.test.example。
//
// 依赖（已添加到 pubspec.yaml）：
//   de_src:
//     path: ../../../../dudu-ltd/deepseek_reverse_call/dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import 'package:de_src/de_src.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 配置 — 通过 --dart-define-from-file=.env.test 注入
// 参考 .env.test.example 创建自己的配置文件，然后运行：
//   flutter run --dart-define-from-file=.env.test -t lib/main_de_src.dart
// ═══════════════════════════════════════════════════════════════════════════

const String apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.deepseek.com',
);
const String modelId = String.fromEnvironment(
  'API_MODEL_ID',
  defaultValue: 'deepseek-v4-flash',
);
const bool supportJson = bool.fromEnvironment(
  'API_SUPPORT_JSON',
  defaultValue: true,
);

// ═══════════════════════════════════════════════════════════════════════════
// 第一部分：定义 DsrcApi — AI 的能力契约
// ═══════════════════════════════════════════════════════════════════════════

/// 从 sealed ChatMessage 中提取文本内容
String _msgContent(ChatMessage? msg) => switch (msg) {
  AssistantMessage m => m.content ?? '',
  UserMessage m => m.text ?? '',
  _ => '',
};

/// 从 JSON 响应中提取 reply 字段，作为展示给用户的消息体
String _extractReply(String raw) {
  try {
    final json = _parseJson5(raw);
    if (json case {'reply': final String reply}) return reply;
    if (json case {'reply': final reply}) return reply.toString();
  } catch (_) {}
  return raw;
}

/// 轻量 JSON 解析（兼容未闭合的流式片段）
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

/// 基础问答 API — 不带子话题，仅做问答
var qaApi = DsrcApi(
  value: 'assistant-qa',
  name: 'AI 助手',
  prompt: () => ['你是一个智能 AI 助手，请用中文回答用户问题。', '回答简洁准确，必要时可以分点说明。'],
  subTopics: () => [],
  plainTopics: [],
  properties: () => {'reply': '回复内容'},
);

/// 读取文件工具 API（示例）
var readFileApi = DsrcApi(
  value: 'tool-read-file',
  name: '读取文件',
  prompt: () => ['读取指定路径的文件内容并返回。'],
  subTopics: () => [],
  plainTopics: [],
  properties: () => {'path': '文件路径', 'content': '文件内容'},
);

/// 代码分析工具 API（示例）
var codeAnalyzeApi = DsrcApi(
  value: 'tool-code-analyze',
  name: '代码分析',
  prompt: () => ['分析代码质量，返回发现的问题和改进建议。'],
  subTopics: () => [],
  plainTopics: [],
  properties: () => {
    'file': '分析的文件',
    'issues': '发现的问题列表',
    'suggestions': '改进建议',
  },
);

/// 路由器 API — 仅有 subTopics（工具列表），无额外 prompt / properties。
///
/// prompt 为空，LLM 只看到工具定义 + 用户消息，自行决定是否调工具。
var routerApi = DsrcApi(
  value: 'assistant-router',
  name: '智能助手',
  prompt: () => [],
  subTopics: () => [readFileApi, codeAnalyzeApi],
  plainTopics: ['say-goodbye'],
  properties: () => <String, String>{},
);

// ═══════════════════════════════════════════════════════════════════════════
// 第二部分：Stream 桥接 — de_src → ExchangeEvent
// ═══════════════════════════════════════════════════════════════════════════

/// 将 de_src 的流式输出转换为 agent_chat 的 ExchangeEvent 流。
///
/// 映射关系：
///   de_src cotStream  →  ThinkingStarted / ThinkingDelta / ThinkingCompleted
///   de_src contentStream →  ContentStarted / ContentDelta / ContentCompleted
///   de_src 内部工具调用   →  ToolCallStarted / ToolCallCompleted
///
/// [text] 用户输入的消息文本。
/// [messageTransformer] 可选的消息格式转换，默认直接透传。
Stream<ExchangeEvent> deSrcToEventStream(
  String text, {
  String Function(String rawContent)? messageTransformer,
}) {
  final ctrl = StreamController<ExchangeEvent>();
  _processWithDeSrc(text, ctrl, messageTransformer);
  return ctrl.stream;
}

/// 内部处理函数 — 执行 de_src API 调用并桥接事件
Future<void> _processWithDeSrc(
  String text,
  StreamController<ExchangeEvent> ctrl, [
  String Function(String rawContent)? transformer,
]) async {
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

  // ── de_src 流控制器 ─────────────────────────────────
  final cotCtrl = StreamController<String>();
  final contentCtrl = StreamController<String>();

  try {
    // ── 缓存变量 ──
    var thinkBuffer = '';
    var contentBuffer = '';
    var thinkEmitted = false;
    var contentEmitted = false;

    // ── 桥接推理流 → Thinking 事件 ──
    cotCtrl.stream.listen(
      (chunk) {
        if (!thinkEmitted) {
          ctrl.add(ThinkingStarted(id, 'think'));
          thinkEmitted = true;
        }
        thinkBuffer += chunk;
        ctrl.add(ThinkingDelta(id, 'think', thinkBuffer));
      },
      onDone: () {
        if (thinkEmitted) {
          ctrl.add(ThinkingCompleted(id, 'think', thinkBuffer));
          ctrl.add(ParallelBoundary(id));
        }
      },
      cancelOnError: true,
    );

    // ── 桥接内容流 → Content 事件 ──
    contentCtrl.stream.listen(
      (chunk) {
        if (!contentEmitted) {
          ctrl.add(ContentStarted(id, 'content'));
          contentEmitted = true;
        }
        contentBuffer += chunk;
        ctrl.add(ContentDelta(id, 'content', contentBuffer));
      },
      onDone: () {
        if (contentEmitted) {
          // 可选消息格式转换
          var finalContent = contentBuffer;
          if (transformer != null) {
            finalContent = transformer(finalContent);
          }
          ctrl.add(ContentCompleted(id, 'content', finalContent));
          ctrl.add(TokenCount(id, contentBuffer.length));
        }
      },
      cancelOnError: true,
    );

    // ── 初始化 de_src 客户端 ──
    final dsrc = DeepSeekReverseCall(
      appKey: apiKey,
      baseUrl: baseUrl,
      modelId: modelId,
      supportJson: supportJson,
      stream: true,
    );

    // ── 发起 API 调用 ──
    // dsrc.api() 会自动：1) 构建 system + user 消息 2) 流式输出到 ctrl
    // 3) 处理工具调用 4) 返回最终内容
    await dsrc.api(
      msgs: [text],
      api: qaApi,
      cotStream: cotCtrl,
      contentStream: contentCtrl,
    );

    // 确保流监听器完成处理
    await Future<void>.delayed(Duration.zero);
  } catch (e) {
    if (!ctrl.isClosed) {
      ctrl.add(ExchangeError(id, 'AI 调用失败: $e'));
    }
  } finally {
    await cotCtrl.close();
    await contentCtrl.close();
    if (!ctrl.isClosed) {
      await ctrl.close();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 第三部分：带工具调用的桥接（高级用法）
// ═══════════════════════════════════════════════════════════════════════════

/// 带工具处理的事件生成器。
///
/// 相比单纯的流桥接，此函数额外处理了工具回调：
/// 1. 在 answerSettings 中注册工具处理函数
/// 2. 工具处理函数内部调用 dsrc.api() 执行子任务
/// 3. 工具处理结果嵌入到后续的消息轮次中
Stream<ExchangeEvent> deSrcWithTools(String text) {
  final ctrl = StreamController<ExchangeEvent>();
  _processWithTools(text, ctrl);
  return ctrl.stream;
}

Future<void> _processWithTools(
  String text,
  StreamController<ExchangeEvent> ctrl,
) async {
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

  final cotCtrl = StreamController<String>();
  final contentCtrl = StreamController<String>();

  try {
    // ── 缓存 ──
    var thinkBuffer = '';
    var thinkEmitted = false;
    // ignore: unused_local_variable
    var contentBuffer = '';

    // ── 推理流：流式输出 ──
    cotCtrl.stream.listen(
      (chunk) {
        if (!thinkEmitted) {
          ctrl.add(ThinkingStarted(id, 'think'));
          thinkEmitted = true;
        }
        thinkBuffer += chunk;
        ctrl.add(ThinkingDelta(id, 'think', thinkBuffer));
      },
      onDone: () {
        if (thinkEmitted) {
          ctrl.add(ThinkingCompleted(id, 'think', thinkBuffer));
          ctrl.add(ParallelBoundary(id));
        }
      },
      cancelOnError: true,
    );

    // ── 内容流：仅缓冲，不发射事件 ──
    // 内容事件在工具 handler 内部或 dsrc.api() 返回后发射，
    // 确保内容 block 出现在工具 block 之后而非之前。
    contentCtrl.stream.listen(
      (chunk) {
        contentBuffer += chunk;
      },
      onDone: () {},
      cancelOnError: true,
    );

    // ── 内容块 ID 生成器 ──
    // 每个 content block 拥有唯一 ID，支持同一 exchange 内多个内容块。
    var contentSeq = 0;
    String nextContentId() => '${id}_content_${contentSeq++}';

    // ── 注册工具回调 ──
    Future<List<ChatMessage>?> readFileHandler(ActionArgs args) async {
      // 发射本轮模型的中间回答（如有）
      final reply = (args.prev?['reply'] as String?) ?? '';
      if (reply.isNotEmpty) {
        final cid = nextContentId();
        ctrl.add(ContentStarted(id, cid));
        ctrl.add(ContentDelta(id, cid, reply));
        ctrl.add(ContentCompleted(id, cid, reply));
      }

      final tcId = (args.prev?['_tool_call_id'] as String?) ?? 'tool_read';
      ctrl.add(ParallelBoundary(id));
      ctrl.add(
        ToolCallStarted(id, tcId, 'read_file', {
          'path': args.prev?['path'] ?? 'unknown',
        }),
      );
      ctrl.add(ToolCallCompleted(id, tcId, '模拟文件内容：\nTODO list\n1. ...'));
      return [
        ChatMessage.assistant(content: _msgContent(args.message)),
        ChatMessage.user(UserMessageContent.text('文件已读取，请根据文件内容继续回答。')),
      ];
    }

    Future<List<ChatMessage>?> codeAnalyzeHandler(ActionArgs args) async {
      // 发射本轮模型的中间回答（如有）
      final reply = (args.prev?['reply'] as String?) ?? '';
      if (reply.isNotEmpty) {
        final cid = nextContentId();
        ctrl.add(ContentStarted(id, cid));
        ctrl.add(ContentDelta(id, cid, reply));
        ctrl.add(ContentCompleted(id, cid, reply));
      }

      final tcId = (args.prev?['_tool_call_id'] as String?) ?? 'tool_analyze';
      ctrl.add(ParallelBoundary(id));
      ctrl.add(
        ToolCallStarted(id, tcId, 'code_analyze', {
          'file': args.prev?['file'] ?? 'unknown',
        }),
      );
      ctrl.add(ToolCallCompleted(id, tcId, '分析完成：发现 2 个问题'));
      return [
        ChatMessage.assistant(content: _msgContent(args.message)),
        ChatMessage.user(UserMessageContent.text('代码分析完成，请根据分析结果向用户报告。')),
      ];
    }

    // ── 注册到 answerSettings ──
    // 注意：路由回调只负责分发，不发射 Content 事件
    answerSettings.addAll({
      routerApi.value: (ActionArgs args) async {
        if (args.prev?['finished'] == true) return null;

        // 处理 API 原生 tool_calls（OpenAI 风格流式函数调用）
        if (args.toolCalls != null && args.toolCalls!.isNotEmpty) {
          for (final tc in args.toolCalls!) {
            final handler = answerSettings[tc.function.name];
            if (handler == null) continue;
            Map<String, dynamic> parsed = {};
            try {
              parsed = Map<String, dynamic>.from(
                json.decode(tc.function.arguments),
              );
            } catch (_) {}
            parsed['_tool_call_id'] = tc.id;
            return await handler(args.copyWith(prev: parsed));
          }
          return null;
        }

        final router = args.prev?['router'] as String?;
        if (router == null || answerSettings[router] == null) return null;
        return await answerSettings[router]!(args);
      },
      readFileApi.value: readFileHandler,
      codeAnalyzeApi.value: codeAnalyzeHandler,
      'say-goodbye': (_) async => null,
    });

    // ── 初始化客户端并调用 ──
    final dsrc = DeepSeekReverseCall(
      appKey: apiKey,
      baseUrl: baseUrl,
      modelId: modelId,
      supportJson: supportJson,
      stream: true,
    );

    final result = await dsrc.api(
      msgs: [text],
      api: routerApi,
      cotStream: cotCtrl,
      contentStream: contentCtrl,
    );

    await Future<void>.delayed(Duration.zero);

    // ── 从 dsrc.api() 的最终返回值中提取并发射内容 ──
    // dsrc.api() 会递归处理工具调用，最终返回最终的文本回答。
    // 注意：de_src 在原生 tool_calls 非空时才会调 answerSettings；
    // JSON router 模式下（{"router":"tool-read-file",...}）toolCalls 为空，
    // de_src 直接返回 JSON 字符串，需在此处手动分发 router。
    // 使用 nextContentId() 确保唯一 block ID。
    if (result != null && result.isNotEmpty) {
      final parsed = _parseJson5(result);

      // JSON router 分发：模型可能使用字段路由而非原生 tool_calls。
      // de_src 在 toolCalls 为空时不调 answerSettings，需手动触发。
      // 工具 handler 内部已发射 reply 内容 + 工具事件，此处不再重复发射。
      final router = parsed['router'] as String?;
      final hasRouterDispatch =
          router != null &&
          answerSettings[router] != null &&
          router != 'assistant-qa' &&
          router != 'say-goodbye';
      if (hasRouterDispatch) {
        await answerSettings[router]!(ActionArgs(prev: parsed, api: routerApi));
      }

      // 提取 reply 作为展示内容
      // 注意：hasRouterDispatch 为真时 handler 已发射 reply 内容，跳过避免重复。
      if (!hasRouterDispatch && parsed.containsKey('reply')) {
        final reply = parsed['reply'].toString();
        if (reply.isNotEmpty) {
          final cid = nextContentId();
          ctrl.add(ContentStarted(id, cid));
          ctrl.add(ContentDelta(id, cid, reply));
          ctrl.add(ContentCompleted(id, cid, reply));
          ctrl.add(TokenCount(id, reply.length));
        }
      } else if (!hasRouterDispatch && !result.trimLeft().startsWith('{')) {
        // 非 JSON 纯文本回复（兜底）
        final cid = nextContentId();
        ctrl.add(ContentStarted(id, cid));
        ctrl.add(ContentDelta(id, cid, result));
        ctrl.add(ContentCompleted(id, cid, result));
        ctrl.add(TokenCount(id, result.length));
      }
    }
  } catch (e) {
    if (!ctrl.isClosed) {
      ctrl.add(ExchangeError(id, 'AI 调用失败: $e'));
    }
  } finally {
    await cotCtrl.close();
    await contentCtrl.close();
    if (!ctrl.isClosed) await ctrl.close();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 第四部分：Flutter App — 使用 de_src 替代 Mock
// ═══════════════════════════════════════════════════════════════════════════

class DeSrcChatApp extends StatefulWidget {
  final bool enableTools;
  final Stream<ExchangeEvent> Function(String)? mockGenerator;

  const DeSrcChatApp({super.key, this.enableTools = false, this.mockGenerator});

  @override
  State<DeSrcChatApp> createState() => _DeSrcChatAppState();
}

class _DeSrcChatAppState extends State<DeSrcChatApp> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();

    // 使用 de_src 桥接作为 AI 事件源
    // 默认从 JSON 响应中提取 reply 字段
    // 如果提供了 mockGenerator（测试用），优先使用
    final generator =
        widget.mockGenerator ??
        (text) => deSrcToEventStream(text, messageTransformer: _extractReply);
    bus = DefaultChatBus(
      onGenerate: widget.enableTools ? deSrcWithTools : generator,
      onInterrupt: _onInterrupt,
    );
  }

  void _onInterrupt() {
    debugPrint('用户中断了 AI 响应');
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agent Chat × de_src',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: Scaffold(
        key: const ValueKey('de_src_scaffold'),
        appBar: AppBar(
          title: Text(
            widget.enableTools ? '智能助手（带工具）' : 'AI 助手',
            key: const ValueKey('appbar_title'),
          ),
          actions: [
            if (widget.enableTools)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Chip(
                  label: Text('工具模式', style: TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        body: ChatScreen(bus: bus),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 第五部分：入口
// ═══════════════════════════════════════════════════════════════════════════

/// 使用 de_src 替代 Mock 的 Agent Chat 入口。
///
/// 运行方式：
///   cd dart/e2e-example
///   flutter run --dart-define-from-file=.env.test -t lib/main_de_src.dart
///
/// VS Code 启动：
///   1. 在 VS Code 中打开 dart/e2e-example/ 文件夹
///   2. 按 F5（或 Ctrl+F5），选择 "de_src (tools enabled)" 配置
///
/// 注意事项：
///   1. 参考 .env.test.example 创建 .env.test 并填入你的 API 信息
///   2. 确保 de_src 的依赖路径在 pubspec.yaml 中正确
///   3. 运行前执行 flutter pub get
void main() {
  runApp(const DeSrcChatApp(enableTools: true));
}

/// 带工具支持的模式（备选入口）
///
/// 使用 subTopics + answerSettings 实现 LLM 自主工具调用。
/// 目前框架整合中，工具调用的事件桥接为预览实现。
void mainWithTools() {
  runApp(const DeSrcChatApp(enableTools: true));
}
