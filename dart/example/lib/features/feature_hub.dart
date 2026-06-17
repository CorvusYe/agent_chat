import 'package:flutter/material.dart';
import 'streaming_output.dart';
import 'tool_calls_demo.dart';
import 'confirmation_gate.dart';
import 'queue_demo.dart';
import 'input_modes.dart';
import 'history_demo.dart';
import 'custom_blocks_demo.dart';
import 'theme_gallery.dart';
import 'stats_demo.dart';
import 'custom_theme_demo.dart';
import 'code_drawer.dart';

/// 特性描述 — 含标题、说明、图标、构建器和对应 API 代码片段
class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  final List<CodeSnippet> snippets;
  const _Feature(
    this.title,
    this.subtitle,
    this.icon,
    this.builder,
    this.snippets,
  );
}

final _features = <_Feature>[
  _Feature(
    '流输出展示',
    '打字机效果的 thinking / content delta',
    Icons.text_fields,
    (_) => const StreamingOutputDemo(),
    [
      CodeSnippet(
        'DefaultChatBus.onGenerate',
        '// 核心 API：通过 onGenerate 回调返回事件流\n'
            'bus = DefaultChatBus(\n'
            '  onGenerate: (String text) async* {\n'
            '    // 1. 思考块 — 逐字 delta\n'
            '    yield ThinkingStarted(id, \'think_1\');\n'
            '    for (...) {\n'
            '      yield ThinkingDelta(id, \'think_1\', text);\n'
            '      await Future.delayed(Duration(milliseconds: 25));\n'
            '    }\n'
            '    yield ThinkingCompleted(id, \'think_1\', fullText);\n'
            '\n'
            '    // 2. 工具调用\n'
            '    yield ToolCallStarted(id, \'tool\', \'read_file\', args);\n'
            '    // ... 等待执行\n'
            '    yield ToolCallCompleted(id, \'tool\', result);\n'
            '\n'
            '    // 3. 内容输出 — 打字机效果\n'
            '    yield ContentStarted(id, \'content\');\n'
            '    for (...) {\n'
            '      yield ContentDelta(id, \'content\', chunk);\n'
            '      await Future.delayed(Duration(milliseconds: 16));\n'
            '    }\n'
            '    yield ContentCompleted(id, \'content\', fullText);\n'
            '\n'
            '    // 4. Token 统计\n'
            '    yield TokenCount(id, count);\n'
            '  },\n'
            ');',
      ),
      CodeSnippet(
        '事件流生命周期',
        'ExchangeEvent 事件类型：\n'
            '├─ ThinkingStarted / Delta / Completed  — 思考块\n'
            '├─ ToolCallStarted / Delta / Completed  — 工具调用\n'
            '├─ ContentStarted / Delta / Completed   — 内容输出\n'
            '├─ ParallelBoundary                     — 并行分组\n'
            '├─ TokenCount                           — 计 token\n'
            '├─ ExchangeError                        — 错误\n'
            '└─ CustomBlockEvent                     — 自定义块\n'
            '\n'
            'DefaultChatBus._processEventStream() 通过\n'
            'await for (final event in stream) 消费事件流，\n'
            '每收到事件就 notifyListeners() 触发 UI 更新。',
      ),
      CodeSnippet(
        '停止流输出 / 中断',
        '// 中断回调\n'
            'onInterrupt: () => _cancelled = true;\n'
            '\n'
            '// 在 async* 生成器中检查标志位\n'
            'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
            '  _cancelled = false;\n'
            '  for (...) {\n'
            '    if (_cancelled) return;  // ← 立即停止 yield\n'
            '    yield ThinkingDelta(...);\n'
            '  }\n'
            '}\n'
            '\n'
            '// ChatScreen 内部调用 bus.cancelTool() →\n'
            '// 触发 onInterrupt → _cancelled = true\n'
            '// → async* 函数 return → 流结束',
      ),
    ],
  ),
  _Feature(
    '工具调用展示',
    'ToolCall block 各状态渲染',
    Icons.build_circle,
    (_) => const ToolCallsDemo(),
    [
      CodeSnippet(
        'ToolCallStarted 参数',
        'yield ToolCallStarted(\n'
            '  exchangeId,          // 所属 exchange\n'
            '  blockId,             // 块唯一 ID\n'
            '  toolName,            // 工具名（如 read_file）\n'
            '  arguments,           // 参数 Map\n'
            '  requiresConfirm,     // 是否需要用户确认\n'
            '  autoApproved,        // 自动批准\n'
            '  description,         // 确认对话框描述\n'
            '  canAlwaysAllow,      // 是否显示"始终允许"\n'
            ');',
      ),
      CodeSnippet(
        'BlockStatus 状态机',
        'BlockStatus 枚举值：\n'
            '├─ pending         — 等待确认（确认门）\n'
            '├─ running         — 执行中\n'
            '├─ completed       — 已完成\n'
            '├─ cancelled       — 已取消\n'
            '├─ approved        — 已批准\n'
            '└─ alwaysAllowed   — 始终允许\n'
            '\n'
            'DefaultChatBus 自动管理状态转换：\n'
            ' - ToolCallStarted + requiresConfirm → pending\n'
            ' - 用户 confirmTool() → approved/running\n'
            ' - 用户 cancelTool()  → cancelled\n'
            ' - ToolCallCompleted → completed',
      ),
      CodeSnippet(
        'ParallelBoundary 分组',
        '// ParallelBoundary 将前面的 blocks 分为一组\n'
            '// 同组内 blocks 并行渲染（无序号前缀）\n'
            'yield ToolCallStarted(id, \'t1\', \'tool_a\', {});\n'
            'yield ToolCallStarted(id, \'t2\', \'tool_b\', {});\n'
            'yield ParallelBoundary(id);  // ← 打包 t1+t2 为同一组\n'
            '// 之后的 blocks 进入新组',
      ),
    ],
  ),
  _Feature(
    '确认门演示',
    '工具需确认时的对话框流程',
    Icons.gpp_maybe,
    (_) => const ConfirmationGateDemo(),
    [
      CodeSnippet(
        '确认门核心流程',
        '// 1. 发射需确认的工具\n'
            'yield ToolCallStarted(id, \'tool\', \'delete_file\',\n'
            '    {\'path\': \'/tmp/cache.db\'},\n'
            '    requiresConfirm: true,\n'
            '    description: \'将要删除缓存文件\',\n'
            '    canAlwaysAllow: true,  // 显示"始终允许"复选框\n'
            ');\n'
            '\n'
            '// 2. ChatScreen 检测 pending block → 弹出确认对话框\n'
            '// 3. 用户选择：\n'
            '//    - 批准 → bus.confirmTool(e, t, false)\n'
            '//              → status 变 approved → running\n'
            '//    - 拒绝 → bus.cancelTool(e, t)\n'
            '//              → status 变 cancelled\n'
            '//              → 触发 onInterrupt\n'
            '//    - 始终允许 → bus.confirmTool(e, t, true)\n'
            '//                 → 加入信任列表\n'
            '//                 → 后续同工具跳过确认',
      ),
      CodeSnippet(
        '信任列表机制',
        '// DefaultChatBus 内部维护 _trustedTools 集合。\n'
            '// 当用户选择"始终允许"时，该工具名加入信任列表：\n'
            '_trustedTools.add(toolName);\n'
            '// 后续同名的 ToolCallStarted 检查信任列表：\n'
            'final autoApproved = e.autoApproved\n'
            '    || _trustedTools.contains(e.toolName);\n'
            '// 命中 → 跳过确认门，直接进入 running 状态',
      ),
    ],
  ),
  _Feature('队列模式', '流式发送消息入队 → 自动排空', Icons.queue, (_) => const QueueDemo(), [
    CodeSnippet(
      'ChatBus.withDecorators',
      '// 用装饰器模式增强 ChatBus：\n'
          'bus = ChatBus.withDecorators(\n'
          '  impl: DefaultChatBus(onGenerate: _mockAI),\n'
          '  decorators: [\n'
          '    (inner) => _QueueDecorator(inner),\n'
          '  ],\n'
          ');\n'
          '\n'
          '// 装饰器实现要点：\n'
          'class _QueueDecorator with ChangeNotifier\n'
          '    implements ChatBus {\n'
          '  final List<String> _queue = [];\n'
          '  bool _wasStreaming = false;\n'
          '\n'
          '  void _onChanged() {\n'
          '    if (_wasStreaming && !inner.isStreaming) {\n'
          '      _drain();  // 流结束 → 排空\n'
          '    }\n'
          '    _wasStreaming = inner.isStreaming;\n'
          '    notifyListeners();\n'
          '  }\n'
          '\n'
          '  void sendMessage(String text) {\n'
          '    if (inner.isStreaming) {\n'
          '      _queue.add(text);  // 入队\n'
          '      return;\n'
          '    }\n'
          '    inner.sendMessage(text);\n'
          '  }\n'
          '}',
    ),
    CodeSnippet(
      '队列状态 API',
      'ChatBus 队列相关 getter：\n'
          '├─ queueItems: List<String>   — 队列中的消息\n'
          '├─ queueCount: int            — 队列长度\n'
          '└─ isStreaming: bool          — 是否正在流输出\n'
          '\n'
          'ChatScreen 内置队列弹窗展示 queueItems，\n'
          '通过 StatsBar 上的按钮触发 toggleQueue() 显示。',
    ),
  ]),
  _Feature(
    '输入组件',
    'ChatInput 多种按钮配置',
    Icons.keyboard,
    (_) => const InputModesDemo(),
    [
      CodeSnippet(
        'ChatScreen 参数',
        'ChatScreen(\n'
            '  bus: bus,                    // 必需：ChatBus\n'
            '  theme: myChatTheme,          // 可选：自定义 ChatTheme\n'
            '  loadingIndicator: ...,       // 可选：加载中视图\n'
            '  emptyPlaceholder: ...,       // 可选：空列表视图\n'
            ')\n'
            '\n'
            'ChatScreen 内部构建了完整的聊天 UI：\n'
            '├─ 消息列表（CustomScrollView + Sliver）\n'
            '├─ 输入框（AutoResizeTextField）\n'
            '├─ StatsBar\n'
            '└─ 队列弹窗',
      ),
      CodeSnippet(
        '输入框核心属性',
        'AutoResizeTextField(\n'
            '  controller,   // TextEditingController\n'
            '  hintText,     // 占位提示\n'
            '  onChanged,    // 文本变化回调\n'
            ')\n'
            '\n'
            '自动调整高度的多行输入框，支持：\n'
            ' - Enter 发送、Shift+Enter 换行\n'
            ' - 自适应高度（minLines / maxLines）\n'
            ' - 发送按钮 + 可选队列/Token 按钮',
      ),
    ],
  ),
  _Feature('历史加载', '模拟载入多轮对话历史', Icons.history, (_) => const HistoryDemo(), [
    CodeSnippet(
      'Exchange 模型',
      'Exchange(\n'
          '  id: \'ex_001\',            // 唯一 ID\n'
          '  userMessage: \'你好\',     // 用户消息\n'
          '  timestamp: DateTime.now(),\n'
          '  groups: [                  // BlockGroup 列表\n'
          '    BlockGroup(id: \'g1\', blocks: [\n'
          '      ChatBlock(id: \'b1\', type: BlockType.thinking,\n'
          '          content: \'思考中…\',\n'
          '          status: BlockStatus.completed),\n'
          '      ChatBlock(id: \'b2\', type: BlockType.content,\n'
          '          content: \'回复内容\',\n'
          '          status: BlockStatus.completed),\n'
          '    ]),\n'
          '  ],\n'
          '  status: ExchangeStatus.completed,\n'
          '  errorMessage: null,        // 失败时设置\n'
          ')\n'
          '\n'
          'ExchangeStatus: completed / processing /\n'
          '                  waitingInput / cancelled / failed',
    ),
    CodeSnippet(
      'ChatBus.exchanges',
      '// 只读的历史记录列表\n'
          'List<Exchange> get exchanges;\n'
          '\n'
          '// 新消息通过 sendMessage() 添加，\n'
          '// DefaultChatBus 自动创建 Exchange\n'
          '// 并追加到 _exchanges 列表。\n'
          '\n'
          '// isLoadingHistory 控制加载状态\n'
          'bool get isLoadingHistory;\n'
          '// → true 时 ChatScreen 显示 loadingIndicator\n'
          '// → false 时显示正常消息列表',
    ),
  ]),
  _Feature(
    '自定义块',
    'CustomBlock + BlockRegistry',
    Icons.widgets,
    (_) => const CustomBlocksDemo(),
    [
      CodeSnippet(
        'BlockRegistry 注册',
        '// 1. 注册自定义块类型\n'
            'BlockRegistry.registerCustom(\n'
            '  \'code_snippet\',          // 类型名称\n'
            '  _buildCodeSnippet,       // Widget builder\n'
            ');\n'
            '\n'
            '// 2. 注册样式（可选）\n'
            'BlockRegistry.registerStyle(\n'
            '  \'code_snippet\',\n'
            '  BlockStyle(\n'
            '    icon: Icons.code,\n'
            '    dotColor: Color(0xFF7C3AED),\n'
            '    headerColor: Color(0xFF7C3AED),\n'
            '    label: \'代码片段\',\n'
            '  ),\n'
            ');\n'
            '\n'
            '// Widget builder 签名：\n'
            'typedef CustomBlockBuilder = Widget Function(\n'
            '  BuildContext context,\n'
            '  ChatBlock block,\n'
            '  ChatBus bus,\n'
            '  Exchange exchange,\n'
            ');',
      ),
      CodeSnippet(
        'CustomBlockEvent 发射',
        '// 在事件流中发送自定义块\n'
            'yield CustomBlockEvent(\n'
            '  exchangeId,\n'
            '  \'code_1\',\n'
            '  \'code_snippet\',                // 对应 registerCustom 的名称\n'
            '  content: \'...代码内容...\',\n'
            '  label: \'hello.dart\',          // 显示标题\n'
            '  status: BlockStatus.completed,\n'
            '  metadata: {\'language\': \'dart\'},\n'
            ');\n'
            '\n'
            '// DefaultChatBus 处理流程：\n'
            '// CustomBlockEvent → 创建 ChatBlock(\n'
            '//   type: BlockType.custom(typeName)\n'
            '// ) → 追加到 pendingBlocks\n'
            '// → notifyListeners → UI 渲染',
      ),
    ],
  ),
  _Feature(
    '主题画廊',
    '暗色/亮色/内置 ChatTheme 切换',
    Icons.palette,
    (_) => const ThemeGallery(),
    [
      CodeSnippet(
        'ChatTheme 结构',
        'ChatTheme 是 ThemeExtension<ChatTheme>，\n'
            '包含 ~70 个属性分 8 类：\n'
            '├─ 背景色  — bgPrimary / bgSurface / bgCard …\n'
            '├─ 文字色  — textPrimary / textContent …\n'
            '├─ 强调色  — accent / accentHover / success / error\n'
            '├─ 边框色  — border / borderLight / borderAccent\n'
            '├─ 状态点  — dotThinking / dotTool / dotContent\n'
            '├─ 间距    — spacingXs ~ spacingXl / blockPadding\n'
            '├─ 圆角    — radiusSm ~ radiusXl\n'
            '└─ 动画    — breathingDuration / rotationDuration',
      ),
      CodeSnippet(
        'ThemeData 注册',
        '// 将 ChatTheme 注册为 ThemeExtension：\n'
            'MaterialApp(\n'
            '  theme: ThemeData(\n'
            '    brightness: Brightness.light,\n'
            '    extensions: [ChatThemes.fluent],  // ← 亮色用\n'
            '  ),\n'
            '  darkTheme: ThemeData(\n'
            '    brightness: Brightness.dark,\n'
            '    extensions: [ChatThemes.fluentDark],  // ← 暗色用\n'
            '  ),\n'
            ')\n'
            '\n'
            'ChatScreen 通过 ChatTheme.of(context) 获取：\n'
            'return Theme.of(context).extension<ChatTheme>()\n'
            '    ?? _fallback;',
      ),
      CodeSnippet(
        '内置主题',
        'ChatThemes 提供了 3 个内置主题：\n'
            '├─ ChatThemes.fluent      — Fluent 2 浅色\n'
            '├─ ChatThemes.fluentDark  — Fluent 2 暗色\n'
            '└─ ChatThemes.dark        — 默认暗色（紫色调）\n'
            '\n'
            '你也可以用 ChatTheme(...) 构造任意自定义主题。',
      ),
    ],
  ),
  _Feature(
    '自定义主题',
    '动态创建 ChatTheme 实时预览',
    Icons.colorize,
    (_) => const CustomThemeDemo(),
    [
      CodeSnippet(
        'ChatTheme 构造函数',
        '// 从零构建 ChatTheme：\n'
            'final myTheme = ChatTheme(\n'
            '  bgPrimary: Color(0xFF1a1a2e),\n'
            '  bgSurface: Color(0xFF2d3a5e),\n'
            '  bgCard: Color(0x05FFFFFF),\n'
            '  bgInput: Color(0x0AFFFFFF),\n'
            '  textPrimary: Color(0xFFe0e0e0),\n'
            '  textContent: Color(0xFFe2e8f0),\n'
            '  textSecondary: Color(0xFF94a3b8),\n'
            '  accent: Color(0xFF3b82f6),\n'
            '  border: Color(0x1FFFFFFF),\n'
            '  // ... 共 ~50+ 个命名参数\n'
            ');',
      ),
      CodeSnippet(
        'Theme 局部覆盖',
        '// 用 Theme widget 为子树覆盖 ChatTheme：\n'
            'Theme(\n'
            '  data: ThemeData(\n'
            '    brightness: Brightness.dark,\n'
            '    extensions: [myCustomChatTheme],\n'
            '  ),\n'
            '  child: ChatScreen(bus: bus),\n'
            ')\n'
            '\n'
            '// ChatTheme 配合 Color.lerp 可推导衍生色：\n'
            'final surface = Color.lerp(bgPrimary, white, 0.08)!;\n'
            'final textSec  = Color.lerp(textPrimary, white, 0.4)!;',
      ),
    ],
  ),
  _Feature(
    '统计栏',
    'Token 计数 / 耗时显示',
    Icons.bar_chart,
    (_) => const StatsDemo(),
    [
      CodeSnippet(
        'StatsBar 指标',
        'StatsBar 展示 ChatBus 的统计信息：\n'
            '├─ totalTokens: int         — 累计 Token\n'
            '├─ elapsed: Duration?       — 当前/上次会话耗时\n'
            '├─ queueCount: int          — 队列长度\n'
            '├─ activeExchangeCount: int — 活跃 Exchange 数\n'
            '└─ isLoadingHistory: bool   — 是否正在加载历史\n'
            '\n'
            '使用方法：\n'
            'StatsBar(totalTokens: bus.totalTokens)\n'
            '// 自动监听 bus 变化更新显示',
      ),
      CodeSnippet(
        'Token 计数机制',
        '// 在事件流中发射 Token：\n'
            'yield TokenCount(id, 156);  // 累加到 totalTokens\n'
            '\n'
            '// 编程式增加：\n'
            'bus.addTokens(100);\n'
            '\n'
            '// 读取：\n'
            'int get totalTokens => _totalTokens;\n'
            '\n'
            '// 计时：\n'
            '// DefaultChatBus 在首个 Exchange 开始时\n'
            '// 记录 _startTime，流结束时记录 _lastElapsed\n'
            'Duration? get elapsed => _startTime != null\n'
            '    ? DateTime.now().difference(_startTime!)\n'
            '    : _lastElapsed;',
      ),
    ],
  ),
];

class FeatureHub extends StatefulWidget {
  const FeatureHub({super.key});

  @override
  State<FeatureHub> createState() => _FeatureHubState();
}

class _FeatureHubState extends State<FeatureHub> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final feature = _features[_current];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.code),
              tooltip: '查看 API 代码',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agent Chat',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '特性展示',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withAlpha(
                          179,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _features.length,
                  itemBuilder: (_, i) {
                    final f = _features[i];
                    final selected = i == _current;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: theme.colorScheme.primaryContainer
                          .withAlpha(77),
                      leading: Icon(
                        f.icon,
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        f.title,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: Text(
                        f.subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        setState(() => _current = i);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: CodeDrawer(
        snippets: feature.snippets,
        featureName: feature.title,
      ),
      body: _features[_current].builder(context),
    );
  }
}
