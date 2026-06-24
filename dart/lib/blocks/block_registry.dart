import 'package:flutter/material.dart';
import '../models/chat_block.dart';
import '../models/exchange.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';
import '../l10n/chat_l10n.dart';

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

/// 当前 exchange 是否处于失败态
bool _isFailed(Exchange exchange) => exchange.status == ExchangeStatus.failed;

Widget _defaultThinkingBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  return _ThinkingBlock(block: block, isError: _isFailed(exchange));
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
  return _ToolBlock(block: block, isError: _isFailed(exchange));
}

Widget _defaultContentBuilder(
  BuildContext context,
  ChatBlock block,
  ChatBus bus,
  Exchange exchange,
) {
  return _ContentBlock(block: block, isError: _isFailed(exchange));
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
  final bool isError;
  const _ThinkingBlock({required this.block, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Text(
        block.content ?? '',
        softWrap: true,
        style: TextStyle(
          color: isError ? theme.error : theme.textSecondary,
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
  final bool isError;
  const _ToolBlock({required this.block, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 错误状态使用红色系
    final borderColor = isError ? theme.error.withAlpha(80) : theme.borderLight;
    final headerBg = isError
        ? theme.error.withAlpha(isDark ? 25 : 18)
        : theme.bgCardHeader;
    final headerTextColor = isError ? theme.error : theme.textToolHeader;
    final resultBg = isError
        ? theme.error.withAlpha(isDark ? 15 : 10)
        : theme.resultBg;
    final resultColor = isError ? theme.error : theme.textToolResult;

    return Container(
      decoration: BoxDecoration(
        color: theme.bgCard,
        border: Border.all(color: borderColor),
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
            color: headerBg,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    block.toolName ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      fontSize: theme.fontSizeMd,
                      color: headerTextColor,
                    ),
                  ),
                ),
                if (block.toolArgs != null && block.toolArgs!.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        block.toolArgs!.toString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: theme.fontSizeSm,
                          color: isError ? theme.error : theme.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (block.toolResult != null && block.toolResult!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(theme.spacingMd),
              decoration: BoxDecoration(color: resultBg),
              clipBehavior: Clip.hardEdge,
              child: Text(
                block.toolResult!,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: theme.fontSizeSm,
                  height: 1.5,
                  color: resultColor,
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
  final bool isError;
  const _ContentBlock({required this.block, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final content = block.content;
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    final theme = ChatTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: Text(
        content,
        softWrap: true,
        style: TextStyle(
          color: isError ? theme.error : theme.textContent,
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

class _ConfirmGate extends StatefulWidget {
  final ChatBlock block;
  final ChatBus bus;
  final String exchangeId;
  const _ConfirmGate({
    required this.block,
    required this.bus,
    required this.exchangeId,
  });

  @override
  State<_ConfirmGate> createState() => _ConfirmGateState();
}

class _ConfirmGateState extends State<_ConfirmGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flashAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut));
    widget.bus.attentionSignal.addListener(_onAttention);
  }

  @override
  void dispose() {
    widget.bus.attentionSignal.removeListener(_onAttention);
    _flashCtrl.dispose();
    super.dispose();
  }

  void _onAttention() {
    if (!mounted) return;
    _flashCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final hasArgs =
        widget.block.toolArgs != null && widget.block.toolArgs!.isNotEmpty;

    return AnimatedBuilder(
      animation: _flashAnim,
      builder: (context, child) {
        final flashColor = theme.accent.withAlpha(
          (_flashAnim.value * 30).round(),
        );
        final bgColor = Color.lerp(theme.bgCard, flashColor, _flashAnim.value)!;
        return Container(
          padding: theme.confirmPadding,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(theme.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 头部：工具名 + 描述
              if (widget.block.toolName != null ||
                  widget.block.description != null)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: hasArgs ? theme.spacingXs : theme.spacingXs + 2,
                  ),
                  child: Row(
                    children: [
                      if (widget.block.toolName != null)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: theme.spacingXs + 2,
                            ),
                            child: Text(
                              widget.block.toolName!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                fontSize: theme.fontSizeSm,
                                color: theme.textToolHeader,
                              ),
                            ),
                          ),
                        ),
                      if (widget.block.description != null)
                        Expanded(
                          child: Text(
                            widget.block.description!,
                            style: TextStyle(
                              color: theme.textContent,
                              fontSize: theme.fontSizeSm,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              // 工具参数（命令/详情）— 单独一行，突出展示
              if (hasArgs)
                Padding(
                  padding: EdgeInsets.only(bottom: theme.spacingXs + 2),
                  child: Container(
                    width: double.infinity,
                    padding: theme.codeBlockPadding,
                    decoration: BoxDecoration(
                      color: theme.bgCommand,
                      borderRadius: BorderRadius.circular(theme.radiusSm),
                    ),
                    child: Text(
                      widget.block.toolArgs!.toString(),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: theme.fontSizeSm,
                        height: 1.4,
                        color: theme.textContent,
                      ),
                    ),
                  ),
                ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _CompactBtn(
                    label: ChatL10n.of(context).btnAllow,
                    filled: true,
                    color: theme.accent,
                    onPressed: () => widget.bus.confirmTool(
                      widget.exchangeId,
                      widget.block.toolName ?? '',
                      false,
                    ),
                  ),
                  if (widget.block.canAlwaysAllow)
                    _CompactBtn(
                      label: ChatL10n.of(context).btnAlwaysAllow,
                      filled: false,
                      color: theme.accent,
                      onPressed: () => widget.bus.confirmTool(
                        widget.exchangeId,
                        widget.block.toolName ?? '',
                        true,
                      ),
                    ),
                  _CompactBtn(
                    label: ChatL10n.of(context).btnCancel,
                    filled: false,
                    color: theme.textSecondary,
                    onPressed: () => widget.bus.cancelTool(
                      widget.exchangeId,
                      widget.block.toolName ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    final theme = ChatTheme.of(context);
    return SizedBox(
      height: theme.smallButtonHeight,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: filled ? color : theme.btnSecondaryBg,
          foregroundColor: filled
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : Colors.white)
              : color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radiusSm),
            side: filled
                ? BorderSide.none
                : BorderSide(color: theme.buttonBorderColor),
          ),
          padding: theme.buttonPadding,
          textStyle: TextStyle(
            fontSize: theme.fontSizeSm,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
