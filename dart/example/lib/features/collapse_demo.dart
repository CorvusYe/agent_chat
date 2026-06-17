// 块展开/折叠控制演示
//
// 展示 ChatScreen 中 block 展开/折叠的完整机制：
//   - 默认：最新 block 展开，历史 block 折叠
//   - 手动：点击 header 切换展开/折叠
//   - 同组规则：同组有 running 的 block 时强制展开
//   - 通过 CustomBlockEvent / 自定义信号控制块可见性

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class CollapseDemo extends StatefulWidget {
  const CollapseDemo({super.key});

  @override
  State<CollapseDemo> createState() => _CollapseDemoState();
}

class _CollapseDemoState extends State<CollapseDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockStream,
      onInterrupt: () => _cancelled = true,
    );
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
    // 第1轮：完整对话（之后会被折叠）
    bus.sendMessage('第一轮对话（将被折叠）');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // 第2轮：新对话（展开状态）
    bus.sendMessage('第二轮对话（展开状态）');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    // 第3轮：带并行工具的对话
    bus.sendMessage('第三轮：同组并行工具（强制展开）');
  }

  Stream<ExchangeEvent> _mockStream(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    // ── 思考块 ──
    yield ThinkingStarted(id, 'think');
    yield ThinkingDelta(id, 'think', '分析中…');
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think', '分析完成');

    // ── 第3轮展示同组并行工具 ──
    if (text.contains('第三轮')) {
      yield ToolCallStarted(id, 'tc_a', 'search_db', {'query': '用户数据'});
      yield ToolCallStarted(id, 'tc_b', 'read_cache', {'key': 'user_profile'});
      yield ParallelBoundary(id);
      await Future.delayed(const Duration(milliseconds: 400));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'tc_a', '找到 42 条记录');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'tc_b', '缓存命中');
    } else {
      // 普通单工具
      yield ToolCallStarted(id, 'tc', 'read_file', {
        'path': 'data.txt',
      }, autoApproved: true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'tc', '文件读取成功');
    }

    yield ParallelBoundary(id);
    yield TokenCount(id, 64);

    // ── 回答 ──
    yield ContentStarted(id, 'content');
    const reply = '处理完成。你可以点击 block 头部切换展开/折叠。';
    yield ContentDelta(id, 'content', reply);
    yield ContentCompleted(id, 'content', reply);
    yield TokenCount(id, reply.length);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
