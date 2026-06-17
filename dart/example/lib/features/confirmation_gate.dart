// 确认门演示 — 工具需确认时的对话框流程
//
// 展示 requiresConfirm=true 时 ChatScreen 的确认门交互：
//   - 弹出确认对话框（"允许/拒绝/始终允许"）
//   - 批准后工具继续执行
//   - 拒绝后工具被取消
//   - "始终允许" 记录到信任列表，后续同工具跳过确认

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class ConfirmationGateDemo extends StatefulWidget {
  const ConfirmationGateDemo({super.key});

  @override
  State<ConfirmationGateDemo> createState() => _ConfirmationGateDemoState();
}

class _ConfirmationGateDemoState extends State<ConfirmationGateDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockConfirmStream,
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
    bus.sendMessage('测试工具确认门流程');
    // 第二次发送演示"始终允许"
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    bus.sendMessage('再次触发需要确认的工具');
  }

  Stream<ExchangeEvent> _mockConfirmStream(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 'think');
    yield ThinkingDelta(id, 'think', '正在准备操作…');
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think', '需要执行以下操作：');

    // ── 需要用户确认的删除操作 ──
    yield ToolCallStarted(
      id,
      'tool_delete',
      'delete_file',
      {'path': '/tmp/cache.db'},
      requiresConfirm: true,
      description: '将要删除缓存文件',
      canAlwaysAllow: true,
    );
    // ── 另一个需确认的操作 ──
    yield ToolCallStarted(
      id,
      'tool_exec',
      'execute_command',
      {'cmd': 'rm -rf ./build/'},
      requiresConfirm: true,
      description: '将要执行清理命令',
      canAlwaysAllow: true,
    );
    yield ParallelBoundary(id);

    // 等待用户确认/拒绝 — ChatScreen 会暂停在这里
    // 确认后继续执行
    await Future.delayed(const Duration(milliseconds: 800));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tool_delete', '✓ 文件已删除');
    await Future.delayed(const Duration(milliseconds: 400));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tool_exec', '✓ 清理完成，释放 245 MB');

    yield TokenCount(id, 42);

    // 最终回答
    yield ParallelBoundary(id);
    yield ContentStarted(id, 'content');
    const reply = '操作已完成。';
    yield ContentDelta(id, 'content', reply);
    yield ContentCompleted(id, 'content', reply);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
