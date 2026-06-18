// 报错块演示 — ExchangeError / ExchangeStatus.failed
//
// 展示多种错误场景的 UI 表现：
//   - 主动 yield ExchangeError 触发失败状态
//   - 工具调用失败后报告错误
//   - 网络超时模拟

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class ErrorDemo extends StatefulWidget {
  const ErrorDemo({super.key});

  @override
  State<ErrorDemo> createState() => _ErrorDemoState();
}

class _ErrorDemoState extends State<ErrorDemo> {
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
    // 第1轮：正常完成 — 对比用
    bus.sendMessage('正常请求');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // 第2轮：工具调用失败
    bus.sendMessage('工具执行出错');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    // 第3轮：网络超时
    bus.sendMessage('超时错误');
  }

  Stream<ExchangeEvent> _mockStream(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    if (text == '正常请求') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '正常处理…');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '正常处理完成');
      yield ContentStarted(id, 'content');
      const reply = '这是正常的回复内容。';
      yield ContentDelta(id, 'content', reply);
      yield ContentCompleted(id, 'content', reply);
      yield TokenCount(id, 32);
      return;
    }

    if (text == '工具执行出错') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '正在调用工具…');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '工具执行遇到问题');

      yield ToolCallStarted(id, 'tool', 'analyze_repo', {
        'target': 'src/',
      }, autoApproved: true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (_cancelled) return;
      // 工具执行失败 → isError=true 自动触发 Exchange 失败态
      yield ToolCallCompleted(
        id,
        'tool',
        '✗ 分析失败: 目标仓库不存在或权限不足\n请检查仓库路径是否正确。',
        isError: true,
      );
      return;
    }

    if (text == '超时错误') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '正在连接远程服务…');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_cancelled) return;
      // 超时 → 直接报错（无工具调用，思考后超时）
      yield ExchangeError(
        id,
        '请求超时: 服务器无响应 (15s)\n\n可能的原因：\n'
        '  • 网络连接不稳定\n'
        '  • 服务器负载过高\n'
        '  • 防火墙拦截\n\n'
        '建议稍后重试或联系管理员。',
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}
