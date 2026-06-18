import 'package:flutter/material.dart';
import '../models/chat_block.dart';
import '../models/exchange.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';

/// BlockDef — 自定义 Block 类型的完整定义。
///
/// 同时描述视觉样式（颜色、图标、标签）和渲染逻辑（builder），
/// 通过 [BlockRegistry.registerCustom] 一次性注册。
class BlockDef {
  /// 类型名称，对应 [ChatBlock.type] 的 name。
  final String name;

  /// 渲染构造器。
  final BlockWidgetBuilder builder;

  /// 圆点颜色（时间线上）。
  final Color dotColor;

  /// 头部文字颜色。
  final Color headerColor;

  /// 头部图标。
  final IconData icon;

  /// 头部标签文本。
  final String label;

  const BlockDef({
    required this.name,
    required this.builder,
    required this.dotColor,
    required this.headerColor,
    required this.icon,
    required this.label,
  });
}

/// BlockWidgetBuilder 签名。
/// context — 构建上下文
/// block — 要渲染的 block 数据
/// bus — 外壳总线，用于触发 confirm/cancel 等
/// exchange — 所属 exchange，用于获取上下文
typedef BlockWidgetBuilder =
    Widget Function(
      BuildContext context,
      ChatBlock block,
      ChatBus bus,
      Exchange exchange,
    );

/// BlockRegistry — 可插拔的 block 渲染器注册表。
///
/// 内置类型自动注册到默认构造器，用户可以随时调用 [register] 替换或新增：
///
/// ```dart
/// BlockRegistry.register(BlockType.tool, (ctx, block, bus, ex) => MyToolWidget(block));
/// ```
///
/// 自定义 Block 类型通过 [registerCustom] 一次性注册定义（含样式 + 构造器）：
///
/// ```dart
/// BlockRegistry.registerCustom(BlockDef(
///   name: 'code_snippet',
///   builder: _buildCodeSnippet,
///   icon: Icons.code,
///   dotColor: Color(0xFF7C3AED),
///   headerColor: Color(0xFF7C3AED),
///   label: '代码片段',
/// ));
/// ```
class BlockRegistry {
  BlockRegistry._();

  static final Map<String, BlockWidgetBuilder> _registry = {};
  static final Map<String, BlockDef> _defs = {};
  static bool _builtinsRegistered = false;

  static void _ensureBuiltins() {
    if (_builtinsRegistered) return;
    _builtinsRegistered = true;

    register(BlockType.thinking, _defaultThinkingBuilder);
    register(BlockType.tool, _defaultToolBuilder);
    register(BlockType.content, _defaultContentBuilder);
    register(BlockType.confirmation, _defaultConfirmBuilder);
  }

  /// 注册或覆盖内置类型的构造器。
  static void register(BlockType type, BlockWidgetBuilder builder) {
    _registry[type.name] = builder;
  }

  /// 注册自定义 Block 类型（样式 + 构造器一次性完成）。
  ///
  /// 注册后 [ExchangeWidget] 自动使用 [BlockDef] 中的
  /// 图标、颜色、标签来渲染时间线上的圆点和头部。
  static void registerCustom(BlockDef def) {
    _registry[def.name] = def.builder;
    _defs[def.name] = def;
  }

  /// 获取内置类型的构造器。
  static BlockWidgetBuilder? get(BlockType type) => _registry[type.name];

  /// 获取自定义类型的构造器。
  static BlockWidgetBuilder? getCustom(String name) => _registry[name];

  /// 获取自定义类型的完整定义（含样式 + 构造器）。
  static BlockDef? getDef(BlockType type) => _defs[type.name];

  /// 构建 block widget。
  static Widget build(
    BuildContext context,
    ChatBlock block,
    ChatBus bus,
    Exchange exchange,
  ) {
    _ensureBuiltins();
    final builder = _registry[block.type.name];
    if (builder == null) return const SizedBox.shrink();
    return builder(context, block, bus, exchange);
  }
}

// ═══════════════════════════════════════════════════════
//  默认 Block 构造器
// ═══════════════════════════════════════════════════════

Widget _defaultThinkingBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  return _ThinkingBlock(block: block);
}

Widget _defaultToolBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  if (block.requiresConfirm && block.status == BlockStatus.pending) {
    return _ConfirmGate(block: block, bus: bus, exchangeId: exchange.id);
  }
  return _ToolBlock(block: block);
}

Widget _defaultContentBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  return _ContentBlock(block: block);
}

Widget _defaultConfirmBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  return _ConfirmGate(block: block, bus: bus, exchangeId: exchange.id);
}

// ═══════════════════════════════════════════════════════
//  Thinking Block
// ═══════════════════════════════════════════════════════

class _ThinkingBlock extends StatelessWidget {
  final ChatBlock block;
  const _ThinkingBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Text(
        block.content ?? '',
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: theme.fontSizeMd,
          height: 1.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Tool Block
// ═══════════════════════════════════════════════════════

class _ToolBlock extends StatelessWidget {
  final ChatBlock block;
  const _ToolBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.bgCard,
        border: Border.all(color: theme.borderLight),
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacingMd,
              vertical: theme.spacingXs + 2,
            ),
            color: theme.bgCardHeader,
            child: Row(
              children: [
                Text(
                  block.toolName ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                    fontSize: theme.fontSizeMd,
                    color: theme.textToolHeader,
                  ),
                ),
                if (block.toolArgs != null && block.toolArgs!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      block.toolArgs!.toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: theme.fontSizeSm,
                        color: theme.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
          if (block.toolResult != null && block.toolResult!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(theme.spacingMd),
              color: isDark ? const Color(0x1A000000) : const Color(0x0A000000),
              child: Text(
                block.toolResult!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: theme.fontSizeSm,
                  height: 1.5,
                  color: theme.textToolResult,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Content Block
// ═══════════════════════════════════════════════════════

class _ContentBlock extends StatelessWidget {
  final ChatBlock block;
  const _ContentBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final content = block.content;
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    final theme = ChatTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Text(
        content,
        style: TextStyle(
          color: theme.textContent,
          fontSize: theme.fontSizeLg,
          height: 1.6,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Confirm Gate
// ═══════════════════════════════════════════════════════

class _ConfirmGate extends StatelessWidget {
  final ChatBlock block;
  final ChatBus bus;
  final String exchangeId;
  const _ConfirmGate({
    required this.block,
    required this.bus,
    required this.exchangeId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: theme.bgCard,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (block.description != null || block.toolName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  if (block.toolName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        block.toolName!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: theme.fontSizeSm,
                          color: theme.textToolHeader,
                        ),
                      ),
                    ),
                  if (block.description != null)
                    Expanded(
                      child: Text(
                        block.description!,
                        style: TextStyle(
                          color: theme.textContent,
                          fontSize: theme.fontSizeSm,
                          height: 1.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (block.toolArgs != null && block.toolArgs!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        block.toolArgs!.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: theme.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _CompactBtn(
                label: '允许',
                filled: true,
                color: theme.accent,
                onPressed: () =>
                    bus.confirmTool(exchangeId, block.toolName ?? '', false),
              ),
              if (block.canAlwaysAllow)
                _CompactBtn(
                  label: '始终允许',
                  filled: false,
                  color: theme.accent,
                  onPressed: () =>
                      bus.confirmTool(exchangeId, block.toolName ?? '', true),
                ),
              _CompactBtn(
                label: '取消',
                filled: false,
                color: theme.textSecondary,
                onPressed: () =>
                    bus.cancelTool(exchangeId, block.toolName ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onPressed;
  const _CompactBtn({
    required this.label,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: filled ? color : Colors.transparent,
          foregroundColor: filled
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white)
              : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: filled
                ? BorderSide.none
                : BorderSide(color: color.withAlpha(100)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
