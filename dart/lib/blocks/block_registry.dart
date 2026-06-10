import 'package:flutter/material.dart';
import '../models/chat_block.dart';
import '../models/exchange.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';

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
/// BlockRegistry.register(BlockType.custom, (ctx, block, bus, ex) => MyCustomWidget(block));
/// ```
class BlockRegistry {
  BlockRegistry._();

  static final Map<String, BlockWidgetBuilder> _registry = {};
  static bool _builtinsRegistered = false;

  static void _ensureBuiltins() {
    if (_builtinsRegistered) return;
    _builtinsRegistered = true;

    register(BlockType.thinking, _defaultThinkingBuilder);
    register(BlockType.tool, _defaultToolBuilder);
    register(BlockType.content, _defaultContentBuilder);
    register(BlockType.confirmation, _defaultConfirmBuilder);
  }

  /// 注册或覆盖指定类型的构造器。
  static void register(BlockType type, BlockWidgetBuilder builder) {
    _registry[type.name] = builder;
  }

  /// 按名称注册自定义类型。
  static void registerCustom(String name, BlockWidgetBuilder builder) {
    _registry[name] = builder;
  }

  /// 获取指定类型的构造器。
  static BlockWidgetBuilder? get(BlockType type) => _registry[type.name];

  /// 获取自定义类型的构造器。
  static BlockWidgetBuilder? getCustom(String name) => _registry[name];

  /// 构建 block widget。
  static Widget build(
    BuildContext context,
    ChatBlock block,
    ChatBus bus,
    Exchange exchange,
  ) {
    _ensureBuiltins();
    final builder = _registry[block.type.name];
    if (builder == null) {
      return const SizedBox.shrink();
    }
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
    return Text(
      block.content ?? '',
      style: TextStyle(
        color: theme.textSecondary,
        fontSize: theme.fontSizeMd,
        height: 1.5,
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
                if (block.toolArgs != null && block.toolArgs!.isNotEmpty) ...[
                  const Spacer(),
                  Flexible(
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
    final theme = ChatTheme.of(context);
    return Text(
      block.content ?? '',
      style: TextStyle(
        color: theme.textContent,
        fontSize: theme.fontSizeLg,
        height: 1.6,
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
      decoration: BoxDecoration(
        color: theme.bgWarning,
        border: Border.all(color: theme.borderWarning),
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (block.description != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacingMd,
                theme.spacingSm,
                theme.spacingMd,
                theme.spacingXs,
              ),
              child: Text(
                block.description!,
                style: TextStyle(
                  color: theme.textContent,
                  fontSize: theme.fontSizeMd,
                  height: 1.5,
                ),
              ),
            ),
          if (block.toolName != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacingMd,
                vertical: theme.spacingXs,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacingSm + 2,
                  vertical: theme.spacingXs + 2,
                ),
                decoration: BoxDecoration(
                  color: theme.bgCommand,
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                ),
                child: Row(
                  children: [
                    Text(
                      block.toolName!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        fontSize: theme.fontSizeMd,
                        color: theme.warning,
                      ),
                    ),
                    if (block.toolArgs != null &&
                        block.toolArgs!.isNotEmpty) ...[
                      const Spacer(),
                      Flexible(
                        child: Text(
                          block.toolArgs!.toString(),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: theme.fontSizeSm,
                            color: theme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacingMd,
              theme.spacingXs,
              theme.spacingMd,
              theme.spacingSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ConfirmButton.filled(
                  label: '允许',
                  color: theme.accent,
                  onPressed: () =>
                      bus.confirmTool(exchangeId, block.toolName ?? '', false),
                ),
                if (block.canAlwaysAllow) const SizedBox(width: 8),
                if (block.canAlwaysAllow)
                  _ConfirmButton.outlined(
                    label: '始终允许',
                    color: theme.accent,
                    onPressed: () =>
                        bus.confirmTool(exchangeId, block.toolName ?? '', true),
                  ),
                const SizedBox(width: 8),
                _ConfirmButton.text(
                  label: '取消',
                  color: theme.textSecondary,
                  onPressed: () =>
                      bus.cancelTool(exchangeId, block.toolName ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool _filled;
  final bool _outlined;
  final VoidCallback onPressed;

  const _ConfirmButton._({
    required this.label,
    required this.color,
    required this.onPressed,
    required this._filled,
    required this._outlined,
  });

  factory _ConfirmButton.filled({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => _ConfirmButton._(
    label: label,
    color: color,
    onPressed: onPressed,
    filled: true,
    outlined: false,
  );

  factory _ConfirmButton.outlined({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => _ConfirmButton._(
    label: label,
    color: color,
    onPressed: onPressed,
    filled: false,
    outlined: true,
  );

  factory _ConfirmButton.text({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => _ConfirmButton._(
    label: label,
    color: color,
    onPressed: onPressed,
    filled: false,
    outlined: false,
  );

  @override
  Widget build(BuildContext context) {
    final bgColor = _filled ? color : Colors.transparent;
    final fgColor = _filled ? Colors.white : color;
    final borderSide = _outlined
        ? BorderSide(color: color.withValues(alpha: 0.5))
        : BorderSide.none;

    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: borderSide,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
