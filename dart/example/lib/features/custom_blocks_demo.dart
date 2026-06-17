// 自定义块演示 — CustomBlock + BlockRegistry
//
// 展示如何注册和渲染自定义 BlockType。
// 通过 BlockRegistry.registerCustom() 将自定义块类型与 Widget builder 关联。
// 在事件流中通过 CustomBlockEvent 发射自定义块数据。
//
// 注册了两种自定义块：
//   - code_snippet：带语法高亮标题的代码片段
//   - info_card：带图标和颜色的信息卡片

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class CustomBlocksDemo extends StatefulWidget {
  const CustomBlocksDemo({super.key});

  @override
  State<CustomBlocksDemo> createState() => _CustomBlocksDemoState();
}

class _CustomBlocksDemoState extends State<CustomBlocksDemo> {
  late final ChatBus bus;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    // 注册自定义块类型（仅首次）
    _registerBlockTypes();

    bus = DefaultChatBus(
      onGenerate: _mockWithCustomBlocks,
      onInterrupt: () => _cancelled = true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDemo());
  }

  void _registerBlockTypes() {
    if (_registered) return;
    _registered = true;

    BlockRegistry.registerCustom(
      BlockDef(
        name: 'code_snippet',
        builder: _buildCodeSnippet,
        icon: Icons.code,
        dotColor: const Color(0xFF7C3AED),
        headerColor: const Color(0xFF7C3AED),
        label: '代码片段',
      ),
    );
    BlockRegistry.registerCustom(
      BlockDef(
        name: 'info_card',
        builder: _buildInfoCard,
        icon: Icons.info_outline,
        dotColor: const Color(0xFF0EA5E9),
        headerColor: const Color(0xFF0EA5E9),
        label: '信息',
      ),
    );
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
    bus.sendMessage('展示自定义块');
  }

  Stream<ExchangeEvent> _mockWithCustomBlocks(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 'think');
    const thinkText = '正在生成自定义块展示…';
    yield ThinkingDelta(id, 'think', thinkText);
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think', thinkText);
    yield TokenCount(id, 15);

    // 发射自定义块：代码片段
    yield CustomBlockEvent(
      id,
      'code_1',
      'code_snippet',
      content:
          'import "dart:math";\n\nvoid main() {\n  print("Hello, Custom Block!");\n}',
      label: 'hello.dart',
      metadata: {'language': 'dart', 'lines': 5},
    );

    // 发射自定义块：信息卡片
    yield CustomBlockEvent(
      id,
      'info_1',
      'info_card',
      content:
          '自定义块 BlockRegistry 允许你注册任意 Widget builder。\n'
          '在事件流中发射 CustomBlockEvent 即可渲染。',
      label: '使用说明',
      metadata: {'type': 'tip'},
    );

    await Future.delayed(const Duration(milliseconds: 300));
    if (_cancelled) return;

    yield ParallelBoundary(id);
    yield TokenCount(id, 42);

    // 内容回答
    yield ContentStarted(id, 'content');
    const reply = '以上是自定义块的演示效果。你可以注册任意类型的自定义块。';
    yield ContentDelta(id, 'content', reply);
    yield ContentCompleted(id, 'content', reply);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}

// ── 自定义块 Widget 构建器 ──

Widget _buildCodeSnippet(
  BuildContext ctx,
  ChatBlock block,
  ChatBus bus,
  Exchange ex,
) {
  final t = ChatTheme.of(ctx);
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      color: t.bgCard,
      border: Border.all(color: t.borderLight),
      borderRadius: BorderRadius.circular(t.radiusMd),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFF0EEFF),
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: t.textToolHeader),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  block.description ?? '代码',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: t.fontSizeMd,
                    color: t.textToolHeader,
                  ),
                ),
              ),
              if (block.toolArgs?['language'] != null)
                Chip(
                  label: Text(
                    block.toolArgs!['language'] as String,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: dark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA),
          child: SelectableText(
            block.content ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: t.fontSizeSm,
              height: 1.6,
              color: dark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoCard(
  BuildContext ctx,
  ChatBlock block,
  ChatBus bus,
  Exchange ex,
) {
  final t = ChatTheme.of(ctx);
  final dark = Theme.of(ctx).brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
      border: Border.all(
        color: dark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
      ),
      borderRadius: BorderRadius.circular(t.radiusMd),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, color: const Color(0xFF0EA5E9), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (block.description != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    block.description!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: t.fontSizeMd,
                      color: t.textToolHeader,
                    ),
                  ),
                ),
              SelectableText(
                block.content ?? '',
                style: TextStyle(
                  fontSize: t.fontSizeSm,
                  height: 1.5,
                  color: dark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
