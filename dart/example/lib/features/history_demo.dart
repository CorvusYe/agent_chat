// 历史加载演示 — 模拟载入多轮对话历史
//
// 展示 ChatBus.exchanges 中存储的多条 Exchange 记录。
// 模拟已完成的对话历史，展示：
//   - 多轮对话历史渲染
//   - 不同 Exchange 状态（completed / cancelled / failed）
//   - 已批准和已取消的工具调用
//   - 思考 + 工具 + 内容的完整历史

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class HistoryDemo extends StatefulWidget {
  const HistoryDemo({super.key});

  @override
  State<HistoryDemo> createState() => _HistoryDemoState();
}

class _HistoryDemoState extends State<HistoryDemo> {
  late final _HistoryBus bus;

  @override
  void initState() {
    super.initState();
    bus = _HistoryBus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) bus.loadHistory();
      });
    });
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}

class _HistoryBus extends ChangeNotifier implements ChatBus {
  final List<Exchange> _exchanges = [];
  bool _loadingHistory = true;

  @override
  List<Exchange> get exchanges => List.unmodifiable(_exchanges);
  @override
  bool get isLoadingHistory => _loadingHistory;
  @override
  bool get isStreaming => false;
  @override
  List<String> get queueItems => [];
  @override
  int get queueCount => 0;
  @override
  int get totalTokens => 2845;
  @override
  Duration? get elapsed => const Duration(seconds: 47);
  @override
  int get activeExchangeCount => 0;

  void loadHistory() {
    // 模拟从持久化存储加载历史的延迟
    Future.delayed(const Duration(milliseconds: 800), () {
      _injectDemoHistory();
      _loadingHistory = false;
      notifyListeners();
    });
  }

  void _injectDemoHistory() {
    final now = DateTime.now();

    // 第1轮：完成 — 代码质量检查
    _exchanges.add(
      Exchange(
        id: 'hist_1',
        userMessage: '帮我检查代码质量',
        timestamp: now.subtract(const Duration(minutes: 12)),
        groups: [
          BlockGroup(
            id: 'g1',
            blocks: [
              ChatBlock(
                id: 'h1_think',
                type: BlockType.thinking,
                content: '分析中…',
                status: BlockStatus.completed,
              ),
              ChatBlock(
                id: 'h1_tool',
                type: BlockType.tool,
                toolName: 'analyze_code',
                toolArgs: {'target': 'src/'},
                toolResult: '发现 3 个问题',
                status: BlockStatus.completed,
              ),
              ChatBlock(
                id: 'h1_content',
                type: BlockType.content,
                content: '发现 2 个性能问题和 1 个安全漏洞。建议优先修复 SQL 注入。',
                status: BlockStatus.completed,
              ),
            ],
          ),
        ],
        status: ExchangeStatus.completed,
      ),
    );

    // 第2轮：完成 — 生成修复
    _exchanges.add(
      Exchange(
        id: 'hist_2',
        userMessage: '生成修复方案',
        timestamp: now.subtract(const Duration(minutes: 8)),
        groups: [
          BlockGroup(
            id: 'g2',
            blocks: [
              ChatBlock(
                id: 'h2_think',
                type: BlockType.thinking,
                content: '生成修复方案…',
                status: BlockStatus.completed,
              ),
              ChatBlock(
                id: 'h2_tool1',
                type: BlockType.tool,
                toolName: 'generate_patch',
                toolArgs: {'file': 'src/db/query.dart'},
                toolResult: 'patch 已生成',
                status: BlockStatus.completed,
              ),
              ChatBlock(
                id: 'h2_tool2',
                type: BlockType.tool,
                toolName: 'generate_patch',
                toolArgs: {'file': 'src/api/auth.dart'},
                toolResult: 'patch 已生成',
                status: BlockStatus.alwaysAllowed,
              ),
              ChatBlock(
                id: 'h2_content',
                type: BlockType.content,
                content: '已生成 2 个修复补丁，请审查后应用。',
                status: BlockStatus.completed,
              ),
            ],
          ),
        ],
        status: ExchangeStatus.completed,
      ),
    );

    // 第3轮：已取消 — 用户取消了操作
    _exchanges.add(
      Exchange(
        id: 'hist_3',
        userMessage: '执行危险操作',
        timestamp: now.subtract(const Duration(minutes: 4)),
        groups: [
          BlockGroup(
            id: 'g3',
            blocks: [
              ChatBlock(
                id: 'h3_think',
                type: BlockType.thinking,
                content: '需要确认操作…',
                status: BlockStatus.completed,
              ),
              ChatBlock(
                id: 'h3_tool',
                type: BlockType.tool,
                toolName: 'delete_all',
                toolArgs: {'confirm': true},
                requiresConfirm: true,
                status: BlockStatus.cancelled,
              ),
            ],
          ),
        ],
        status: ExchangeStatus.cancelled,
      ),
    );

    // 第4轮：失败 — API 超时
    _exchanges.add(
      Exchange(
        id: 'hist_4',
        userMessage: '分析大数据集',
        timestamp: now.subtract(const Duration(minutes: 2)),
        groups: [
          BlockGroup(
            id: 'g4',
            blocks: [
              ChatBlock(
                id: 'h4_think',
                type: BlockType.thinking,
                content: '正在连接数据服务…',
                status: BlockStatus.completed,
              ),
            ],
          ),
        ],
        status: ExchangeStatus.failed,
        errorMessage: 'API 调用超时，请稍后重试。',
      ),
    );
  }

  // ── ChatBus 方法（新消息走默认流程） ──
  @override
  void sendMessage(String text) {
    // 新消息由 DefaultChatBus 处理 — 使用静态实例
    _delegate.sendMessage(text);
  }

  final DefaultChatBus _delegate = DefaultChatBus(onGenerate: _liveMock);

  static Stream<ExchangeEvent> _liveMock(String text) async* {
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 't');
    yield ThinkingDelta(id, 't', '正在处理新消息…');
    await Future.delayed(const Duration(milliseconds: 200));
    yield ThinkingCompleted(id, 't', '正在处理新消息…');
    yield ContentStarted(id, 'c');
    const reply = '这是新的回复内容，追加在历史记录之后。';
    yield ContentDelta(id, 'c', reply);
    yield ContentCompleted(id, 'c', reply);
  }

  @override
  void confirmTool(String e, String t, bool a) =>
      _delegate.confirmTool(e, t, a);
  @override
  void cancelTool(String e, String t) => _delegate.cancelTool(e, t);
  @override
  void toggleQueue() {}
  @override
  void addTokens(int c) => _delegate.addTokens(c);
  @override
  void acceptEvents(String e, Stream<ExchangeEvent> s) =>
      _delegate.acceptEvents(e, s);
  @override
  void init() {}
  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }
}
