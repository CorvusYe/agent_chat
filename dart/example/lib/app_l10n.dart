import 'package:flutter/widgets.dart';
import 'features/code_drawer.dart';
import 'features/code_snippets_en.dart';
import 'features/code_snippets_zh_hant.dart';

/// 示例应用专属的国际化字符串。
///
/// 不包含 agent_chat 库本身的字符串（由 ChatL10n 提供）。
@immutable
abstract class AppL10n {
  const AppL10n();

  // ── Drawer / Hub header ──

  /// App 标题。
  String get appTitle;

  /// Drawer 副标题。
  String get appSubtitle;

  /// "查看 API 代码" 按钮 tooltip。
  String get viewApiCode;

  // ── Code drawer ──

  /// "核心接口调用"。
  String get coreApiLabel;

  /// 代码抽屉标题，例如 "StreamingOutput — API"。
  String codeDrawerTitle(String featureName);

  // ── Locale switcher ──

  /// 当前语言名称（用于按钮显示）。
  String get currentLocaleName;

  /// 切换语言 tooltip。
  String get switchLocale;

  // ── Theme gallery ──

  /// 亮色。
  String get light;

  /// 暗色。
  String get dark;

  /// "切换配色" tooltip。
  String get switchColor;

  /// ChatTheme 下拉标签。
  String get chatThemeLabel;

  /// 内置 ChatTheme 名称 — Fluent / 默认 / Neumorphism。
  String get themeFluent;
  String get themeDefault;
  String get themeNeumorphism;

  /// 配色名称。
  String colorName(String key);

  // ── Input modes tabs ──

  /// Tab: 默认 / + Queue / + Token / 纯文本
  String get inputDefault;
  String get inputQueue;
  String get inputToken;
  String get inputTextOnly;

  /// "仅展示 TextField 输入"
  String get textFieldOnlyHint;

  // ── Feature titles (drawer list) ──

  /// 13 个特性的标题。
  List<String> get featureTitles;

  /// 13 个特性的副标题。
  List<String> get featureSubtitles;

  /// 每个特性的代码示例（按 feature index 索引）。
  List<List<CodeSnippet>> get featureSnippets;

  // ── Custom theme demo ──

  /// "macOS Neumorphism" 面板标题。
  String get themeDemoTitle;

  /// Neumorphism 图标按钮 tooltip。
  String get neuTooltip;

  // ── ChatTheme names (highlight in main.dart) ──

  /// 三个内置 ChatTheme 名称列表：Fluent / 默认 / Neumorphism。
  List<String> get chatThemeNames;

  // ── Built-in instances ──

  static const AppL10n zhHans = _AppL10nZhHans();
  static const AppL10n zhHant = _AppL10nZhHant();
  static const AppL10n en = _AppL10nEn();

  /// 优先通过 [scriptCode]（Hans/Hant）区分简繁体，降级兼容 countryCode。
  static AppL10n fromLocale(Locale locale) {
    if (locale.languageCode == 'en') return en;
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') return zhHant;
      if (locale.countryCode == 'TW' ||
          locale.countryCode == 'HK' ||
          locale.countryCode == 'MO') {
        return zhHant;
      }
      return zhHans;
    }
    return zhHans;
  }

  static AppL10n of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppL10nScope>();
    return scope?.l10n ?? zhHans;
  }
}

class AppL10nScope extends InheritedWidget {
  final AppL10n l10n;
  const AppL10nScope({super.key, required this.l10n, required super.child});

  @override
  bool updateShouldNotify(AppL10nScope old) => old.l10n != l10n;
}

// ── zh_CN ──

class _AppL10nZhHans extends AppL10n {
  const _AppL10nZhHans();

  @override
  String get appTitle => 'Agent Chat';
  @override
  String get appSubtitle => '特性展示';
  @override
  String get viewApiCode => '查看 API 代码';
  @override
  String get coreApiLabel => '核心接口调用';
  @override
  String codeDrawerTitle(String name) => '$name — API';
  @override
  String get light => '亮色';
  @override
  String get dark => '暗色';
  @override
  String get switchColor => '切换配色';
  @override
  String get chatThemeLabel => 'ChatTheme';
  @override
  String get themeFluent => 'Fluent';
  @override
  String get themeDefault => '默认';
  @override
  String get themeNeumorphism => 'Neumorphism';

  @override
  String colorName(String key) {
    const names = <String, String>{
      'teal': 'teal',
      'indigo': 'indigo',
      'purple': 'purple',
      'orange': 'orange',
      'blue grey': 'blue grey',
      'pink': 'pink',
    };
    return names[key] ?? key;
  }

  @override
  String get currentLocaleName => '中文';
  @override
  String get switchLocale => '切换语言';
  @override
  String get inputDefault => '默认';
  @override
  String get inputQueue => '+ 队列按钮';
  @override
  String get inputToken => '+ Token 按钮';
  @override
  String get inputTextOnly => '纯文本';
  @override
  String get textFieldOnlyHint => '仅展示 TextField 输入';

  @override
  List<String> get featureTitles => const [
    '流输出展示',
    '工具调用展示',
    '确认门演示',
    '报错块展示',
    '队列模式',
    '输入组件',
    '历史加载',
    '自定义块',
    '主题画廊',
    '自定义主题',
    '展开/折叠控制',
    '统计栏',
    '自定义语言',
  ];

  @override
  List<String> get featureSubtitles => const [
    '打字机效果的 thinking / content delta',
    'ToolCall block 各状态渲染',
    '工具需确认时的对话框流程',
    'ExchangeError / 失败状态渲染',
    '流式发送消息入队 → 自动排空',
    'ChatInput 多种按钮配置',
    '模拟载入多轮对话历史',
    'CustomBlock + BlockRegistry',
    '暗色/亮色/内置 ChatTheme 切换',
    '动态创建 ChatTheme 实时预览',
    'ExchangeEvent 控制块可见性',
    'Token 计数 / 耗时显示',
    'ChatL10n 继承 + Scope 注入',
  ];

  @override
  List<List<CodeSnippet>> get featureSnippets => [
    // ── 0: 流输出展示 ──
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
            '    //        isError: true  → 红色错误风格\n'
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
    // ── 1: 工具调用展示 ──
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
            ' - ToolCallCompleted           → completed\n'
            ' - ToolCallCompleted(isError)  → completed + exchange failed\n'
            ' - ExchangeError               → exchange failed + 错误块',
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
    // ── 2: 确认门演示 ──
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
      CodeSnippet(
        '按钮风格（主题控制）',
        '确认门按钮通过 ChatTheme 控制样式：\n'
            '\n'
            'smallButtonHeight    — 按钮高度（默认 24px）\n'
            'radiusSm             — 按钮圆角（默认 2px）\n'
            'fontSizeSm           — 按钮字号（默认 12px）\n'
            'buttonPadding        — 按钮内边距\n'
            'accent               — 允许/始终允许按钮色\n'
            'textSecondary        — 取消按钮文字色\n'
            '\n'
            '暗色模式下 filled 按钮文字为深色 #1A1A1A，\n'
            '亮色模式下为白色。描边按钮文字 = accent 色，\n'
            '边框 = accent 色 39% 透明度。',
      ),
    ],
    // ── 3: 报错块展示 ──
    [
      CodeSnippet(
        'yield ExchangeError',
        '// 在事件流中直接 yield ExchangeError：\n'
            '\n'
            'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
            '  yield ThinkingStarted(id, \'think\');\n'
            '  // ...\n'
            '  if (somethingWrong) {\n'
            '    yield ExchangeError(\n'
            '      id,                               // exchangeId\n'
            '      \'分析失败: 目标仓库不存在\\n\'         // 错误消息\n'
            '      \'请检查路径是否正确。\'\n'
            '    );\n'
            '    return;  // ← 必须 return，流不再继续\n'
            '  }\n'
            '  // ... 正常流程\n'
            '}',
      ),
      CodeSnippet(
        '失败态触发机制',
        '目前有两种方式触发 Exchange 失败态：\n'
            '\n'
            '// 方式A：ExchangeError（显示错误块）\n'
            'yield ExchangeError(id, \'消息…\');\n'
            '→ 设 status=failed + errorMessage\n'
            '→ ChatScreen 渲染"错误"头部 + 错误消息\n'
            '→ 折叠时头部后显示消息摘要（新增）\n'
            '\n'
            '// 方式B：ToolCallCompleted(isError)（工具变红）\n'
            'yield ToolCallCompleted(id, \'tool\', \'✗ 错误…\',\n'
            '    isError: true);\n'
            '→ 设 status=failed，不设 errorMessage\n'
            '→ 工具块以红色边框/文字显示错误结果\n'
            '→ 不额外渲染错误块（避免信息重复）\n'
            '\n'
            '// 两种方式均触发块级错误风格：\n'
            '// _isFailed(exchange) → thinking/tool/content\n'
            '// 所有 block 文字变为 theme.error 红色',
      ),
    ],
    // ── 4: 队列模式 ──
    [
      CodeSnippet(
        '完整队列装饰器源码',
        'class _QueueDecorator with ChangeNotifier\n'
            '    implements ChatBus {\n'
            '  final ChatBus _inner;\n'
            '  final List<String> _queue = [];\n'
            '  bool _wasStreaming = false;\n'
            '\n'
            '  _QueueDecorator(this._inner) {\n'
            '    _inner.addListener(_onChanged);  // ① 监听流状态\n'
            '  }\n'
            '\n'
            '  // ── ② 流状态变化时自动排空 ──\n'
            '  void _onChanged() {\n'
            '    // 流从"正在输出"→"输出结束"的瞬间\n'
            '    if (_wasStreaming && !_inner.isStreaming) {\n'
            '      _drain();  // ③ 排空队列中的下一条\n'
            '    }\n'
            '    _wasStreaming = _inner.isStreaming;\n'
            '    notifyListeners();\n'
            '  }\n'
            '\n'
            '  // ── ③ 排空：取下一条发送 ──\n'
            '  void _drain() {\n'
            '    if (_queue.isNotEmpty) {\n'
            '      _inner.sendMessage(_queue.removeAt(0));\n'
            '      // drain 只发一条，发完下一轮 _onChanged\n'
            '      // 再触发下一次 drain，直到队列清空\n'
            '    }\n'
            '  }\n'
            '\n'
            '  // ── ④ sendMessage：拦截入队逻辑 ──\n'
            '  @override\n'
            '  void sendMessage(String text) {\n'
            '    if (_inner.isStreaming) {\n'
            '      // AI 正在输出 → 阻断发送，消息入队\n'
            '      _queue.add(text);\n'
            '      return;  // ← 关键：直接 return，不调 inner\n'
            '    }\n'
            '    // 队列非空时：先从队列取一条发掉，新消息排到队尾\n'
            '    if (_queue.isNotEmpty) {\n'
            '      _inner.sendMessage(_queue.removeAt(0));\n'
            '      _queue.add(text);\n'
            '      return;\n'
            '    }\n'
            '    // 队列空 + 无流 → 正常发送\n'
            '    _inner.sendMessage(text);\n'
            '  }\n'
            '\n'
            '  // 状态全部委托给 _inner\n'
            '  @override bool get isStreaming => _inner.isStreaming;\n'
            '  @override List<String> get queueItems => _queue;\n'
            '  @override int get queueCount => _queue.length;\n'
            '  @override ValueNotifier<int> get attentionSignal => _inner.attentionSignal;\n'
            '  @override List<Exchange> get exchanges => _inner.exchanges;\n'
            '  @override bool get isLoadingHistory => _inner.isLoadingHistory;\n'
            '  @override int get totalTokens => _inner.totalTokens;\n'
            '  @override Duration? get elapsed => _inner.elapsed;\n'
            '  @override int get activeExchangeCount => _inner.activeExchangeCount;\n'
            '  @override void confirmTool(a, b, c) => _inner.confirmTool(a, b, c);\n'
            '  @override void cancelTool(a, b) => _inner.cancelTool(a, b);\n'
            '  @override void toggleQueue() => _inner.toggleQueue();\n'
            '  @override void addTokens(int c) => _inner.addTokens(c);\n'
            '  @override void acceptEvents(e, s) => _inner.acceptEvents(e, s);\n'
            '  @override void init() => _inner.init();\n'
            '  @override void dispose() {\n'
            '    _inner.removeListener(_onChanged);\n'
            '    _inner.dispose();\n'
            '    super.dispose();\n'
            '  }\n'
            '}',
      ),
      CodeSnippet(
        '执行流程：入队 → 阻断 → 排空',
        '时间线（用户连续发 3 条消息）：\n'
            '┌─────────────────────────────────────────────────┐\n'
            '│  sendMessage("请求1")                           │\n'
            '│  → isStreaming=false, queue空                   │\n'
            '│  → 直接送 inner → AI 开始流输出                   │\n'
            '├─────────────────────────────────────────────────┤\n'
            '│  sendMessage("请求2") ← 用户立即再发              │\n'
            '│  → isStreaming=true                             │\n'
            '│  → 阻断！_queue.add("请求2")  ░░░ 入队           │\n'
            '├─────────────────────────────────────────────────┤\n'
            '│  sendMessage("请求3") ← 用户又发                  │\n'
            '│  → isStreaming=true                             │\n'
            '│  → 阻断！_queue.add("请求3")  ░░░ 入队           │\n'
            '├─────────────────────────────────────────────────┤\n'
            '│  AI 流结束 → _onChanged 触发                     │\n'
            '│  → _drain() → 取 queue[0]="请求2" 送 inner       │\n'
            '│  → AI 又开始流输出 "请求2"...                     │\n'
            '├─────────────────────────────────────────────────┤\n'
            '│  AI 流结束 → _drain() → 取 "请求3" 送 inner       │\n'
            '│  → AI 流输出 "请求3"                             │\n'
            '├─────────────────────────────────────────────────┤\n'
            '│  AI 流结束 → _drain() → queue空 → 停止            │\n'
            '└─────────────────────────────────────────────────┘',
      ),
      CodeSnippet(
        '接入方式',
        'bus = ChatBus.withDecorators(\n'
            '  impl: DefaultChatBus(onGenerate: _mockAI),\n'
            '  decorators: [\n'
            '    (inner) => _QueueDecorator(inner),\n'
            '  ],\n'
            ');\n'
            '\n'
            '// 队列对外暴露的状态：\n'
            'bus.queueItems  → List<String>   // 队列中待处理的消息\n'
            'bus.queueCount  → int            // 队列长度\n'
            'bus.isStreaming → bool           // 是否正在流输出\n'
            '\n'
            '// ChatScreen 内置队列弹窗：\n'
            '// StatsBar 右侧按钮 → toggleQueue()\n'
            '// 弹出 _QueuePopupContent 展示 queueItems',
      ),
    ],
    // ── 5: 输入组件 ──
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
    // ── 6: 历史加载 ──
    [
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
    ],
    // ── 7: 自定义块 ──
    [
      CodeSnippet(
        'BlockDef — 一次性注册',
        '// BlockDef 同时包含样式 + 构造器：\n'
            'BlockRegistry.registerCustom(BlockDef(\n'
            '  name: \'code_snippet\',      // 类型名称\n'
            '  builder: _buildCodeSnippet, // Widget builder\n'
            '  icon: Icons.code,           // 头部图标\n'
            '  dotColor: Color(0xFF7C3AED),// 圆点色\n'
            '  headerColor: Color(0xFF7C3AED),// 头部色\n'
            '  label: \'代码片段\',          // 标签\n'
            '));\n'
            '\n'
            '// 不再需要分开调用 registerCustom + registerStyle，\n'
            '// 一个 BlockDef 一次性完成全部注册。\n'
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
            '  content: \'```dart\\nvoid main() {\\n  print("hello");\\n}\\n```\',\n'
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
    // ── 8: 主题画廊 ──
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
        'ChatThemes 提供了 6 个内置主题（3 类 × 亮暗）：\n'
            '├─ ChatThemes.fluent          — Fluent 2 浅色\n'
            '├─ ChatThemes.fluentDark      — Fluent 2 暗色\n'
            '├─ ChatThemes.light           — 默认亮色（紫色调）\n'
            '├─ ChatThemes.dark            — 默认暗色（紫色调）\n'
            '├─ ChatThemes.neumorphicLight — Neumorphism 浅色\n'
            '└─ ChatThemes.neumorphicDark  — Neumorphism 暗色\n'
            '\n'
            '你也可以用 ChatTheme(...) 构造任意自定义主题。',
      ),
    ],
    // ── 9: 自定义主题 ──
    [
      CodeSnippet(
        'macOS 亮色主题（完整）',
        'ChatTheme macOSLightTheme() => ChatTheme(\n'
            '  bgPrimary: Color(0xFFF5F5F7),     // 灰白底\n'
            '  bgSurface: Color(0xFFFFFFFF),\n'
            '  bgInput: Color(0xFFE8E8ED),\n'
            '  bgCard: Color(0xFFFFFFFF),\n'
            '  bgCardHeader: Color(0xFFF0F0F5),\n'
            '  bgCommand: Color(0xFFF0F0F5),\n'
            '  textPrimary: Color(0xFF1D1D1F),   // 近乎黑\n'
            '  textContent: Color(0xFF1D1D1F),\n'
            '  textSecondary: Color(0xFF86868B),\n'
            '  textToolHeader: Color(0xFF007AFF), // macOS 蓝\n'
            '  accent: Color(0xFF007AFF),\n'
            '  accentHover: Color(0xFF0066D6),\n'
            '  success: Color(0xFF34C759),\n'
            '  error: Color(0xFFFF3B30),\n'
            '  warning: Color(0xFFFF9500),\n'
            '  border: Color(0xFFD2D2D7),\n'
            '  borderLight: Color(0xFFE5E5EA),\n'
            '  btnSecondaryBg: Color(0x1F007AFF),\n'
            '  // ... 其他属性使用默认值（继承自 ChatTheme 构造函数）\n'
            ');',
      ),
      CodeSnippet(
        'macOS 暗色主题（完整）',
        'ChatTheme macOSDarkTheme() => ChatTheme(\n'
            '  bgPrimary: Color(0xFF1C1C1E),     // 深灰底\n'
            '  bgSurface: Color(0xFF2C2C2E),\n'
            '  bgInput: Color(0xFF3A3A3C),\n'
            '  bgCard: Color(0xFF2C2C2E),\n'
            '  bgCardHeader: Color(0xFF363638),\n'
            '  bgCommand: Color(0xFF363638),\n'
            '  textPrimary: Color(0xFFF5F5F7),   // 近乎白\n'
            '  textContent: Color(0xFFF5F5F7),\n'
            '  textSecondary: Color(0xFF98989D),\n'
            '  textToolHeader: Color(0xFF64B5F6), // 浅蓝\n'
            '  accent: Color(0xFF64B5F6),\n'
            '  accentHover: Color(0xFF4CA9F5),\n'
            '  success: Color(0xFF30D158),\n'
            '  error: Color(0xFFFF453A),\n'
            '  warning: Color(0xFFFF9F0A),\n'
            '  border: Color(0xFF48484A),\n'
            '  borderLight: Color(0xFF3A3A3C),\n'
            '  btnSecondaryBg: Color(0x2F64B5F6),\n'
            ');',
      ),
      CodeSnippet(
        '使用方式',
        '// 用 Theme widget 局部覆盖：\n'
            'Theme(\n'
            '  data: ThemeData(\n'
            '    brightness: Brightness.dark,\n'
            '    extensions: [macOSDarkTheme()],\n'
            '  ),\n'
            '  child: ChatScreen(bus: bus),\n'
            ')\n'
            '\n'
            '// 或全局注册：\n'
            'MaterialApp(\n'
            '  theme: ThemeData(extensions: [macOSLightTheme()]),\n'
            '  darkTheme: ThemeData(extensions: [macOSDarkTheme()]),\n'
            ')\n'
            '\n'
            '// 每个主题 ~20 个核心颜色属性，其他使用默认值。\n'
            '// ChatTheme 共约 70 个属性，未指定的走构造函数默认值。',
      ),
    ],
    // ── 10: 展开/折叠控制 ──
    [
      CodeSnippet(
        '默认展开规则',
        'ChatScreen._isCollapsed() 的默认策略：\n'
            '\n'
            'bool _isCollapsed(ChatBlock block, Exchange exchange) {\n'
            '  // ① 用户手动展开过 → 不折叠\n'
            '  if (_manuallyExpandedKeys.contains(key))\n'
            '    return false;\n'
            '  // ② 用户手动折叠过 → 折叠\n'
            '  if (_manuallyCollapsedKeys.contains(key))\n'
            '    return true;\n'
            '\n'
            '  // ③ 同组有 running/pending 的 block → 展开\n'
            '  for (final group in exchange.groups) {\n'
            '    if (group.blocks.any((b) => b.id == block.id)) {\n'
            '      if (group.blocks.any((b) =>\n'
            '          b.status == BlockStatus.running ||\n'
            '          b.status == BlockStatus.pending))\n'
            '        return false;\n'
            '      break;\n'
            '    }\n'
            '  }\n'
            '\n'
            '  // ④ 最新 block → 展开，历史 block → 折叠\n'
            '  return !_isLatestBlock(block, exchange);\n'
            '}',
      ),
      CodeSnippet(
        '手动切换：点击 header',
        '用户点击 block header 时触发 _handleToggle()：\n'
            '\n'
            'void _handleToggle() {\n'
            '  final newExpanded = !_expanded;\n'
            '  setState(() => _expanded = newExpanded);\n'
            '  // 通知父级记录手动状态\n'
            '  widget.onCollapsedChanged?.call(\n'
            '    widget.block.id, newExpanded);\n'
            '}\n'
            '\n'
            '// ChatScreen 将手工状态记入集合：\n'
            'void _onToggleCollapsed(\n'
            '    String collapseKey, bool currentlyCollapsed) {\n'
            '  setState(() {\n'
            '    if (currentlyCollapsed) {\n'
            '      _manuallyExpandedKeys.add(collapseKey);\n'
            '      _manuallyCollapsedKeys.remove(collapseKey);\n'
            '    } else {\n'
            '      _manuallyCollapsedKeys.add(collapseKey);\n'
            '      _manuallyExpandedKeys.remove(collapseKey);\n'
            '    }\n'
            '  });\n'
            '}',
      ),
      CodeSnippet(
        '同组并行强制展开',
        '当同一 ParallelBoundary 组内有正在运行的 block：\n'
            '\n'
            'yield ToolCallStarted(id, \'t1\', \'search\', {});\n'
            'yield ToolCallStarted(id, \'t2\', \'cache\', {});\n'
            'yield ParallelBoundary(id);  // ← 打包为同组\n'
            '\n'
            '// → t1 和 t2 同属一个 BlockGroup\n'
            '// → 只要 t2 还在 running，整个组保持展开\n'
            '// → 即使 t1 已完成，用户也看不到折叠\n'
            '// → 全部完成后恢复到默认规则\n'
            '\n'
            '// 这是通过 _isCollapsed 中的"同组检查"实现的：\n'
            'group.blocks.any((b) =>\n'
            '  b.status == BlockStatus.running ||\n'
            '  b.status == BlockStatus.pending\n'
            ') → return false (不折叠)',
      ),
      CodeSnippet(
        '通过 CustomBlockEvent / 外部控制',
        '// 目前 ChatScreen 的折叠状态完全由 UI 交互驱动。\n'
            '// 你可以通过以下方式从外部触发折叠/展开：\n'
            '\n'
            '// 方式 A：利用 CustomBlockEvent 携带标记\n'
            '// 在你的事件流中发射元数据事件，由 ChatScreen\n'
            '// 的监听器提取并调用 _onToggleCollapsed()。\n'
            '\n'
            '// 方式 B：继承 ChatScreen 覆写 _isCollapsed\n'
            '// 或通过 blockRegistry 自定义 block widget\n'
            '// 的 collapsed 参数。\n'
            '\n'
            '// 方式 C：直接操作 collapsedBlockIds 集合\n'
            '// (需要访问 ChatScreen 内部状态，暂未暴露)\n'
            '// 但你可以自己实现一个 ChatBus 监听器来\n'
            '// 响应特定事件并触发重建。',
      ),
    ],
    // ── 11: 统计栏 ──
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
    // ── 12: 自定义语言 ──
    [
      CodeSnippet(
        'ChatL10nFrench — 继承抽象类',
        'class ChatL10nFrench extends ChatL10n {\n'
            '  const ChatL10nFrench();\n'
            '\n'
            '  @override String get emptyChatHint\n'
            '      => \'Envoyez un message pour commencer\';\n'
            '  @override String get inputHint\n'
            '      => \'Entrez un message…\';\n'
            '  @override String get expandAll => \'Tout développer\';\n'
            '  @override String get collapse => \'Réduire\';\n'
            '  // … 编译器强制实现全部 20+ 个 getter …\n'
            '  @override String get btnCancel => \'Annuler\';\n'
            '}',
      ),
      CodeSnippet(
        'ChatL10nScope 注入',
        '// 方式 A：全局 Scope，子树全部自动生效\n'
            'ChatL10nScope(\n'
            '  l10n: const ChatL10nFrench(),\n'
            '  child: ChatScreen(bus: bus),\n'
            ')\n'
            '\n'
            '// 方式 B：ChatScreen 直接传参\n'
            'ChatScreen(bus: bus, l10n: const ChatL10nFrench())\n'
            '\n'
            '// 方式 C：跟随系统 locale\n'
            'ChatL10nScope(\n'
            '  l10n: _fromLocale(PlatformDispatcher\n'
            '      .instance.locale),\n'
            '  child: MaterialApp(...),\n'
            ')\n'
            '// 自己写分发函数，不改库源码',
      ),
      CodeSnippet(
        '内置 vs 自定义',
        'ChatL10n 提供 3 种内置语言：\n'
            '├─ zhHans — 中文简体 (zh-Hans)\n'
            '├─ zhHant — 中文繁体 (zh-Hant)\n'
            '└─ en   — 英文\n'
            '\n'
            '开发者添加新语言只需：\n'
            '1. 继承 ChatL10n，实现全部 getter\n'
            '2. 用 ChatL10nScope 注入\n'
            '\n'
            '不需改库源码，不需代码生成。',
      ),
    ],
  ];

  @override
  String get themeDemoTitle => 'macOS Neumorphism';
  @override
  String get neuTooltip => 'Neumorphism: 双阴影挤出 + 单色系';
  @override
  List<String> get chatThemeNames => const ['Fluent', '默认', 'Neumorphism'];
}

// ── zh_TW ──

class _AppL10nZhHant extends AppL10n {
  const _AppL10nZhHant();

  @override
  String get appTitle => 'Agent Chat';
  @override
  String get appSubtitle => '特性展示';
  @override
  String get viewApiCode => '檢視 API 程式碼';
  @override
  String get coreApiLabel => '核心介面呼叫';
  @override
  String codeDrawerTitle(String name) => '$name — API';
  @override
  String get light => '亮色';
  @override
  String get dark => '暗色';
  @override
  String get switchColor => '切換配色';
  @override
  String get chatThemeLabel => 'ChatTheme';
  @override
  String get themeFluent => 'Fluent';
  @override
  String get themeDefault => '預設';
  @override
  String get themeNeumorphism => 'Neumorphism';

  @override
  String colorName(String key) {
    const names = <String, String>{
      'teal': 'teal',
      'indigo': 'indigo',
      'purple': 'purple',
      'orange': 'orange',
      'blue grey': 'blue grey',
      'pink': 'pink',
    };
    return names[key] ?? key;
  }

  @override
  String get currentLocaleName => '繁體';
  @override
  String get switchLocale => '切換語言';
  @override
  String get inputDefault => '預設';
  @override
  String get inputQueue => '+ 佇列按鈕';
  @override
  String get inputToken => '+ Token 按鈕';
  @override
  String get inputTextOnly => '純文字';
  @override
  String get textFieldOnlyHint => '僅展示 TextField 輸入';

  @override
  List<String> get featureTitles => const [
    '串流輸出展示',
    '工具呼叫展示',
    '確認閘演示',
    '錯誤區塊展示',
    '佇列模式',
    '輸入元件',
    '歷史載入',
    '自訂區塊',
    '主題畫廊',
    '自訂主題',
    '展開/收起控制',
    '統計欄',
    '自訂語言',
  ];

  @override
  List<String> get featureSubtitles => const [
    '打字機效果的 thinking / content delta',
    'ToolCall block 各狀態渲染',
    '工具需確認的對話框流程',
    'ExchangeError / 失敗狀態渲染',
    '串流發送訊息入佇列 → 自動排空',
    'ChatInput 多種按鈕配置',
    '模擬載入多輪對話歷史',
    'CustomBlock + BlockRegistry',
    '暗色/亮色/內建 ChatTheme 切換',
    '動態建立 ChatTheme 即時預覽',
    'ExchangeEvent 控制區塊可見性',
    'Token 計數 / 耗時顯示',
    'ChatL10n 繼承 + Scope 注入',
  ];

  @override
  List<List<CodeSnippet>> get featureSnippets => buildZhHantSnippets();
  @override
  String get themeDemoTitle => 'macOS Neumorphism';
  @override
  String get neuTooltip => 'Neumorphism: 雙陰影擠出 + 單色系';
  @override
  List<String> get chatThemeNames => const ['Fluent', '預設', 'Neumorphism'];
}

// ── en ──

class _AppL10nEn extends AppL10n {
  const _AppL10nEn();

  @override
  String get appTitle => 'Agent Chat';
  @override
  String get appSubtitle => 'Feature Showcase';
  @override
  String get viewApiCode => 'View API Code';
  @override
  String get coreApiLabel => 'Core API Reference';
  @override
  String codeDrawerTitle(String name) => '$name — API';
  @override
  List<List<CodeSnippet>> get featureSnippets => buildEnSnippets();
  @override
  String get light => 'Light';
  @override
  String get dark => 'Dark';
  @override
  String get switchColor => 'Switch color';
  @override
  String get chatThemeLabel => 'ChatTheme';
  @override
  String get themeFluent => 'Fluent';
  @override
  String get themeDefault => 'Default';
  @override
  String get themeNeumorphism => 'Neumorphism';

  @override
  String colorName(String key) {
    const names = <String, String>{
      'teal': 'teal',
      'indigo': 'indigo',
      'purple': 'purple',
      'orange': 'orange',
      'blue grey': 'blue grey',
      'pink': 'pink',
    };
    return names[key] ?? key;
  }

  @override
  String get currentLocaleName => 'English';
  @override
  String get switchLocale => 'Switch language';
  @override
  String get inputDefault => 'Default';
  @override
  String get inputQueue => '+ Queue';
  @override
  String get inputToken => '+ Token';
  @override
  String get inputTextOnly => 'Text only';
  @override
  String get textFieldOnlyHint => 'TextField input only';

  @override
  List<String> get featureTitles => const [
    'Streaming Output',
    'Tool Calls',
    'Confirmation Gate',
    'Error Blocks',
    'Queue Mode',
    'Input Modes',
    'History Loading',
    'Custom Blocks',
    'Theme Gallery',
    'Custom Theme',
    'Collapse / Expand',
    'Stats Bar',
    'Custom Language',
  ];

  @override
  List<String> get featureSubtitles => const [
    'Typewriter effect for thinking / content delta',
    'ToolCall block state rendering',
    'Confirmation dialog flow for tools',
    'ExchangeError / failure state rendering',
    'Streaming message queue with auto-drain',
    'ChatInput with multiple button configurations',
    'Multi-turn conversation history loading',
    'CustomBlock + BlockRegistry',
    'Dark/light/built-in ChatTheme switching',
    'Real-time ChatTheme preview',
    'ExchangeEvent-driven collapse control',
    'Token count / elapsed time display',
    'ChatL10n inheritance + Scope injection',
  ];

  @override
  String get themeDemoTitle => 'macOS Neumorphism';
  @override
  String get neuTooltip => 'Neumorphism: dual-shadow extrusion + monochrome';
  @override
  List<String> get chatThemeNames => const ['Fluent', 'Default', 'Neumorphism'];
}
