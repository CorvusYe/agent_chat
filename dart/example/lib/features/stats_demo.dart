// 统计栏演示 — Token 计数 / 耗时显示
//
// 展示 StatsBar widget 的多项统计指标：
//   - totalTokens：累计 Token 消耗
//   - elapsed：当前 / 上次会话耗时
//   - queueCount：队列中待处理消息数
//   - activeExchangeCount：正在处理的活跃 Exchange 数
//   - isLoadingHistory：历史加载状态提示

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class StatsDemo extends StatefulWidget {
  const StatsDemo({super.key});

  @override
  State<StatsDemo> createState() => _StatsDemoState();
}

class _StatsDemoState extends State<StatsDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockWithStats,
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

    // 模拟已有一些统计数据
    bus.addTokens(1234);

    bus.sendMessage('查看统计信息');
  }

  Stream<ExchangeEvent> _mockWithStats(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 't');
    const thinkText = '统计信息展示中…\n请观察底部的 StatsBar 变化。';
    for (var i = 0; i < thinkText.length; i += 6) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_cancelled) return;
      yield ThinkingDelta(
        id,
        't',
        thinkText.substring(0, (i + 6).clamp(0, thinkText.length)),
      );
    }
    if (_cancelled) return;
    yield ThinkingCompleted(id, 't', thinkText);
    yield TokenCount(id, 156);

    // 工具调用
    yield ToolCallStarted(id, 'tc_1', 'heavy_analysis', {'mode': 'full'});
    await Future.delayed(const Duration(milliseconds: 600));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tc_1', '✓ 分析完成');

    yield ToolCallStarted(id, 'tc_2', 'data_export', {'format': 'json'});
    await Future.delayed(const Duration(milliseconds: 400));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tc_2', '✓ 导出完成');

    yield ParallelBoundary(id);

    // 内容
    yield ContentStarted(id, 'c');
    const reply = 'StatsBar 展示了 token 计数、耗时等实时统计信息。';
    for (var i = 0; i < reply.length; i += 3) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (_cancelled) return;
      yield ContentDelta(
        id,
        'c',
        reply.substring(0, (i + 3).clamp(0, reply.length)),
      );
    }
    yield ContentCompleted(id, 'c', reply);
    yield TokenCount(id, reply.length);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
