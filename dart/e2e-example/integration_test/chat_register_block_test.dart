import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:agent_chat/agent_chat.dart';
import 'mock_utils.dart';

/// Integration test: BlockRegistry.register() and BlockType.custom().
///
/// Tests:
///   - Override a built-in type (thinking) after initial render
///   - Register a brand-new custom type (weather) via BlockType.custom()
///   - Multiple custom types rendering in separate exchanges
///   - Override another built-in type (tool)
///   - Custom block with interactive button
///   - Custom block triggering ChatBus operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BlockRegistry — 注册自定义 Block', () {
    // ═══════════════════════════════════════════════════════
    //  1. Override built-in thinking block type
    // ═══════════════════════════════════════════════════════
    testWidgets('覆盖 thinking 内置类型', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // Send a message first to trigger _ensureBuiltins() in BlockRegistry.build()
      bus.sendMessage('第一条消息');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 1);

      // Now override the thinking block builder.
      // _ensureBuiltins() already ran, so our register() won't be overwritten.
      BlockRegistry.register(BlockType.thinking, (ctx, block, bus, ex) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('CUSTOM_THINKING: ${block.content ?? ''}'),
        );
      });

      // Send second message — should use the custom thinking builder
      bus.sendMessage('第二条消息');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 2);

      // Custom thinking widget rendered
      expect(find.textContaining('CUSTOM_THINKING:'), findsAtLeastNWidgets(1));

      // Content block still uses default builder
      expect(find.text('处理完成。'), findsAtLeastNWidgets(1));

      // Stats bar visible (sanity check)
      expectStatsBarVisible(tester);
    });

    // ═══════════════════════════════════════════════════════
    //  2. Register a brand-new custom block type
    // ═══════════════════════════════════════════════════════
    testWidgets('注册 BlockType.custom 天气块', (tester) async {
      // Register BEFORE pumpWidget.  Safe because _ensureBuiltins() only
      // registers the 4 built-in types (thinking, tool, content, confirmation)
      // and does NOT touch custom types.
      BlockRegistry.register(BlockType.custom('weather'), (
        ctx,
        block,
        bus,
        ex,
      ) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A5C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text('☀️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    block.content ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (block.toolResult != null)
                    Text(
                      block.toolResult!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      });

      // Create a test bus pre-loaded with a custom block
      final bus = _TestCustomBus();
      bus.loadExchange(
        Exchange(
          id: 'ex_weather',
          userMessage: '查看北京天气',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g1',
              blocks: [
                ChatBlock(
                  id: 'b1',
                  type: BlockType.custom('weather'),
                  content: '北京',
                  toolResult: '晴, 25°C, 湿度 45%',
                ),
              ],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // User message visible
      expect(find.text('查看北京天气'), findsOneWidget);

      // Custom weather block content (single block → expanded)
      expect(find.text('北京'), findsOneWidget);
      expect(find.text('晴, 25°C, 湿度 45%'), findsOneWidget);

      // Custom block header label (custom type with no toolName → "自定义")
      expect(find.text('自定义'), findsAtLeastNWidgets(1));
    });

    // ═══════════════════════════════════════════════════════
    //  3. Multiple custom types in separate exchanges
    // ═══════════════════════════════════════════════════════
    testWidgets('多个自定义类型同时渲染', (tester) async {
      // Register 3 custom types
      BlockRegistry.register(BlockType.custom('weather'), (
        ctx,
        block,
        bus,
        ex,
      ) {
        return Text('🌤 ${block.content}');
      });
      BlockRegistry.register(BlockType.custom('stock'), (ctx, block, bus, ex) {
        return Text('📈 ${block.content}');
      });
      BlockRegistry.register(BlockType.custom('news'), (ctx, block, bus, ex) {
        return Text('📰 ${block.content}');
      });

      // Each type gets its own exchange so the block is always the latest (expanded)
      final bus = _TestCustomBus();
      bus.loadExchange(
        Exchange(
          id: 'ex_w',
          userMessage: '天气查询',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g1',
              blocks: [
                ChatBlock(
                  id: 'b1',
                  type: BlockType.custom('weather'),
                  content: '晴, 28°C',
                ),
              ],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );
      bus.loadExchange(
        Exchange(
          id: 'ex_s',
          userMessage: '股票查询',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g2',
              blocks: [
                ChatBlock(
                  id: 'b2',
                  type: BlockType.custom('stock'),
                  content: 'AAPL: \$198, GOOG: \$175',
                ),
              ],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );
      bus.loadExchange(
        Exchange(
          id: 'ex_n',
          userMessage: '新闻摘要',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g3',
              blocks: [
                ChatBlock(
                  id: 'b3',
                  type: BlockType.custom('news'),
                  content: 'AI 技术取得新突破',
                ),
              ],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // All custom content visible (each is the only block in its exchange → expanded)
      expect(find.text('🌤 晴, 28°C'), findsOneWidget);
      expect(find.text('📈 AAPL: \$198, GOOG: \$175'), findsOneWidget);
      expect(find.text('📰 AI 技术取得新突破'), findsOneWidget);

      // User messages visible
      expect(find.text('天气查询'), findsOneWidget);
      expect(find.text('股票查询'), findsOneWidget);
      expect(find.text('新闻摘要'), findsOneWidget);
    });

    // ═══════════════════════════════════════════════════════
    //  4. Override tool type with custom widget
    // ═══════════════════════════════════════════════════════
    testWidgets('覆盖 tool 内置类型', (tester) async {
      final bus = DefaultChatBus(onGenerate: createSmartMockAI());

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );

      // First exchange to trigger _ensureBuiltins()
      bus.sendMessage('你好');
      await waitForAICompletion(tester);
      expect(bus.exchanges.length, 1);

      // Override tool builder
      BlockRegistry.register(BlockType.tool, (ctx, block, bus, ex) {
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.blueGrey.shade900,
          child: Text(
            '🛠 ${block.toolName ?? "工具"}: ${block.toolResult ?? ""}',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      });

      // Send "code analysis" message — triggers multi-tool blocks
      bus.sendMessage('分析项目的代码质量');
      await waitForAICompletion(tester);

      // Custom tool block content rendered
      expect(find.textContaining('🛠'), findsAtLeastNWidgets(1));

      // Content block still uses default builder
      expect(find.text('处理完成。'), findsAtLeastNWidgets(1));
    });

    // ═══════════════════════════════════════════════════════
    //  5. Custom block with user interaction
    // ═══════════════════════════════════════════════════════
    testWidgets('自定义 Block 中的按钮交互', (tester) async {
      int buttonClicks = 0;

      BlockRegistry.register(BlockType.custom('counter'), (
        ctx,
        block,
        bus,
        ex,
      ) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => buttonClicks++,
            child: Text('点击 ($buttonClicks)'),
          ),
        );
      });

      final bus = _TestCustomBus();
      bus.loadExchange(
        Exchange(
          id: 'ex_counter',
          userMessage: '计数器测试',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g1',
              blocks: [
                ChatBlock(
                  id: 'b1',
                  type: BlockType.custom('counter'),
                  content: '点击按钮计数',
                ),
              ],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Button visible with initial count
      expect(find.text('点击 (0)'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('点击 (0)'));
      await tester.pump();

      // Callback was invoked
      expect(buttonClicks, 1);
    });

    // ═══════════════════════════════════════════════════════
    //  6. Custom block that triggers ChatBus operations
    // ═══════════════════════════════════════════════════════
    testWidgets('自定义 Block 触发总线操作', (tester) async {
      BlockRegistry.register(BlockType.custom('action'), (ctx, block, bus, ex) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => bus.addTokens(50),
            child: const Text('添加 Token'),
          ),
        );
      });

      final bus = _TestCustomBus();
      bus.loadExchange(
        Exchange(
          id: 'ex_action',
          userMessage: '操作测试',
          timestamp: DateTime.now(),
          groups: [
            BlockGroup(
              id: 'g1',
              blocks: [ChatBlock(id: 'b1', type: BlockType.custom('action'))],
            ),
          ],
          status: ExchangeStatus.completed,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark),
          home: ChatScreen(bus: bus),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Button visible
      expect(find.text('添加 Token'), findsOneWidget);

      // Initial token count is 0
      expect(bus.totalTokens, 0);

      // Tap button to call bus.addTokens(50)
      await tester.tap(find.text('添加 Token'));
      await tester.pump();

      // Tokens added via bus
      expect(bus.totalTokens, 50);
    });
  });
}

// ═══════════════════════════════════════════════════════
//  Test helper: Custom ChatBus that pre-loads exchanges.
//
//  Unlike DefaultChatBus (which requires AI event streams),
//  this allows us to inject Exchange objects with custom blocks
//  directly — essential for testing BlockType.custom().
// ═══════════════════════════════════════════════════════

class _TestCustomBus extends ChangeNotifier implements ChatBus {
  final List<Exchange> _exchanges = [];
  int _totalTokens = 0;

  void loadExchange(Exchange exchange) {
    _exchanges.add(exchange);
    notifyListeners();
  }

  @override
  List<Exchange> get exchanges => List.unmodifiable(_exchanges);

  @override
  bool get isLoadingHistory => false;

  @override
  bool get isStreaming => false;

  @override
  List<String> get queueItems => [];

  @override
  int get queueCount => 0;

  @override
  int get totalTokens => _totalTokens;

  @override
  Duration? get elapsed => null;

  @override
  int get activeExchangeCount => 0;
  @override
  late final ValueNotifier<int> attentionSignal = ValueNotifier<int>(0);

  @override
  void sendMessage(String text) {}

  @override
  void confirmTool(String exchangeId, String toolName, bool alwaysAllow) {}

  @override
  void cancelTool(String exchangeId, String toolName) {}

  @override
  void toggleQueue() {}

  @override
  void addTokens(int count) {
    _totalTokens += count;
    notifyListeners();
  }

  @override
  void acceptEvents(String exchangeId, Stream<ExchangeEvent> events) {}

  @override
  void init() {}

  // dispose inherited from ChangeNotifier is sufficient
}
