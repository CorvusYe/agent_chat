import 'code_drawer.dart';

/// English code snippets for all 13 features.
List<List<CodeSnippet>> buildEnSnippets() => [
  // ── 0: Streaming Output ──
  [
    CodeSnippet(
      'DefaultChatBus.onGenerate',
      '// Core API: generate event stream via onGenerate callback\n'
          'bus = DefaultChatBus(\n'
          '  onGenerate: (String text) async* {\n'
          '    // 1. Thinking block — word-by-word delta\n'
          '    yield ThinkingStarted(id, \'think_1\');\n'
          '    for (...) {\n'
          '      yield ThinkingDelta(id, \'think_1\', text);\n'
          '      await Future.delayed(Duration(milliseconds: 25));\n'
          '    }\n'
          '    yield ThinkingCompleted(id, \'think_1\', fullText);\n'
          '\n'
          '    // 2. Tool call\n'
          '    yield ToolCallStarted(id, \'tool\', \'read_file\', args);\n'
          '    // ... wait for execution\n'
          '    yield ToolCallCompleted(id, \'tool\', result);\n'
          '    //        isError: true  → red error style\n'
          '    // 3. Content output — typewriter effect\n'
          '    yield ContentStarted(id, \'content\');\n'
          '    for (...) {\n'
          '      yield ContentDelta(id, \'content\', chunk);\n'
          '      await Future.delayed(Duration(milliseconds: 16));\n'
          '    }\n'
          '    yield ContentCompleted(id, \'content\', fullText);\n'
          '\n'
          '    // 4. Token stats\n'
          '    yield TokenCount(id, count);\n'
          '  },\n'
          ');',
    ),
    CodeSnippet(
      'Event Stream Lifecycle',
      'ExchangeEvent types:\n'
          '├─ ThinkingStarted / Delta / Completed  — thinking block\n'
          '├─ ToolCallStarted / Delta / Completed  — tool call\n'
          '├─ ContentStarted / Delta / Completed   — content output\n'
          '├─ ParallelBoundary                     — parallel group\n'
          '├─ TokenCount                           — token count\n'
          '├─ ExchangeError                        — error\n'
          '└─ CustomBlockEvent                     — custom block\n'
          '\n'
          'DefaultChatBus._processEventStream() consumes\n'
          'the event stream via await for (final event in stream),\n'
          'calling notifyListeners() on each event to trigger UI updates.',
    ),
    CodeSnippet(
      'Stop / Interrupt Streaming',
      '// Interrupt callback\n'
          'onInterrupt: () => _cancelled = true;\n'
          '\n'
          '// Check flag in the async* generator\n'
          'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
          '  _cancelled = false;\n'
          '  for (...) {\n'
          '    if (_cancelled) return;  // ← instantly stop yielding\n'
          '    yield ThinkingDelta(...);\n'
          '  }\n'
          '}\n'
          '\n'
          '// ChatScreen calls bus.cancelTool() internally →\n'
          '// triggers onInterrupt → _cancelled = true\n'
          '// → async* function returns → stream ends',
    ),
  ],
  // ── 1: Tool Calls ──
  [
    CodeSnippet(
      'ToolCallStarted Parameters',
      'yield ToolCallStarted(\n'
          '  exchangeId,          // parent exchange\n'
          '  blockId,             // unique block ID\n'
          '  toolName,            // tool name (e.g. read_file)\n'
          '  arguments,           // argument Map\n'
          '  requiresConfirm,     // requires user confirmation\n'
          '  autoApproved,        // auto-approved\n'
          '  description,         // confirmation dialog description\n'
          '  canAlwaysAllow,      // show "always allow" checkbox\n'
          ');',
    ),
    CodeSnippet(
      'BlockStatus State Machine',
      'BlockStatus enum values:\n'
          '├─ pending         — awaiting confirmation\n'
          '├─ running         — executing\n'
          '├─ completed       — done\n'
          '├─ cancelled       — canceled\n'
          '├─ approved        — approved\n'
          '└─ alwaysAllowed   — always allowed\n'
          '\n'
          'DefaultChatBus manages state transitions:\n'
          ' - ToolCallStarted + requiresConfirm → pending\n'
          ' - User confirmTool() → approved/running\n'
          ' - User cancelTool()  → cancelled\n'
          ' - ToolCallCompleted           → completed\n'
          ' - ToolCallCompleted(isError)  → completed + exchange failed\n'
          ' - ExchangeError               → exchange failed + error block',
    ),
    CodeSnippet(
      'ParallelBoundary Grouping',
      '// ParallelBoundary groups preceding blocks together\n'
          '// Blocks in the same group render in parallel (no index prefix)\n'
          'yield ToolCallStarted(id, \'t1\', \'tool_a\', {});\n'
          'yield ToolCallStarted(id, \'t2\', \'tool_b\', {});\n'
          'yield ParallelBoundary(id);  // ← pack t1+t2 into the same group\n'
          '// Subsequent blocks enter a new group',
    ),
  ],
  // ── 2: Confirmation Gate ──
  [
    CodeSnippet(
      'Confirmation Gate Core Flow',
      '// 1. Emit a tool that requires confirmation\n'
          'yield ToolCallStarted(id, \'tool\', \'delete_file\',\n'
          '    {\'path\': \'/tmp/cache.db\'},\n'
          '    requiresConfirm: true,\n'
          '    description: \'About to delete the cache file\',\n'
          '    canAlwaysAllow: true,  // show "always allow" checkbox\n'
          ');\n'
          '\n'
          '// 2. ChatScreen detects pending block → shows confirmation dialog\n'
          '// 3. User chooses:\n'
          '//    - Approve → bus.confirmTool(e, t, false)\n'
          '//              → status becomes approved → running\n'
          '//    - Reject → bus.cancelTool(e, t)\n'
          '//              → status becomes cancelled\n'
          '//              → triggers onInterrupt\n'
          '//    - Always allow → bus.confirmTool(e, t, true)\n'
          '//                    → added to trust list\n'
          '//                    → subsequent same tool skips confirmation',
    ),
    CodeSnippet(
      'Trust List Mechanism',
      '// DefaultChatBus maintains an internal _trustedTools set.\n'
          '// When user selects "always allow", the tool name is added:\n'
          '_trustedTools.add(toolName);\n'
          '// Subsequent same-named ToolCallStarted checks the trust list:\n'
          'final autoApproved = e.autoApproved\n'
          '    || _trustedTools.contains(e.toolName);\n'
          '// Match → skip confirmation gate, go directly to running',
    ),
    CodeSnippet(
      'Button Style (Theme Controlled)',
      'Confirmation gate buttons are styled via ChatTheme:\n'
          '\n'
          'smallButtonHeight    — button height (default 24px)\n'
          'radiusSm             — button radius (default 2px)\n'
          'fontSizeSm           — button font size (default 12px)\n'
          'buttonPadding        — button padding\n'
          'accent               — allow/always allow button color\n'
          'textSecondary        — cancel button text color\n'
          '\n'
          'In dark mode, filled button text is dark #1A1A1A,\n'
          'in light mode it is white. Outline button text = accent color,\n'
          'border = accent at 39% opacity.',
    ),
  ],
  // ── 3: Error Blocks ──
  [
    CodeSnippet(
      'yield ExchangeError',
      '// Yield ExchangeError directly in the event stream:\n'
          '\n'
          'Stream<ExchangeEvent> _mockAI(String text) async* {\n'
          '  yield ThinkingStarted(id, \'think\');\n'
          '  // ...\n'
          '  if (somethingWrong) {\n'
          '    yield ExchangeError(\n'
          '      id,                               // exchangeId\n'
          '      \'Analysis failed: target repo not found\\n\'  // error message\n'
          '      \'Please check the path.\'\n'
          '    );\n'
          '    return;  // ← must return, stream cannot continue\n'
          '  }\n'
          '  // ... normal flow\n'
          '}',
    ),
    CodeSnippet(
      'Failure State Triggers',
      'Two ways to trigger Exchange failure:\n'
          '\n'
          '// Method A: ExchangeError (shows error block)\n'
          'yield ExchangeError(id, \'message…\');\n'
          '→ sets status=failed + errorMessage\n'
          '→ ChatScreen renders "Error" header + error message\n'
          '→ collapsed header shows message summary\n'
          '\n'
          '// Method B: ToolCallCompleted(isError) (tool turns red)\n'
          'yield ToolCallCompleted(id, \'tool\', \'✗ error…\',\n'
          '    isError: true);\n'
          '→ sets status=failed, no errorMessage\n'
          '→ tool block shows error result with red border/text\n'
          '→ no extra error block (avoids duplicate info)\n'
          '\n'
          '// Both methods trigger block-level error styling:\n'
          '// _isFailed(exchange) → thinking/tool/content\n'
          '// all block text turns theme.error red',
    ),
  ],
  // ── 4: Queue Mode ──
  [
    CodeSnippet(
      'Full Queue Decorator Source',
      'class _QueueDecorator with ChangeNotifier\n'
          '    implements ChatBus {\n'
          '  final ChatBus _inner;\n'
          '  final List<String> _queue = [];\n'
          '  bool _wasStreaming = false;\n'
          '\n'
          '  _QueueDecorator(this._inner) {\n'
          '    _inner.addListener(_onChanged);  // ① Listen to stream state\n'
          '  }\n'
          '\n'
          '  // ── ② Auto-drain when stream state changes ──\n'
          '  void _onChanged() {\n'
          '    // Moment stream goes from "streaming" → "idle"\n'
          '    if (_wasStreaming && !_inner.isStreaming) {\n'
          '      _drain();  // ③ Drain next item in queue\n'
          '    }\n'
          '    _wasStreaming = _inner.isStreaming;\n'
          '    notifyListeners();\n'
          '  }\n'
          '\n'
          '  // ── ③ Drain: take next and send ──\n'
          '  void _drain() {\n'
          '    if (_queue.isNotEmpty) {\n'
          '      _inner.sendMessage(_queue.removeAt(0));\n'
          '      // drain sends only one; next _onChanged\n'
          '      // triggers another drain until queue is empty\n'
          '    }\n'
          '  }\n'
          '\n'
          '  // ── ④ sendMessage: intercept and queue logic ──\n'
          '  @override\n'
          '  void sendMessage(String text) {\n'
          '    if (_inner.isStreaming) {\n'
          '      // AI is generating → block send, enqueue message\n'
          '      _queue.add(text);\n'
          '      return;  // ← key: directly return, don\'t call inner\n'
          '    }\n'
          '    // Queue not empty: take one from queue first, new message goes to tail\n'
          '    if (_queue.isNotEmpty) {\n'
          '      _inner.sendMessage(_queue.removeAt(0));\n'
          '      _queue.add(text);\n'
          '      return;\n'
          '    }\n'
          '    // Queue empty + no streaming → send normally\n'
          '    _inner.sendMessage(text);\n'
          '  }\n'
          '\n'
          '  // All state delegated to _inner\n'
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
      'Flow: Enqueue → Block → Drain',
      'Timeline (user sends 3 messages in a row):\n'
          '┌─────────────────────────────────────────────────┐\n'
          '│  sendMessage("Request 1")                       │\n'
          '│  → isStreaming=false, queue empty               │\n'
          '│  → send to inner directly → AI starts streaming │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  sendMessage("Request 2") ← user sends again    │\n'
          '│  → isStreaming=true                             │\n'
          '│  → blocked! _queue.add("Request 2")  ░░░ queued │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  sendMessage("Request 3") ← user sends again    │\n'
          '│  → isStreaming=true                             │\n'
          '│  → blocked! _queue.add("Request 3")  ░░░ queued │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI stream ends → _onChanged fires              │\n'
          '│  → _drain() → take queue[0]="Request 2" to inner│\n'
          '│  → AI starts streaming "Request 2"...           │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI stream ends → _drain() → take "Request 3"   │\n'
          '│  → AI streams "Request 3"                       │\n'
          '├─────────────────────────────────────────────────┤\n'
          '│  AI stream ends → _drain() → queue empty → stop │\n'
          '└─────────────────────────────────────────────────┘',
    ),
    CodeSnippet(
      'Integration',
      'bus = ChatBus.withDecorators(\n'
          '  impl: DefaultChatBus(onGenerate: _mockAI),\n'
          '  decorators: [\n'
          '    (inner) => _QueueDecorator(inner),\n'
          '  ],\n'
          ');\n'
          '\n'
          '// Queue-exposed status:\n'
          'bus.queueItems  → List<String>   // queued messages\n'
          'bus.queueCount  → int            // queue length\n'
          'bus.isStreaming → bool           // currently streaming\n'
          '\n'
          '// ChatScreen built-in queue popup:\n'
          '// StatsBar button on the right → toggleQueue()\n'
          '// Shows _QueuePopupContent listing queueItems',
    ),
  ],
  // ── 5: Input Modes ──
  [
    CodeSnippet(
      'ChatScreen Parameters',
      'ChatScreen(\n'
          '  bus: bus,                    // required: ChatBus\n'
          '  theme: myChatTheme,          // optional: custom ChatTheme\n'
          '  loadingIndicator: ...,       // optional: loading view\n'
          '  emptyPlaceholder: ...,       // optional: empty list view\n'
          ')\n'
          '\n'
          'ChatScreen builds the complete chat UI internally:\n'
          '├─ Message list (CustomScrollView + Sliver)\n'
          '├─ Input field (AutoResizeTextField)\n'
          '├─ StatsBar\n'
          '└─ Queue popup',
    ),
    CodeSnippet(
      'Input Field Core Properties',
      'AutoResizeTextField(\n'
          '  controller,   // TextEditingController\n'
          '  hintText,     // placeholder hint\n'
          '  onChanged,    // text change callback\n'
          ')\n'
          '\n'
          'Auto-resizing multi-line input field supports:\n'
          ' - Enter to send, Shift+Enter for newline\n'
          ' - Auto height (minLines / maxLines)\n'
          ' - Send button + optional Queue/Token buttons',
    ),
  ],
  // ── 6: History Loading ──
  [
    CodeSnippet(
      'Exchange Model',
      'Exchange(\n'
          '  id: \'ex_001\',            // unique ID\n'
          '  userMessage: \'Hello\',    // user message\n'
          '  timestamp: DateTime.now(),\n'
          '  groups: [                  // BlockGroup list\n'
          '    BlockGroup(id: \'g1\', blocks: [\n'
          '      ChatBlock(id: \'b1\', type: BlockType.thinking,\n'
          '          content: \'Thinking…\',\n'
          '          status: BlockStatus.completed),\n'
          '      ChatBlock(id: \'b2\', type: BlockType.content,\n'
          '          content: \'Reply content\',\n'
          '          status: BlockStatus.completed),\n'
          '    ]),\n'
          '  ],\n'
          '  status: ExchangeStatus.completed,\n'
          '  errorMessage: null,        // set on failure\n'
          ')\n'
          '\n'
          'ExchangeStatus: completed / processing /\n'
          '                  waitingInput / cancelled / failed',
    ),
    CodeSnippet(
      'ChatBus.exchanges',
      '// Read-only history list\n'
          'List<Exchange> get exchanges;\n'
          '\n'
          '// New messages are added via sendMessage(),\n'
          '// DefaultChatBus auto-creates an Exchange\n'
          '// and appends it to the _exchanges list.\n'
          '\n'
          '// isLoadingHistory controls loading state\n'
          'bool get isLoadingHistory;\n'
          '// → true: ChatScreen shows loadingIndicator\n'
          '// → false: shows normal message list',
    ),
  ],
  // ── 7: Custom Blocks ──
  [
    CodeSnippet(
      'BlockDef — One-shot Registration',
      '// BlockDef bundles style + builder:\n'
          'BlockRegistry.registerCustom(BlockDef(\n'
          '  name: \'code_snippet\',      // type name\n'
          '  builder: _buildCodeSnippet, // Widget builder\n'
          '  icon: Icons.code,           // header icon\n'
          '  dotColor: Color(0xFF7C3AED),// dot color\n'
          '  headerColor: Color(0xFF7C3AED),// header color\n'
          '  label: \'Code Snippet\',      // label\n'
          '));\n'
          '\n'
          '// No need to call registerCustom + registerStyle separately,\n'
          '// a single BlockDef completes all registration.\n'
          '\n'
          '// Widget builder signature:\n'
          'typedef CustomBlockBuilder = Widget Function(\n'
          '  BuildContext context,\n'
          '  ChatBlock block,\n'
          '  ChatBus bus,\n'
          '  Exchange exchange,\n'
          ');',
    ),
    CodeSnippet(
      'CustomBlockEvent Emission',
      '// Emit a custom block in the event stream\n'
          'yield CustomBlockEvent(\n'
          '  exchangeId,\n'
          '  \'code_1\',\n'
          '  \'code_snippet\',                // matches registerCustom name\n'
          '  content: \'```dart\\nvoid main() {\\n  print("hello");\\n}\\n```\',\n'
          '  label: \'hello.dart\',          // display title\n'
          '  status: BlockStatus.completed,\n'
          '  metadata: {\'language\': \'dart\'},\n'
          ');\n'
          '\n'
          '// DefaultChatBus processing:\n'
          '// CustomBlockEvent → creates ChatBlock(\n'
          '//   type: BlockType.custom(typeName)\n'
          '// ) → appends to pendingBlocks\n'
          '// → notifyListeners → UI renders',
    ),
  ],
  // ── 8: Theme Gallery ──
  [
    CodeSnippet(
      'ChatTheme Structure',
      'ChatTheme extends ThemeExtension<ChatTheme>,\n'
          'contains ~70 properties organized in 8 categories:\n'
          '├─ Background  — bgPrimary / bgSurface / bgCard …\n'
          '├─ Text color  — textPrimary / textContent …\n'
          '├─ Accent      — accent / accentHover / success / error\n'
          '├─ Border      — border / borderLight / borderAccent\n'
          '├─ Status dots — dotThinking / dotTool / dotContent\n'
          '├─ Spacing     — spacingXs ~ spacingXl / blockPadding\n'
          '├─ Radius      — radiusSm ~ radiusXl\n'
          '└─ Animation   — breathingDuration / rotationDuration',
    ),
    CodeSnippet(
      'ThemeData Registration',
      '// Register ChatTheme as a ThemeExtension:\n'
          'MaterialApp(\n'
          '  theme: ThemeData(\n'
          '    brightness: Brightness.light,\n'
          '    extensions: [ChatThemes.fluent],  // ← for light\n'
          '  ),\n'
          '  darkTheme: ThemeData(\n'
          '    brightness: Brightness.dark,\n'
          '    extensions: [ChatThemes.fluentDark],  // ← for dark\n'
          '  ),\n'
          ')\n'
          '\n'
          'ChatScreen retrieves it via ChatTheme.of(context):\n'
          'return Theme.of(context).extension<ChatTheme>()\n'
          '    ?? _fallback;',
    ),
    CodeSnippet(
      'Built-in Themes',
      'ChatThemes provides 6 built-in themes (3 types × dark/light):\n'
          '├─ ChatThemes.fluent          — Fluent 2 light\n'
          '├─ ChatThemes.fluentDark      — Fluent 2 dark\n'
          '├─ ChatThemes.light           — Default light (purple)\n'
          '├─ ChatThemes.dark            — Default dark (purple)\n'
          '├─ ChatThemes.neumorphicLight — Neumorphism light\n'
          '└─ ChatThemes.neumorphicDark  — Neumorphism dark\n'
          '\n'
          'You can also use ChatTheme(...) to construct any custom theme.',
    ),
  ],
  // ── 9: Custom Theme ──
  [
    CodeSnippet(
      'macOS Light Theme (Full)',
      'ChatTheme macOSLightTheme() => ChatTheme(\n'
          '  bgPrimary: Color(0xFFF5F5F7),     // off-white bg\n'
          '  bgSurface: Color(0xFFFFFFFF),\n'
          '  bgInput: Color(0xFFE8E8ED),\n'
          '  bgCard: Color(0xFFFFFFFF),\n'
          '  bgCardHeader: Color(0xFFF0F0F5),\n'
          '  bgCommand: Color(0xFFF0F0F5),\n'
          '  textPrimary: Color(0xFF1D1D1F),   // near-black\n'
          '  textContent: Color(0xFF1D1D1F),\n'
          '  textSecondary: Color(0xFF86868B),\n'
          '  textToolHeader: Color(0xFF007AFF), // macOS blue\n'
          '  accent: Color(0xFF007AFF),\n'
          '  accentHover: Color(0xFF0066D6),\n'
          '  success: Color(0xFF34C759),\n'
          '  error: Color(0xFFFF3B30),\n'
          '  warning: Color(0xFFFF9500),\n'
          '  border: Color(0xFFD2D2D7),\n'
          '  borderLight: Color(0xFFE5E5EA),\n'
          '  btnSecondaryBg: Color(0x1F007AFF),\n'
          '  // ... other properties use defaults (from ChatTheme constructor)\n'
          ');',
    ),
    CodeSnippet(
      'macOS Dark Theme (Full)',
      'ChatTheme macOSDarkTheme() => ChatTheme(\n'
          '  bgPrimary: Color(0xFF1C1C1E),     // dark gray bg\n'
          '  bgSurface: Color(0xFF2C2C2E),\n'
          '  bgInput: Color(0xFF3A3A3C),\n'
          '  bgCard: Color(0xFF2C2C2E),\n'
          '  bgCardHeader: Color(0xFF363638),\n'
          '  bgCommand: Color(0xFF363638),\n'
          '  textPrimary: Color(0xFFF5F5F7),   // near-white\n'
          '  textContent: Color(0xFFF5F5F7),\n'
          '  textSecondary: Color(0xFF98989D),\n'
          '  textToolHeader: Color(0xFF64B5F6), // light blue\n'
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
      'Usage',
      '// Local override with Theme widget:\n'
          'Theme(\n'
          '  data: ThemeData(\n'
          '    brightness: Brightness.dark,\n'
          '    extensions: [macOSDarkTheme()],\n'
          '  ),\n'
          '  child: ChatScreen(bus: bus),\n'
          ')\n'
          '\n'
          '// Or global registration:\n'
          'MaterialApp(\n'
          '  theme: ThemeData(extensions: [macOSLightTheme()]),\n'
          '  darkTheme: ThemeData(extensions: [macOSDarkTheme()]),\n'
          ')\n'
          '\n'
          '// Each theme has ~20 core color properties; others use defaults.\n'
          '// ChatTheme has ~70 properties total; unspecified ones use\n'
          '// constructor defaults.',
    ),
  ],
  // ── 10: Collapse / Expand ──
  [
    CodeSnippet(
      'Default Collapse Rules',
      'ChatScreen._isCollapsed() default strategy:\n'
          '\n'
          'bool _isCollapsed(ChatBlock block, Exchange exchange) {\n'
          '  // ① User manually expanded → don\'t collapse\n'
          '  if (_manuallyExpandedKeys.contains(key))\n'
          '    return false;\n'
          '  // ② User manually collapsed → collapse\n'
          '  if (_manuallyCollapsedKeys.contains(key))\n'
          '    return true;\n'
          '\n'
          '  // ③ Sibling running/pending blocks in the same group → expand\n'
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
          '  // ④ Latest block → expand, historical block → collapse\n'
          '  return !_isLatestBlock(block, exchange);\n'
          '}',
    ),
    CodeSnippet(
      'Manual Toggle: Click Header',
      'When user clicks a block header, _handleToggle() fires:\n'
          '\n'
          'void _handleToggle() {\n'
          '  final newExpanded = !_expanded;\n'
          '  setState(() => _expanded = newExpanded);\n'
          '  // Notify parent to record manual state\n'
          '  widget.onCollapsedChanged?.call(\n'
          '    widget.block.id, newExpanded);\n'
          '}\n'
          '\n'
          '// ChatScreen records manual state in sets:\n'
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
      'Same-Group Parallel Force Expand',
      'When a ParallelBoundary group has running blocks:\n'
          '\n'
          'yield ToolCallStarted(id, \'t1\', \'search\', {});\n'
          'yield ToolCallStarted(id, \'t2\', \'cache\', {});\n'
          'yield ParallelBoundary(id);  // ← pack as same group\n'
          '\n'
          '// → t1 and t2 belong to the same BlockGroup\n'
          '// → as long as t2 is still running, the whole group stays expanded\n'
          '// → even if t1 is done, user won\'t see it collapsed\n'
          '// → when all complete, reverts to default rules\n'
          '\n'
          '// This is implemented via _isCollapsed\'s "same-group check":\n'
          'group.blocks.any((b) =>\n'
          '  b.status == BlockStatus.running ||\n'
          '  b.status == BlockStatus.pending\n'
          ') → return false (don\'t collapse)',
    ),
    CodeSnippet(
      'Via CustomBlockEvent / External Control',
      '// Currently ChatScreen collapse state is entirely UI-driven.\n'
          '// You can trigger collapse/expand from outside via:\n'
          '\n'
          '// Method A: Use CustomBlockEvent to carry a marker\n'
          '// Emit a metadata event in your stream, have ChatScreen\'s\n'
          '// listener extract it and call _onToggleCollapsed().\n'
          '\n'
          '// Method B: Subclass ChatScreen and override _isCollapsed,\n'
          '// or use blockRegistry to customize collapsed parameter.\n'
          '\n'
          '// Method C: Manipulate the collapsedBlockIds set directly\n'
          '// (requires access to ChatScreen internal state, not exposed yet)\n'
          '// But you can implement your own ChatBus listener\n'
          '// to respond to specific events and trigger a rebuild.',
    ),
  ],
  // ── 11: Stats Bar ──
  [
    CodeSnippet(
      'StatsBar Metrics',
      'StatsBar displays ChatBus statistics:\n'
          '├─ totalTokens: int         — accumulated tokens\n'
          '├─ elapsed: Duration?       — current/last session duration\n'
          '├─ queueCount: int          — queue length\n'
          '├─ activeExchangeCount: int — active Exchange count\n'
          '└─ isLoadingHistory: bool   — loading history flag\n'
          '\n'
          'Usage:\n'
          'StatsBar(totalTokens: bus.totalTokens)\n'
          '// Auto-listens to bus changes to update display',
    ),
    CodeSnippet(
      'Token Counting Mechanism',
      '// Emit tokens in the event stream:\n'
          'yield TokenCount(id, 156);  // accumulates to totalTokens\n'
          '\n'
          '// Programmatic increment:\n'
          'bus.addTokens(100);\n'
          '\n'
          '// Read:\n'
          'int get totalTokens => _totalTokens;\n'
          '\n'
          '// Timing:\n'
          '// DefaultChatBus records _startTime when the first\n'
          '// Exchange begins, and _lastElapsed when streaming ends\n'
          'Duration? get elapsed => _startTime != null\n'
          '    ? DateTime.now().difference(_startTime!)\n'
          '    : _lastElapsed;',
    ),
  ],
  // ── 12: Custom Language ──
  [
    CodeSnippet(
      'ChatL10nFrench — Extend Abstract Class',
      'class ChatL10nFrench extends ChatL10n {\n'
          '  const ChatL10nFrench();\n'
          '\n'
          '  @override String get emptyChatHint\n'
          '      => \'Envoyez un message pour commencer\';\n'
          '  @override String get inputHint\n'
          '      => \'Entrez un message…\';\n'
          '  @override String get expandAll => \'Tout développer\';\n'
          '  @override String get collapse => \'Réduire\';\n'
          '  // … Compiler enforces all 20+ getters …\n'
          '  @override String get btnCancel => \'Annuler\';\n'
          '}',
    ),
    CodeSnippet(
      'ChatL10nScope Injection',
      '// Method A: Global Scope, affects all widgets in the subtree\n'
          'ChatL10nScope(\n'
          '  l10n: const ChatL10nFrench(),\n'
          '  child: ChatScreen(bus: bus),\n'
          ')\n'
          '\n'
          '// Method B: ChatScreen direct parameter\n'
          'ChatScreen(bus: bus, l10n: const ChatL10nFrench())\n'
          '\n'
          '// Method C: Follow system locale\n'
          'ChatL10nScope(\n'
          '  l10n: _fromLocale(PlatformDispatcher\n'
          '      .instance.locale),\n'
          '  child: MaterialApp(...),\n'
          ')\n'
          '// Write your own dispatch function, no library source changes',
    ),
    CodeSnippet(
      'Built-in vs Custom',
      'ChatL10n provides 3 built-in languages:\n'
          '├─ zhHans — Simplified Chinese (zh-Hans)\n'
          '├─ zhHant — Traditional Chinese (zh-Hant)\n'
          '└─ en   — English\n'
          '\n'
          'To add a new language you only need:\n'
          '1. Extend ChatL10n, implement all getters\n'
          '2. Inject with ChatL10nScope\n'
          '\n'
          'No library source changes needed, no code generation.',
    ),
  ],
];
