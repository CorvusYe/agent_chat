// 队列模式演示 — 流式发送消息入队 → 自动排空
//
// 使用 ChatBus.withDecorators + 入队装饰器实现。
// 当 AI 流输出期间发送消息，消息自动入队等待。
// AI 流结束后自动排空队列中的下一条消息。
// 展示 queueItems / queueCount 等队列状态 API。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class QueueDemo extends StatefulWidget {
  const QueueDemo({super.key});

  @override
  State<QueueDemo> createState() => _QueueDemoState();
}

class _QueueDemoState extends State<QueueDemo> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    // 使用入队装饰器包装总线
    bus = ChatBus.withDecorators(
      impl: DefaultChatBus(onGenerate: _mockSlowAI, onInterrupt: () {}),
      decorators: [(inner) => _QueuedChatBus(inner)],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoQueue());
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  Future<void> _autoQueue() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // 发送第一条消息 — 启动流
    bus.sendMessage('第一个请求：分析数据');
    // 立即发送第二条 — 应入队
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    bus.sendMessage('第二个请求：生成报告');
    // 立即发送第三条 — 也应入队
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    bus.sendMessage('第三个请求：发送邮件');
  }

  /// 模拟较慢的 AI 响应 — 让队列有时间积累
  Stream<ExchangeEvent> _mockSlowAI(String text) async* {
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 'think');
    const thinkText = '正在处理请求…';
    for (var i = 0; i < thinkText.length; i += 2) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield ThinkingDelta(
        id,
        'think',
        thinkText.substring(0, (i + 2).clamp(0, thinkText.length)),
      );
    }
    yield ThinkingCompleted(id, 'think', thinkText);
    yield TokenCount(id, 85);

    await Future.delayed(const Duration(milliseconds: 800));

    yield ContentStarted(id, 'content');
    final reply = '请求已处理完成。';
    for (var i = 0; i < reply.length; i += 4) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield ContentDelta(
        id,
        'content',
        reply.substring(0, (i + 4).clamp(0, reply.length)),
      );
    }
    yield ContentCompleted(id, 'content', reply);
    yield TokenCount(id, reply.length);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}

/// 入队装饰器 — 流输出期间自动入队，流结束后自动排空
class _QueuedChatBus with ChangeNotifier implements ChatBus {
  final ChatBus _inner;
  final List<String> _queue = [];
  bool _wasStreaming = false;

  _QueuedChatBus(this._inner) {
    _inner.addListener(_onChanged);
  }

  void _onChanged() {
    if (_wasStreaming && !_inner.isStreaming) {
      _drain();
    }
    _wasStreaming = _inner.isStreaming;
    notifyListeners();
  }

  void _drain() {
    if (_queue.isNotEmpty) {
      _inner.sendMessage(_queue.removeAt(0));
    }
  }

  @override
  void sendMessage(String text) {
    if (_inner.isStreaming) {
      _queue.add(text);
      return;
    }
    if (_queue.isNotEmpty) {
      _inner.sendMessage(_queue.removeAt(0));
      _queue.add(text);
      return;
    }
    _inner.sendMessage(text);
  }

  @override
  List<Exchange> get exchanges => _inner.exchanges;
  @override
  bool get isLoadingHistory => _inner.isLoadingHistory;
  @override
  bool get isStreaming => _inner.isStreaming;
  @override
  List<String> get queueItems => _queue;
  @override
  int get queueCount => _queue.length;
  @override
  int get totalTokens => _inner.totalTokens;
  @override
  Duration? get elapsed => _inner.elapsed;
  @override
  int get activeExchangeCount => _inner.activeExchangeCount;

  @override
  void confirmTool(e, t, a) => _inner.confirmTool(e, t, a);
  @override
  void cancelTool(e, t) => _inner.cancelTool(e, t);
  @override
  void toggleQueue() => _inner.toggleQueue();
  @override
  void addTokens(int c) => _inner.addTokens(c);
  @override
  void acceptEvents(e, s) => _inner.acceptEvents(e, s);
  @override
  void init() => _inner.init();
  @override
  void dispose() {
    _inner.removeListener(_onChanged);
    _inner.dispose();
    try {
      super.dispose();
    } catch (_) {}
  }
}
