import 'code_drawer.dart';

/// Traditional Chinese code snippets for all 13 features.
List<List<CodeSnippet>> buildZhHantSnippets() => [
  // ── 0: 串流輸出展示 ──
  [
    CodeSnippet(
      'DefaultChatBus.onGenerate',
      '// 核心 API：透過 onGenerate 回呼傳回事件串流\n'
          'bus = DefaultChatBus(\n'
          '  onGenerate: (String text) async* {\n'
          '    // 1. 思考區塊 — 逐字 delta\n'
          '    yield ThinkingStarted(id, \'think_1\');\n'
          '    for (...) {\n'
          '      yield ThinkingDelta(id, \'think_1\', text);\n'
          '      await Future.delayed(Duration(milliseconds: 25));\n'
          '    }\n'
          '    yield ThinkingCompleted(id, \'think_1\', fullText);\n'
          '\n'
          '    // 2. 工具呼叫\n'
          '    yield ToolCallStarted(id, \'tool\', \'read_file\', args);\n'
          '    // ... 等待執行\n'
          '    yield ToolCallCompleted(id, \'tool\', result);\n'
          '    //        isError: true  → 紅色錯誤樣式\n'
          '    // 3. 內容輸出 — 打字機效果\n'
          '    yield ContentStarted(id, \'content\');\n'
          '    for (...) {\n'
          '      yield ContentDelta(id, \'content\', chunk);\n'
          '      await Future.delayed(Duration(milliseconds: 16));\n'
          '    }\n'
          '    yield ContentCompleted(id, \'content\', fullText);\n'
          '\n'
          '    // 4. Token 統計\n'
          '    yield TokenCount(id, count);\n'
          '  },\n'
          ');',
    ),
    CodeSnippet(
      '事件串流生命週期',
      'ExchangeEvent 事件型別：\n'
          '├─ ThinkingStarted / Delta / Completed  — 思考區塊\n'
          '├─ ToolCallStarted / Delta / Completed  — 工具呼叫\n'
          '├─ ContentStarted / Delta / Completed   — 內容輸出\n'
          '├─ ParallelBoundary                     — 並行分組\n'
          '├─ TokenCount                           — 計 token\n'
          '├─ ExchangeError                        — 錯誤\n'
          '└─ CustomBlockEvent                     — 自訂區塊\n'
          '\n'
          'DefaultChatBus._processEventStream() 透過\n'
          'await for (final event in stream) 消費事件串流，\n'
          '每收到事件就 notifyListeners() 觸發 UI 更新。',
    ),
    CodeSnippet(
      '停止串流輸出 / 中斷',
      '// 中斷回呼\n'
          'onInterrupt: () => _cancelled = true;\n'
          '\n'
          '// 在 async* 產生器中檢查旗標\n'
          'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
          '  _cancelled = false;\n'
          '  for (...) {\n'
          '    if (_cancelled) return;  // ← 立即停止 yield\n'
          '    yield ThinkingDelta(...);\n'
          '  }\n'
          '}\n'
          '\n'
          '// ChatScreen 內部呼叫 bus.cancelTool() →\n'
          '// 觸發 onInterrupt → _cancelled = true\n'
          '// → async* 函式 return → 串流結束',
    ),
  ],
  // ── 1: 工具呼叫展示 ──
  [
    CodeSnippet(
      'ToolCallStarted 參數',
      'yield ToolCallStarted(\n'
          '  exchangeId,          // 所屬 exchange\n'
          '  blockId,             // 區塊唯一 ID\n'
          '  toolName,            // 工具名（如 read_file）\n'
          '  arguments,           // 參數 Map\n'
          '  requiresConfirm,     // 是否需要使用者確認\n'
          '  autoApproved,        // 自動批准\n'
          '  description,         // 確認對話框描述\n'
          '  canAlwaysAllow,      // 是否顯示"始終允許"\n'
          ');',
    ),
    CodeSnippet(
      'BlockStatus 狀態機',
      'BlockStatus 列舉值：\n'
          '├─ pending         — 等待確認（確認閘）\n'
          '├─ running         — 執行中\n'
          '├─ completed       — 已完成\n'
          '├─ cancelled       — 已取消\n'
          '├─ approved        — 已批准\n'
          '└─ alwaysAllowed   — 始終允許\n'
          '\n'
          'DefaultChatBus 自動管理狀態轉換：\n'
          ' - ToolCallStarted + requiresConfirm → pending\n'
          ' - 使用者 confirmTool() → approved/running\n'
          ' - 使用者 cancelTool()  → cancelled\n'
          ' - ToolCallCompleted           → completed\n'
          ' - ToolCallCompleted(isError)  → completed + exchange failed\n'
          ' - ExchangeError               → exchange failed + 錯誤區塊',
    ),
    CodeSnippet(
      'ParallelBoundary 分組',
      '// ParallelBoundary 將前面的 blocks 分為一組\n'
          '// 同組內 blocks 並行渲染（無序號首碼）\n'
          'yield ToolCallStarted(id, \'t1\', \'tool_a\', {});\n'
          'yield ToolCallStarted(id, \'t2\', \'tool_b\', {});\n'
          'yield ParallelBoundary(id);  // ← 打包 t1+t2 為同一組\n'
          '// 之後的 blocks 進入新組',
    ),
  ],
  // ── 2: 確認閘演示 ──
  [
    CodeSnippet(
      '確認閘核心流程',
      '// 1. 發射需確認的工具\n'
          'yield ToolCallStarted(id, \'tool\', \'delete_file\',\n'
          '    {\'path\': \'/tmp/cache.db\'},\n'
          '    requiresConfirm: true,\n'
          '    description: \'將要刪除快取檔案\',\n'
          '    canAlwaysAllow: true,  // 顯示"始終允許"核取方塊\n'
          ');\n'
          '\n'
          '// 2. ChatScreen 偵測 pending block → 彈出確認對話框\n'
          '// 3. 使用者選擇：\n'
          '//    - 批准 → bus.confirmTool(e, t, false)\n'
          '//              → status 變 approved → running\n'
          '//    - 拒絕 → bus.cancelTool(e, t)\n'
          '//              → status 變 cancelled\n'
          '//              → 觸發 onInterrupt\n'
          '//    - 始終允許 → bus.confirmTool(e, t, true)\n'
          '//                 → 加入信任清單\n'
          '//                 → 後續同工具跳過確認',
    ),
    CodeSnippet(
      '信任清單機制',
      '// DefaultChatBus 內部維護 _trustedTools 集合。\n'
          '// 當使用者選擇"始終允許"時，該工具名加入信任清單：\n'
          '_trustedTools.add(toolName);\n'
          '// 後續同名的 ToolCallStarted 檢查信任清單：\n'
          'final autoApproved = e.autoApproved\n'
          '    || _trustedTools.contains(e.toolName);\n'
          '// 命中 → 跳過確認閘，直接進入 running 狀態',
    ),
    CodeSnippet(
      '按鈕樣式（主題控制）',
      '確認閘按鈕透過 ChatTheme 控制樣式：\n'
          '\n'
          'smallButtonHeight    — 按鈕高度（預設 24px）\n'
          'radiusSm             — 按鈕圓角（預設 2px）\n'
          'fontSizeSm           — 按鈕字型大小（預設 12px）\n'
          'buttonPadding        — 按鈕內距\n'
          'accent               — 允許/始終允許按鈕色\n'
          'textSecondary        — 取消按鈕文字色\n'
          '\n'
          '暗色模式下 filled 按鈕文字為深色 #1A1A1A，\n'
          '亮色模式下為白色。描邊按鈕文字 = accent 色，\n'
          '邊框 = accent 色 39% 透明度。',
    ),
  ],
  // ── 3: 錯誤區塊展示 ──
  [
    CodeSnippet(
      'yield ExchangeError',
      '// 在事件串流中直接 yield ExchangeError：\n'
          '\n'
          'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
          '  yield ThinkingStarted(id, \'think\');\n'
          '  // ...\n'
          '  if (somethingWrong) {\n'
          '    yield ExchangeError(\n'
          '      id,                               // exchangeId\n'
          '      \'分析失敗: 目標倉庫不存在\\n\'         // 錯誤訊息\n'
          '      \'請檢查路徑是否正確。\'\n'
          '    );\n'
          '    return;  // ← 必須 return，串流不再繼續\n'
          '  }\n'
          '  // ... 正常流程\n'
          '}',
    ),
    CodeSnippet(
      '失敗態觸發機制',
      '目前有兩種方式觸發 Exchange 失敗態：\n'
          '\n'
          '// 方式A：ExchangeError（顯示錯誤區塊）\n'
          'yield ExchangeError(id, \'訊息…\');\n'
          '→ 設 status=failed + errorMessage\n'
          '→ ChatScreen 渲染"錯誤"標頭 + 錯誤訊息\n'
          '→ 折疊時標頭後顯示訊息摘要（新增）\n'
          '\n'
          '// 方式B：ToolCallCompleted(isError)（工具變紅）\n'
          'yield ToolCallCompleted(id, \'tool\', \'✗ 錯誤…\',\n'
          '    isError: true);\n'
          '→ 設 status=failed，不設 errorMessage\n'
          '→ 工具區塊以紅色邊框/文字顯示錯誤結果\n'
          '→ 不額外渲染錯誤區塊（避免資訊重複）\n'
          '\n'
          '// 兩種方式均觸發區塊級錯誤樣式：\n'
          '// _isFailed(exchange) → thinking/tool/content\n'
          '// 所有 block 文字變為 theme.error 紅色',
    ),
  ],
  // ── 4: 佇列模式 ──
  [
    CodeSnippet(
      '完整佇列裝飾器原始碼',
      'class _QueueDecorator with ChangeNotifier\n'
          '    implements ChatBus {\n'
          '  final ChatBus _inner;\n'
          '  final List<String> _queue = [];\n'
          '  bool _wasStreaming = false;\n'
          '\n'
          '  _QueueDecorator(this._inner) {\n'
          '    _inner.addListener(_onChanged);  // ① 監聽串流狀態\n'
          '  }\n'
          '\n'
          '  // ── ② 串流狀態變化時自動排空 ──\n'
          '  void _onChanged() {\n'
          '    // 串流從"正在輸出"→"輸出結束"的瞬間\n'
          '    if (_wasStreaming && !_inner.isStreaming) {\n'
          '      _drain();  // ③ 排空佇列中的下一條\n'
          '    }\n'
          '    _wasStreaming = _inner.isStreaming;\n'
          '    notifyListeners();\n'
          '  }\n'
          '\n'
          '  // ── ③ 排空：取下一條發送 ──\n'
          '  void _drain() {\n'
          '    if (_queue.isNotEmpty) {\n'
          '      _inner.sendMessage(_queue.removeAt(0));\n'
          '      // drain 只發一條，發完下一輪 _onChanged\n'
          '      // 再觸發下一次 drain，直到佇列清空\n'
          '    }\n'
          '  }\n'
          '\n'
          '  // ── ④ sendMessage：攔截入隊邏輯 ──\n'
          '  @override\n'
          '  void sendMessage(String text) {\n'
          '    if (_inner.isStreaming) {\n'
          '      // AI 正在輸出 → 阻斷發送，訊息入隊\n'
          '      _queue.add(text);\n'
          '      return;  // ← 關鍵：直接 return，不調 inner\n'
          '    }\n'
          '    // 佇列非空時：先從佇列取一條發掉，新訊息排到隊尾\n'
          '    if (_queue.isNotEmpty) {\n'
          '      _inner.sendMessage(_queue.removeAt(0));\n'
          '      _queue.add(text);\n'
          '      return;\n'
          '    }\n'
          '    // 佇列空 + 無串流 → 正常發送\n'
          '    _inner.sendMessage(text);\n'
          '  }\n'
          '\n'
          '  // 狀態全部委託給 _inner\n'
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
      '執行流程：入隊 → 阻斷 → 排空',
      '時間線（使用者連續發 3 條訊息）：\n'
          '┌─────────────────────────────────────────────────┐\n'
          '│  sendMessage("請求1")                           │\n'
          '│  → isStreaming=false, queue空                   │\n'
          '│  → 直接送 inner → AI 開始串流輸出                 │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  sendMessage("請求2") ← 使用者立即再發            │\n'
          '│  → isStreaming=true                             │\n'
          '│  → 阻斷！_queue.add("請求2")  ░░░ 入隊           │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  sendMessage("請求3") ← 使用者又發                │\n'
          '│  → isStreaming=true                             │\n'
          '│  → 阻斷！_queue.add("請求3")  ░░░ 入隊           │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI 串流結束 → _onChanged 觸發                   │\n'
          '│  → _drain() → 取 queue[0]="請求2" 送 inner       │\n'
          '│  → AI 又開始串流輸出 "請求2"...                   │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI 串流結束 → _drain() → 取 "請求3" 送 inner     │\n'
          '│  → AI 串流輸出 "請求3"                           │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI 串流結束 → _drain() → queue空 → 停止          │\n'
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
          '// 佇列對外暴露的狀態：\n'
          'bus.queueItems  → List<String>   // 佇列中待處理的訊息\n'
          'bus.queueCount  → int            // 佇列長度\n'
          'bus.isStreaming → bool           // 是否正在串流輸出\n'
          '\n'
          '// ChatScreen 內建佇列彈窗：\n'
          '// StatsBar 右側按鈕 → toggleQueue()\n'
          '// 彈出 _QueuePopupContent 展示 queueItems',
    ),
  ],
  // ── 5: 輸入元件 ──
  [
    CodeSnippet(
      'ChatScreen 參數',
      'ChatScreen(\n'
          '  bus: bus,                    // 必需：ChatBus\n'
          '  theme: myChatTheme,          // 可選：自訂 ChatTheme\n'
          '  loadingIndicator: ...,       // 可選：載入中檢視\n'
          '  emptyPlaceholder: ...,       // 可選：空清單檢視\n'
          ')\n'
          '\n'
          'ChatScreen 內部建構了完整的聊天 UI：\n'
          '├─ 訊息清單（CustomScrollView + Sliver）\n'
          '├─ 輸入框（AutoResizeTextField）\n'
          '├─ StatsBar\n'
          '└─ 佇列彈窗',
    ),
    CodeSnippet(
      '輸入框核心屬性',
      'AutoResizeTextField(\n'
          '  controller,   // TextEditingController\n'
          '  hintText,     // 佔位提示\n'
          '  onChanged,    // 文字變化回呼\n'
          ')\n'
          '\n'
          '自動調整高度的多行輸入框，支援：\n'
          ' - Enter 發送、Shift+Enter 換行\n'
          ' - 自適應高度（minLines / maxLines）\n'
          ' - 發送按鈕 + 可選佇列/Token 按鈕',
    ),
  ],
  // ── 6: 歷史載入 ──
  [
    CodeSnippet(
      'Exchange 模型',
      'Exchange(\n'
          '  id: \'ex_001\',            // 唯一 ID\n'
          '  userMessage: \'你好\',     // 使用者訊息\n'
          '  timestamp: DateTime.now(),\n'
          '  groups: [                  // BlockGroup 清單\n'
          '    BlockGroup(id: \'g1\', blocks: [\n'
          '      ChatBlock(id: \'b1\', type: BlockType.thinking,\n'
          '          content: \'思考中…\',\n'
          '          status: BlockStatus.completed),\n'
          '      ChatBlock(id: \'b2\', type: BlockType.content,\n'
          '          content: \'回覆內容\',\n'
          '          status: BlockStatus.completed),\n'
          '    ]),\n'
          '  ],\n'
          '  status: ExchangeStatus.completed,\n'
          '  errorMessage: null,        // 失敗時設定\n'
          ')\n'
          '\n'
          'ExchangeStatus: completed / processing /\n'
          '                  waitingInput / cancelled / failed',
    ),
    CodeSnippet(
      'ChatBus.exchanges',
      '// 唯讀的歷史記錄清單\n'
          'List<Exchange> get exchanges;\n'
          '\n'
          '// 新訊息透過 sendMessage() 新增，\n'
          '// DefaultChatBus 自動建立 Exchange\n'
          '// 並附加到 _exchanges 清單。\n'
          '\n'
          '// isLoadingHistory 控制載入狀態\n'
          'bool get isLoadingHistory;\n'
          '// → true 時 ChatScreen 顯示 loadingIndicator\n'
          '// → false 時顯示正常訊息清單',
    ),
  ],
  // ── 7: 自訂區塊 ──
  [
    CodeSnippet(
      'BlockDef — 一次性註冊',
      '// BlockDef 同時包含樣式 + 建構器：\n'
          'BlockRegistry.registerCustom(BlockDef(\n'
          '  name: \'code_snippet\',      // 型別名稱\n'
          '  builder: _buildCodeSnippet, // Widget builder\n'
          '  icon: Icons.code,           // 標頭圖示\n'
          '  dotColor: Color(0xFF7C3AED),// 圓點色\n'
          '  headerColor: Color(0xFF7C3AED),// 標頭色\n'
          '  label: \'程式碼片段\',        // 標籤\n'
          '));\n'
          '\n'
          '// 不再需要分開呼叫 registerCustom + registerStyle，\n'
          '// 一個 BlockDef 一次性完成全部註冊。\n'
          '\n'
          '// Widget builder 簽名：\n'
          'typedef CustomBlockBuilder = Widget Function(\n'
          '  BuildContext context,\n'
          '  ChatBlock block,\n'
          '  ChatBus bus,\n'
          '  Exchange exchange,\n'
          ');',
    ),
    CodeSnippet(
      'CustomBlockEvent 發射',
      '// 在事件串流中發送自訂區塊\n'
          'yield CustomBlockEvent(\n'
          '  exchangeId,\n'
          '  \'code_1\',\n'
          '  \'code_snippet\',                // 對應 registerCustom 的名稱\n'
          '  content: \'```dart\\nvoid main() {\\n  print("hello");\\n}\\n```\',\n'
          '  label: \'hello.dart\',          // 顯示標題\n'
          '  status: BlockStatus.completed,\n'
          '  metadata: {\'language\': \'dart\'},\n'
          ');\n'
          '\n'
          '// DefaultChatBus 處理流程：\n'
          '// CustomBlockEvent → 建立 ChatBlock(\n'
          '//   type: BlockType.custom(typeName)\n'
          '// ) → 附加到 pendingBlocks\n'
          '// → notifyListeners → UI 渲染',
    ),
  ],
  // ── 8: 主題畫廊 ──
  [
    CodeSnippet(
      'ChatTheme 結構',
      'ChatTheme 是 ThemeExtension<ChatTheme>，\n'
          '包含 ~70 個屬性分 8 類：\n'
          '├─ 背景色  — bgPrimary / bgSurface / bgCard …\n'
          '├─ 文字色  — textPrimary / textContent …\n'
          '├─ 強調色  — accent / accentHover / success / error\n'
          '├─ 邊框色  — border / borderLight / borderAccent\n'
          '├─ 狀態點  — dotThinking / dotTool / dotContent\n'
          '├─ 間距    — spacingXs ~ spacingXl / blockPadding\n'
          '├─ 圓角    — radiusSm ~ radiusXl\n'
          '└─ 動畫    — breathingDuration / rotationDuration',
    ),
    CodeSnippet(
      'ThemeData 註冊',
      '// 將 ChatTheme 註冊為 ThemeExtension：\n'
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
          'ChatScreen 透過 ChatTheme.of(context) 取得：\n'
          'return Theme.of(context).extension<ChatTheme>()\n'
          '    ?? _fallback;',
    ),
    CodeSnippet(
      '內建主題',
      'ChatThemes 提供了 6 個內建主題（3 類 × 亮暗）：\n'
          '├─ ChatThemes.fluent          — Fluent 2 淺色\n'
          '├─ ChatThemes.fluentDark      — Fluent 2 暗色\n'
          '├─ ChatThemes.light           — 預設亮色（紫色調）\n'
          '├─ ChatThemes.dark            — 預設暗色（紫色調）\n'
          '├─ ChatThemes.neumorphicLight — Neumorphism 淺色\n'
          '└─ ChatThemes.neumorphicDark  — Neumorphism 暗色\n'
          '\n'
          '你也可以用 ChatTheme(...) 建構任意自訂主題。',
    ),
  ],
  // ── 9: 自訂主題 ──
  [
    CodeSnippet(
      'macOS 亮色主題（完整）',
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
          '  textToolHeader: Color(0xFF007AFF), // macOS 藍\n'
          '  accent: Color(0xFF007AFF),\n'
          '  accentHover: Color(0xFF0066D6),\n'
          '  success: Color(0xFF34C759),\n'
          '  error: Color(0xFFFF3B30),\n'
          '  warning: Color(0xFFFF9500),\n'
          '  border: Color(0xFFD2D2D7),\n'
          '  borderLight: Color(0xFFE5E5EA),\n'
          '  btnSecondaryBg: Color(0x1F007AFF),\n'
          '  // ... 其他屬性使用預設值（繼承自 ChatTheme 建構函式）\n'
          ');',
    ),
    CodeSnippet(
      'macOS 暗色主題（完整）',
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
          '  textToolHeader: Color(0xFF64B5F6), // 淺藍\n'
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
      '// 用 Theme widget 局部覆蓋：\n'
          'Theme(\n'
          '  data: ThemeData(\n'
          '    brightness: Brightness.dark,\n'
          '    extensions: [macOSDarkTheme()],\n'
          '  ),\n'
          '  child: ChatScreen(bus: bus),\n'
          ')\n'
          '\n'
          '// 或全域註冊：\n'
          'MaterialApp(\n'
          '  theme: ThemeData(extensions: [macOSLightTheme()]),\n'
          '  darkTheme: ThemeData(extensions: [macOSDarkTheme()]),\n'
          ')\n'
          '\n'
          '// 每個主題 ~20 個核心顏色屬性，其他使用預設值。\n'
          '// ChatTheme 共約 70 個屬性，未指定的走建構函式預設值。',
    ),
  ],
  // ── 10: 展開/收起控制 ──
  [
    CodeSnippet(
      '預設展開規則',
      'ChatScreen._isCollapsed() 的預設策略：\n'
          '\n'
          'bool _isCollapsed(ChatBlock block, Exchange exchange) {\n'
          '  // ① 使用者手動展開過 → 不折疊\n'
          '  if (_manuallyExpandedKeys.contains(key))\n'
          '    return false;\n'
          '  // ② 使用者手動折疊過 → 折疊\n'
          '  if (_manuallyCollapsedKeys.contains(key))\n'
          '    return true;\n'
          '\n'
          '  // ③ 同組有 running/pending 的 block → 展開\n'
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
          '  // ④ 最新 block → 展開，歷史 block → 折疊\n'
          '  return !_isLatestBlock(block, exchange);\n'
          '}',
    ),
    CodeSnippet(
      '手動切換：點選 header',
      '使用者點選 block header 時觸發 _handleToggle()：\n'
          '\n'
          'void _handleToggle() {\n'
          '  final newExpanded = !_expanded;\n'
          '  setState(() => _expanded = newExpanded);\n'
          '  // 通知父級記錄手動狀態\n'
          '  widget.onCollapsedChanged?.call(\n'
          '    widget.block.id, newExpanded);\n'
          '}\n'
          '\n'
          '// ChatScreen 將手動狀態記入集合：\n'
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
      '同組並行強制展開',
      '當同一 ParallelBoundary 組內有正在執行的 block：\n'
          '\n'
          'yield ToolCallStarted(id, \'t1\', \'search\', {});\n'
          'yield ToolCallStarted(id, \'t2\', \'cache\', {});\n'
          'yield ParallelBoundary(id);  // ← 打包為同組\n'
          '\n'
          '// → t1 和 t2 同屬一個 BlockGroup\n'
          '// → 只要 t2 還在 running，整個組保持展開\n'
          '// → 即使 t1 已完成，使用者也看不到折疊\n'
          '// → 全部完成後恢復到預設規則\n'
          '\n'
          '// 這是透過 _isCollapsed 中的"同組檢查"實現的：\n'
          'group.blocks.any((b) =>\n'
          '  b.status == BlockStatus.running ||\n'
          '  b.status == BlockStatus.pending\n'
          ') → return false (不折疊)',
    ),
    CodeSnippet(
      '透過 CustomBlockEvent / 外部控制',
      '// 目前 ChatScreen 的折疊狀態完全由 UI 互動驅動。\n'
          '// 你可以透過以下方式從外部觸發折疊/展開：\n'
          '\n'
          '// 方式 A：利用 CustomBlockEvent 攜帶標記\n'
          '// 在你的事件串流中發射元資料事件，由 ChatScreen\n'
          '// 的監聽器提取並呼叫 _onToggleCollapsed()。\n'
          '\n'
          '// 方式 B：繼承 ChatScreen 覆寫 _isCollapsed\n'
          '// 或透過 blockRegistry 自訂 block widget\n'
          '// 的 collapsed 參數。\n'
          '\n'
          '// 方式 C：直接操作 collapsedBlockIds 集合\n'
          '// (需要存取 ChatScreen 內部狀態，暫未暴露)\n'
          '// 但你可以自己實現一個 ChatBus 監聽器來\n'
          '// 回應特定事件並觸發重建。',
    ),
  ],
  // ── 11: 統計欄 ──
  [
    CodeSnippet(
      'StatsBar 指標',
      'StatsBar 展示 ChatBus 的統計資訊：\n'
          '├─ totalTokens: int         — 累計 Token\n'
          '├─ elapsed: Duration?       — 目前/上次會話耗時\n'
          '├─ queueCount: int          — 佇列長度\n'
          '├─ activeExchangeCount: int — 活躍 Exchange 數\n'
          '└─ isLoadingHistory: bool   — 是否正在載入歷史\n'
          '\n'
          '使用方法：\n'
          'StatsBar(totalTokens: bus.totalTokens)\n'
          '// 自動監聽 bus 變化更新顯示',
    ),
    CodeSnippet(
      'Token 計數機制',
      '// 在事件串流中發射 Token：\n'
          'yield TokenCount(id, 156);  // 累加到 totalTokens\n'
          '\n'
          '// 程式化增加：\n'
          'bus.addTokens(100);\n'
          '\n'
          '// 讀取：\n'
          'int get totalTokens => _totalTokens;\n'
          '\n'
          '// 計時：\n'
          '// DefaultChatBus 在首個 Exchange 開始時\n'
          '// 記錄 _startTime，串流結束時記錄 _lastElapsed\n'
          'Duration? get elapsed => _startTime != null\n'
          '    ? DateTime.now().difference(_startTime!)\n'
          '    : _lastElapsed;',
    ),
  ],
  // ── 12: 自訂語言 ──
  [
    CodeSnippet(
      'ChatL10nFrench — 繼承抽象類別',
      'class ChatL10nFrench extends ChatL10n {\n'
          '  const ChatL10nFrench();\n'
          '\n'
          '  @override String get emptyChatHint\n'
          '      => \'Envoyez un message pour commencer\';\n'
          '  @override String get inputHint\n'
          '      => \'Entrez un message…\';\n'
          '  @override String get expandAll => \'Tout développer\';\n'
          '  @override String get collapse => \'Réduire\';\n'
          '  // … 編譯器強制實現全部 20+ 個 getter …\n'
          '  @override String get btnCancel => \'Annuler\';\n'
          '}',
    ),
    CodeSnippet(
      'ChatL10nScope 注入',
      '// 方式 A：全域 Scope，子樹全部自動生效\n'
          'ChatL10nScope(\n'
          '  l10n: const ChatL10nFrench(),\n'
          '  child: ChatScreen(bus: bus),\n'
          ')\n'
          '\n'
          '// 方式 B：ChatScreen 直接傳參\n'
          'ChatScreen(bus: bus, l10n: const ChatL10nFrench())\n'
          '\n'
          '// 方式 C：跟隨系統 locale\n'
          'ChatL10nScope(\n'
          '  l10n: _fromLocale(PlatformDispatcher\n'
          '      .instance.locale),\n'
          '  child: MaterialApp(...),\n'
          ')\n'
          '// 自己寫分發函式，不改庫原始碼',
    ),
    CodeSnippet(
      '內建 vs 自訂',
      'ChatL10n 提供 3 種內建語言：\n'
          '├─ zhHans — 中文簡體 (zh-Hans)\n'
          '├─ zhHant — 中文繁體 (zh-Hant)\n'
          '└─ en   — 英文\n'
          '\n'
          '開發者新增語言只需：\n'
          '1. 繼承 ChatL10n，實現全部 getter\n'
          '2. 用 ChatL10nScope 注入\n'
          '\n'
          '不需改庫原始碼，不需程式碼產生。',
    ),
  ],
];
