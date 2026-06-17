// 流输出展示 — 打字机效果的 thinking / content delta
//
// 演示 ChatBus 通过 acceptEvents 接收流式事件并在 ChatScreen 中实时更新
// 的 "打字机" 效果。使用 DefaultChatBus.onGenerate 回调生成模拟 AI 事件流。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class StreamingOutputDemo extends StatefulWidget {
  const StreamingOutputDemo({super.key});

  @override
  State<StreamingOutputDemo> createState() => _StreamingOutputDemoState();
}

class _StreamingOutputDemoState extends State<StreamingOutputDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockStreaming,
      onInterrupt: () => _cancelled = true,
    );
    // 启动自动演示
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDemo());
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  bool _cancelled = false;

  Future<void> _autoDemo() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    bus.sendMessage('展示流式输出效果');
  }

  /// 模拟 AI 事件流 — 展示 thinking → tools → content 的完整流程
  Stream<ExchangeEvent> _mockStreaming(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    // ── 阶段 1：思考（逐字输出） ──
    yield ThinkingStarted(id, 'think_1');
    const thinkText =
        '让我仔细分析你的请求……\n'
        '首先，我需要理解用户的需求。\n'
        '然后，我会搜索相关知识库。\n'
        '最后，整理出完整的回答。';
    for (var i = 0; i < thinkText.length; i += 4) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (_cancelled) return;
      yield ThinkingDelta(
        id,
        'think_1',
        thinkText.substring(
          0,
          i + 4 > thinkText.length ? thinkText.length : i + 4,
        ),
      );
    }
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think_1', thinkText);
    yield TokenCount(id, 89);

    // ── 阶段 2：工具调用 ──
    if (_cancelled) return;
    yield ToolCallStarted(id, 'tool_1', 'read_file', {
      'path': 'src/main.dart',
    }, description: '读取源代码文件');
    await Future.delayed(const Duration(milliseconds: 500));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tool_1', '✓ 文件读取成功，共 245 行');

    if (_cancelled) return;
    yield ToolCallStarted(id, 'tool_2', 'grep_files', {
      'pattern': 'TODO',
    }, description: '搜索 TODO 标记');
    await Future.delayed(const Duration(milliseconds: 300));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tool_2', '找到 3 处 TODO');

    yield ParallelBoundary(id);
    yield TokenCount(id, 128);

    // ── 阶段 3：内容输出（打字机效果） ──
    if (_cancelled) return;
    yield ContentStarted(id, 'content_1');
    const reply =
        '根据分析结果，以下是关键发现：\n\n'
        '1. **代码质量** — 整体良好，有少量待优化点\n'
        '2. **性能风险** — 未发现明显瓶颈\n'
        '3. **建议** — 优先处理 find 出的 TODO 标记\n\n'
        '需要我进一步处理某个具体问题吗？';
    for (var i = 0; i < reply.length; i += 2) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (_cancelled) return;
      yield ContentDelta(
        id,
        'content_1',
        reply.substring(0, i + 2 > reply.length ? reply.length : i + 2),
      );
    }
    if (_cancelled) return;
    yield ContentCompleted(id, 'content_1', reply);
    yield TokenCount(id, reply.length);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
