import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = ChatBus.withDecorators(
      impl: DefaultChatBus(onGenerate: _mockAI, onInterrupt: _onInterrupt),
      decorators: [(inner) => _QueueInputDecorator(inner)],
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDemo());
  }

  void _onInterrupt() {
    _aiCancelled = true;
  }

  Future<void> _autoDemo() async {
    await Future.delayed(const Duration(milliseconds: 800));
    bus.sendMessage('帮我分析一下后端项目的代码质量');
    await _waitIdle();
    bus.sendMessage('数据库查询性能检查');
    await _waitIdle();
    bus.sendMessage('写一份 API 设计文档');
  }

  Future<void> _waitIdle() async {
    while (bus.isStreaming) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    // extra settle time
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agent Chat',
      theme: ThemeData(brightness: Brightness.dark),
      home: ChatScreen(bus: bus),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  QueueInputDecorator — 流中发送自动入队，流结束自动排空
// ═══════════════════════════════════════════════════════

class _QueueInputDecorator with ChangeNotifier implements ChatBus {
  final ChatBus _inner;
  final List<String> _pendingQueue = [];
  bool _wasStreaming = false;

  _QueueInputDecorator(this._inner) {
    _inner.addListener(_onInnerChanged);
  }

  void _onInnerChanged() {
    if (_wasStreaming && !_inner.isStreaming) {
      _drainQueue();
    }
    _wasStreaming = _inner.isStreaming;
    notifyListeners();
  }

  void _drainQueue() {
    if (_pendingQueue.isNotEmpty) {
      _inner.sendMessage(_pendingQueue.removeAt(0));
    }
  }

  @override
  List<Exchange> get exchanges => _inner.exchanges;
  @override
  bool get isLoadingHistory => _inner.isLoadingHistory;
  @override
  bool get isStreaming => _inner.isStreaming;
  @override
  List<String> get queueItems => _pendingQueue;
  @override
  int get queueCount => _pendingQueue.length;
  @override
  int get totalTokens => _inner.totalTokens;
  @override
  Duration? get elapsed => _inner.elapsed;
  @override
  int get activeExchangeCount => _inner.activeExchangeCount;

  @override
  void sendMessage(String text) {
    if (_inner.isStreaming) {
      _pendingQueue.add(text);
      return;
    }
    // Not streaming: consume one pending first, then enqueue the new one
    if (_pendingQueue.isNotEmpty) {
      _inner.sendMessage(_pendingQueue.removeAt(0));
      _pendingQueue.add(text);
      return;
    }
    _inner.sendMessage(text);
  }

  @override
  void confirmTool(exchangeId, toolName, alwaysAllow) =>
      _inner.confirmTool(exchangeId, toolName, alwaysAllow);
  @override
  void cancelTool(exchangeId, toolName) =>
      _inner.cancelTool(exchangeId, toolName);
  @override
  void toggleQueue() => _inner.toggleQueue();
  @override
  void addTokens(int count) => _inner.addTokens(count);
  @override
  void acceptEvents(exchangeId, events) =>
      _inner.acceptEvents(exchangeId, events);
  @override
  void init() => _inner.init();
  @override
  void dispose() {
    _inner.removeListener(_onInnerChanged);
    _inner.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
//  Mock AI — 模拟 AI 事件流
// ═══════════════════════════════════════════════════════

final _rand = Random(42);
bool _aiCancelled = false;
final _toolPool = <_ToolEntry>[
  _ToolEntry(
    'read_file',
    {'path': 'src/app.dart'},
    'import { defineComponent } from "vue";\n\nexport function initApp() { ... }',
    false,
  ),
  _ToolEntry(
    'grep_files',
    {'pattern': 'TODO'},
    'src/main.js:15:  // TODO: handle error\nsrc/utils.js:42:  // TODO: optimize',
    false,
  ),
  _ToolEntry(
    'execute_command',
    {'cmd': 'npm run build'},
    '✓ built in 2.3s',
    true,
  ),
  _ToolEntry(
    'analysis',
    {'target': 'src/db/query.js:42'},
    '检测到 SQL 拼接语句，存在注入风险。\n等级: 高危',
    true,
  ),
];

class _ToolEntry {
  final String name;
  final Map<String, dynamic> args;
  final String result;
  final bool requiresConfirm;
  const _ToolEntry(this.name, this.args, this.result, this.requiresConfirm);
}

Stream<ExchangeEvent> _mockAI(String text) async* {
  _aiCancelled = false;
  final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

  // 1. 思考
  yield ThinkingStarted(id, 'think_1');
  const thinkText = '好的，让我来分析你的请求……';
  for (var i = 0; i < thinkText.length; i += 4) {
    await Future.delayed(const Duration(milliseconds: 20));
    if (_aiCancelled) return;
    yield ThinkingDelta(
      id,
      'think_1',
      thinkText.substring(
        0,
        i + 4 > thinkText.length ? thinkText.length : i + 4,
      ),
    );
  }
  if (_aiCancelled) return;
  yield ThinkingCompleted(id, 'think_1', thinkText);
  yield TokenCount(id, 156);

  // 2. 随机 1~3 个工具（同一并行组）
  final toolCount = _rand.nextInt(3) + 1;
  final used = <int>{};
  for (var i = 0; i < toolCount; i++) {
    var idx = _rand.nextInt(_toolPool.length);
    while (used.contains(idx)) {
      idx = _rand.nextInt(_toolPool.length);
    }
    used.add(idx);
    final entry = _toolPool[idx];
    if (_aiCancelled) return;
    yield ToolCallStarted(
      id,
      'tool_$i',
      entry.name,
      entry.args,
      requiresConfirm: entry.requiresConfirm,
      description: entry.requiresConfirm ? '将要执行以下命令' : null,
    );
  }
  if (_aiCancelled) return;
  yield ParallelBoundary(id);
  yield TokenCount(id, toolCount * 89);

  // 模拟工具执行（并行效果的延时）
  final usedList = used.toList();
  for (var i = 0; i < toolCount; i++) {
    await Future.delayed(Duration(milliseconds: 400 + _rand.nextInt(1000)));
    if (_aiCancelled) return;
    yield ToolCallCompleted(id, 'tool_$i', _toolPool[usedList[i]].result);
  }

  // 3. 回答
  if (_aiCancelled) return;
  yield ContentStarted(id, 'content_1');
  const reply = '以上是执行结果。如果需要进一步处理请告诉我。';
  for (var i = 0; i < reply.length; i += 3) {
    await Future.delayed(const Duration(milliseconds: 15));
    if (_aiCancelled) return;
    yield ContentDelta(
      id,
      'content_1',
      reply.substring(0, i + 3 > reply.length ? reply.length : i + 3),
    );
  }
  if (_aiCancelled) return;
  yield ContentCompleted(id, 'content_1', reply);
  yield TokenCount(id, 234);
}
