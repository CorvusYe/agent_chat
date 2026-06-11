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
// ⚠️ 使用前请将下方 apiKey/baseUrl/modelId 替换为真实值。
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
// 配置区 — 替换为你的真实 API 信息
// ═══════════════════════════════════════════════════════════════════════════

const String _apiKey = 'YOUR_API_KEY';
const String _baseUrl = 'https://api.deepseek.com';
const String _modelId = 'deepseek-v4-flash';
const bool _supportJson = true;

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

/// 路由器 API — 根据用户输入选择合适的工具
///
/// 通过 subTopics 注册子话题，LLM 可以自主选择调用哪个工具。
var routerApi = DsrcApi(
  value: 'assistant-router',
  name: '智能助手',
  prompt: () => [
    '你是一个智能助手，可以根据用户的问题选择合适的工具。',
    '如果问题涉及文件操作，使用 read-file 工具。',
    '如果问题涉及代码审查，使用 code-analyze 工具。',
    '如果是普通问答，直接回复即可。',
  ],
  subTopics: () => [readFileApi, codeAnalyzeApi],
  plainTopics: ['say-goodbye'],
  properties: () => {
    'router': '功能路由：assistant-qa|tool-read-file|tool-code-analyze|say-goodbye',
    'reply': '回复内容',
    'finished': '是否结束对话',
  },
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
      appKey: _apiKey,
      baseUrl: _baseUrl,
      modelId: _modelId,
      supportJson: _supportJson,
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
    var contentBuffer = '';
    var contentEmitted = false;

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

    // ── 内容流：流式输出到 UI（打字机效果）──
    contentCtrl.stream.listen(
      (chunk) {
        if (!contentEmitted) {
          ctrl.add(ContentStarted(id, 'content'));
          contentEmitted = true;
        }
        contentBuffer += chunk;
        // 尝试提取 reply 字段，不成功则显示原始缓冲区
        ctrl.add(ContentDelta(id, 'content', _extractReply(contentBuffer)));
      },
      onDone: () {},
      cancelOnError: true,
    );

    // ── 注册工具回调 ──
    Future<List<ChatMessage>?> readFileHandler(ActionArgs args) async {
      ctrl.add(ParallelBoundary(id));
      ctrl.add(
        ToolCallStarted(id, 'tool_read', 'read_file', {
          'path': args.prev?['path'] ?? 'unknown',
        }),
      );
      ctrl.add(
        ToolCallCompleted(id, 'tool_read', '模拟文件内容：\nTODO list\n1. ...'),
      );
      return [
        ChatMessage.assistant(content: _msgContent(args.message)),
        ChatMessage.user(UserMessageContent.text('文件已读取，请根据文件内容继续回答。')),
      ];
    }

    Future<List<ChatMessage>?> codeAnalyzeHandler(ActionArgs args) async {
      ctrl.add(ParallelBoundary(id));
      ctrl.add(
        ToolCallStarted(id, 'tool_analyze', 'code_analyze', {
          'file': args.prev?['file'] ?? 'unknown',
        }),
      );
      ctrl.add(ToolCallCompleted(id, 'tool_analyze', '分析完成：发现 2 个问题'));
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
            if (tc.function.arguments is String) {
              try {
                parsed =
                    json.decode(tc.function.arguments as String)
                        as Map<String, dynamic>;
              } catch (_) {}
            }
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
      appKey: _apiKey,
      baseUrl: _baseUrl,
      modelId: _modelId,
      supportJson: _supportJson,
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
    // dsrc.api() 会递归处理工具调用，最终返回的是纯文本回答
    var displayText = result ?? contentBuffer;
    if (displayText.isNotEmpty) {
      // 尝试从 JSON 中提取 reply 字段
      final parsed = _parseJson5(displayText);
      if (parsed.containsKey('reply')) {
        displayText = parsed['reply'].toString();
      }
      if (!contentEmitted) {
        // 非流式：没有收到内容块，完整发射
        ctrl.add(ContentStarted(id, 'content'));
        ctrl.add(ContentDelta(id, 'content', displayText));
      }
      ctrl.add(ContentCompleted(id, 'content', displayText));
      ctrl.add(TokenCount(id, displayText.length));
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
///   cd dart/example
///   flutter run -t lib/main_de_src.dart
///
/// 注意事项：
///   1. 请先替换本文件顶部的 _apiKey / _baseUrl / _modelId
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
