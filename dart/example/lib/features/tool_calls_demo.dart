// 工具调用展示 — ToolCall block 各状态渲染
//
// 展示工具调用 block 的多种状态：
//   - pending（等待确认）
//   - running（执行中）
//   - completed（完成）
//   - cancelled（已取消）
//   - alwaysAllowed（始终允许）
//   - approved（已批准）

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class ToolCallsDemo extends StatefulWidget {
  const ToolCallsDemo({super.key});

  @override
  State<ToolCallsDemo> createState() => _ToolCallsDemoState();
}

class _ToolCallsDemoState extends State<ToolCallsDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockToolStream,
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
    bus.sendMessage('展示各种工具调用状态');
  }

  Stream<ExchangeEvent> _mockToolStream(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 'think');
    const thinkText = '正在分析请求，准备调用多个工具…';
    yield ThinkingDelta(id, 'think', thinkText.substring(0, 6));
    await Future.delayed(const Duration(milliseconds: 100));
    if (_cancelled) return;
    yield ThinkingDelta(id, 'think', thinkText);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think', thinkText);

    // 发起两个并行的工具调用
    // 工具1：需确认（autoApproved=false, requiresConfirm=true）
    yield ToolCallStarted(
      id,
      'tool_1',
      'execute_command',
      {'cmd': 'npm run deploy'},
      requiresConfirm: true,
      description: '将要执行部署命令',
      canAlwaysAllow: true,
    );
    // 工具2：自动执行（autoApproved=true）
    yield ToolCallStarted(id, 'tool_2', 'read_file', {
      'path': 'config.yaml',
    }, autoApproved: true);
    yield ParallelBoundary(id);
    yield TokenCount(id, 64);

    // 等待用户确认工具1（在 ChatScreen 中点击通过）；
    // 工具2 自动执行并完成
    await Future.delayed(const Duration(milliseconds: 600));
    if (_cancelled) return;
    yield ToolCallCompleted(
      id,
      'tool_2',
      'config.yaml:\n  debug: true\n  port: 8080',
    );

    // 模拟另一个 exchange 展示不同的工具状态
    // 这个通过多次发送消息来展示
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
