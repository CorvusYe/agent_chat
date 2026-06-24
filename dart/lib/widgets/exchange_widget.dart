import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../bus/chat_bus.dart';
import '../blocks/block_registry.dart';
import '../theme/chat_theme.dart';
import '../l10n/chat_l10n.dart';
import 'block/block_header.dart';
import 'block/block_anim.dart';
import 'block/block_placeholder.dart';

/// 单条 exchange — 含用户消息 + 时间轴内的所有 block。
class ExchangeWidget extends StatelessWidget {
  final Exchange exchange;
  final ChatBus bus;

  const ExchangeWidget({super.key, required this.exchange, required this.bus});

  @override
  Widget build(BuildContext context) {
    final allBlocks = exchange.groups.expand((g) => g.blocks).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 用户消息
        _buildUserMessage(context),
        // 时间轴
        if (allBlocks.isNotEmpty) _buildTimeline(context, allBlocks),
      ],
    );
  }

  Widget _buildUserMessage(BuildContext context) {
    final theme = ChatTheme.of(context);
    return _UserMessage(text: exchange.userMessage, theme: theme);
  }

  Widget _buildTimeline(BuildContext context, List<ChatBlock> blocks) {
    final theme = ChatTheme.of(context);
    final expandedIndex = blocks.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...blocks.asMap().entries.map((entry) {
          final idx = entry.key;
          final block = entry.value;
          final isLast = idx == expandedIndex;
          return _BlockTimelineItem(
            block: block,
            bus: bus,
            exchange: exchange,
            isExpanded: isLast,
            showDotColor: dotColorFor(block, theme),
            headerColor: headerColorFor(block, theme),
            isLastBlock: isLast,
          );
        }),
        if (shouldShowThinkingPlaceholder(exchange))
          buildThinkingPlaceholder(context, exchange),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Public helpers & timeline builder (for sticky headers)
// ═══════════════════════════════════════════════════════

Color dotColorFor(ChatBlock block, ChatTheme theme) {
  if (block.status == BlockStatus.cancelled) return theme.error;
  if (block.status == BlockStatus.alwaysAllowed) return theme.success;
  if (block.status == BlockStatus.approved) return theme.accent;
  if (block.type == BlockType.thinking) return theme.dotThinking;
  if (block.type == BlockType.tool) return theme.dotTool;
  if (block.type == BlockType.content) return theme.dotContent;
  if (block.type == BlockType.confirmation) return theme.dotConfirm;
  // 自定义类型 — 从 BlockRegistry 取样式，未注册时走默认色
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.dotColor;
  return theme.dotContent;
}

Color headerColorFor(ChatBlock block, ChatTheme theme) {
  if (block.type == BlockType.thinking) return theme.headerThinking;
  if (block.type == BlockType.tool) return theme.headerTool;
  if (block.type == BlockType.content) return theme.headerContent;
  if (block.type == BlockType.confirmation) return theme.headerConfirm;
  // 自定义类型 — 从 BlockRegistry 取样式
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.headerColor;
  return theme.headerContent;
}

/// Build only the timeline portion of an exchange (no user message).
/// Used by [ChatScreen] for sticky header layout.
Widget buildExchangeTimeline(
  BuildContext context,
  Exchange exchange,
  ChatBus bus, {
  List<GlobalKey>? blockKeys,
  Set<String>? collapsedBlockIds,
  void Function(String blockId, bool expanded)? onCollapsedChanged,
}) {
  final theme = ChatTheme.of(context);
  final allBlocks = exchange.groups.expand((g) => g.blocks).toList();

  if (allBlocks.isEmpty) return const SizedBox.shrink();

  final expandedIndex = allBlocks.length - 1;

  final items = allBlocks.asMap().entries.map((entry) {
    final idx = entry.key;
    final block = entry.value;
    return _BlockTimelineItem(
      key: blockKeys?[idx],
      block: block,
      bus: bus,
      exchange: exchange,
      isExpanded: idx == expandedIndex,
      showDotColor: dotColorFor(block, theme),
      headerColor: headerColorFor(block, theme),
      collapsed: collapsedBlockIds?.contains(block.id) ?? false,
      onCollapsedChanged: onCollapsedChanged,
      isLastBlock: idx == expandedIndex,
    );
  }).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      ...items,
      if (shouldShowThinkingPlaceholder(exchange))
        buildThinkingPlaceholder(context, exchange),
    ],
  );
}

/// 当 exchange 正在处理且无 active block 时显示"正在思考"占位。
bool shouldShowThinkingPlaceholder(Exchange exchange) {
  if (exchange.status != ExchangeStatus.processing) return false;
  if (exchange.groups.isEmpty) return false;
  return !exchange.groups
      .expand((g) => g.blocks)
      .any(
        (b) =>
            b.status == BlockStatus.running || b.status == BlockStatus.pending,
      );
}

/// "正在思考"占位 widget — 旋转环圆点 + 心跳脉冲文字，样式同 block 标题。
Widget buildThinkingPlaceholder(BuildContext context, Exchange exchange) {
  return const ThinkingPlaceholder();
}

// ═══════════════════════════════════════════════════════
//  Public helpers — label & icon for block headers
// ═══════════════════════════════════════════════════════

String labelForBlock(ChatBlock block, [ChatL10n? l10n]) {
  final L = l10n ?? ChatL10n.zhHans;
  if (block.type == BlockType.thinking) return L.labelThinking;
  if (block.type == BlockType.tool) {
    return L.labelToolWith(block.toolName ?? '');
  }
  if (block.type == BlockType.content) return L.labelContent;
  if (block.type == BlockType.confirmation) return L.labelConfirm;
  // 自定义类型 — 从 BlockRegistry 取样式
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.label;
  return block.toolName ?? L.labelCustom;
}

IconData iconForBlock(ChatBlock block) {
  if (block.type == BlockType.thinking) return Icons.psychology_outlined;
  if (block.type == BlockType.tool) return Icons.build_outlined;
  if (block.type == BlockType.content) return Icons.chat_bubble_outline;
  if (block.type == BlockType.confirmation) return Icons.help_outline;
  // 自定义类型 — 从 BlockRegistry 取样式
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.icon;
  return Icons.extension_outlined;
}

// ═══════════════════════════════════════════════════════
//  User Message — 展开/收起
// ═══════════════════════════════════════════════════════

class _UserMessage extends StatefulWidget {
  final String text;
  final ChatTheme theme;

  const _UserMessage({required this.text, required this.theme});

  @override
  State<_UserMessage> createState() => _UserMessageState();
}

class _UserMessageState extends State<_UserMessage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final lineHeight = theme.fontSizeLg * 1.5; // matches textStyle height
    final padH = theme.spacingLg;
    final padV = theme.spacingSm + 2;

    // collapsed = 3 lines (theme-aware)
    final collapsedHeight = padV * 2 + lineHeight * 3;
    // gradient covers bottom 2 lines
    final gradientStart = padV + lineHeight;
    // expanded = 50% of screen height
    final expandedMaxHeight = MediaQuery.of(context).size.height * 0.5;

    final textStyle = TextStyle(
      color: theme.textPrimary,
      fontSize: theme.fontSizeLg,
      height: 1.5,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - padH * 2;

        // detect overflow beyond 3 lines
        final textSpan = TextSpan(text: widget.text, style: textStyle);
        final tp = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: contentWidth);
        final needsExpand = tp.didExceedMaxLines;

        final decoration = theme.cardDecoration();

        return Container(
          width: double.infinity,
          decoration: decoration,
          child: Stack(
            children: [
              // scrollable content with height constraint
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: _expanded ? expandedMaxHeight : collapsedHeight,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: padH,
                      vertical: padV,
                    ),
                    child: Text(widget.text, style: textStyle),
                  ),
                ),
              ),
              // gradient from line 2 to bottom (covers 2 lines + bottom padding)
              if (!_expanded && needsExpand)
                Positioned(
                  left: 0,
                  right: 0,
                  top: gradientStart,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, theme.bgSurface],
                      ),
                    ),
                  ),
                ),
              // expand/collapse button at bottom-right
              if (needsExpand)
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        _expanded
                            ? ChatL10n.of(context).collapse
                            : ChatL10n.of(context).expandAll,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.accentLight.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Block Timeline Item
// ═══════════════════════════════════════════════════════

class _BlockTimelineItem extends StatefulWidget {
  final ChatBlock block;
  final ChatBus bus;
  final Exchange exchange;
  final bool isExpanded;
  final Color showDotColor;
  final Color headerColor;
  final bool collapsed;
  final void Function(String blockId, bool expanded)? onCollapsedChanged;
  final bool isLastBlock;

  const _BlockTimelineItem({
    super.key,
    required this.block,
    required this.bus,
    required this.exchange,
    required this.isExpanded,
    required this.showDotColor,
    required this.headerColor,
    this.collapsed = false,
    this.onCollapsedChanged,
    this.isLastBlock = false,
  });

  @override
  State<_BlockTimelineItem> createState() => _BlockTimelineItemState();
}

class _BlockTimelineItemState extends State<_BlockTimelineItem>
    with TickerProviderStateMixin {
  bool _expanded = true;
  Timer? _elapsedTimer;
  AnimationController? _breathingCtrl;
  AnimationController? _rotationCtrl;

  bool get _isRunning =>
      widget.block.status == BlockStatus.running ||
      widget.block.status == BlockStatus.pending;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsed;
    _updateElapsedTimer();
    // _initAnimations deferred to didChangeDependencies — needs theme
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAnimations();
  }

  @override
  void didUpdateWidget(_BlockTimelineItem old) {
    super.didUpdateWidget(old);
    if (widget.isExpanded && !old.isExpanded) {
      _expanded = true;
    }
    if (widget.collapsed != old.collapsed && !widget.isExpanded) {
      _expanded = !widget.collapsed;
    }
    if (widget.block.status != old.block.status ||
        widget.block.startTime != old.block.startTime) {
      _updateElapsedTimer();
    }
    if (widget.block.status != old.block.status) {
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _breathingCtrl?.dispose();
    _rotationCtrl?.dispose();
    super.dispose();
  }

  void _initAnimations() {
    if (_isRunning && _breathingCtrl == null) {
      final theme = ChatTheme.of(context);
      _breathingCtrl = AnimationController(
        vsync: this,
        duration: theme.breathingDuration,
      );
      _breathingCtrl!.addListener(() {
        if (mounted) setState(() {});
      });
      _breathingCtrl!.repeat(reverse: true);

      _rotationCtrl = AnimationController(
        vsync: this,
        duration: theme.rotationDuration,
      );
      _rotationCtrl!.addListener(() {
        if (mounted) setState(() {});
      });
      _rotationCtrl!.repeat();
    } else if (!_isRunning && _breathingCtrl != null) {
      _breathingCtrl?.dispose();
      _breathingCtrl = null;
      _rotationCtrl?.dispose();
      _rotationCtrl = null;
    }
  }

  void _updateElapsedTimer() {
    final status = widget.block.status;
    if (widget.block.startTime != null &&
        (status == BlockStatus.running || status == BlockStatus.pending)) {
      _elapsedTimer ??= Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
    }
  }

  void _handleToggle() {
    final newExpanded = !_expanded;
    setState(() => _expanded = newExpanded);
    widget.onCollapsedChanged?.call(widget.block.id, newExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final l10n = ChatL10n.of(context);
    final lineColor = _isRunning && _breathingCtrl != null
        ? widget.showDotColor.withValues(
            alpha: 0.5 + 0.5 * _breathingCtrl!.value,
          )
        : widget.showDotColor;
    final animatedHeaderColor = _isRunning && _breathingCtrl != null
        ? widget.headerColor.withValues(
            alpha: 0.5 + 0.5 * _breathingCtrl!.value,
          )
        : widget.headerColor;
    // 根据主题值计算时间轴圆点中心位置，确保竖线经过圆心
    final headerContentH = max(theme.iconSizeSm, theme.fontSizeSm * 1.2);
    final headerH =
        theme.blockHeaderPadding.top +
        headerContentH +
        theme.blockHeaderPadding.bottom;
    final dotCenterY = headerH / 2;
    final dotSize = theme.timelineDotSize;
    final lineW = theme.timelineLineWidth;
    final gutterW = theme.timelineGutter;
    // 圆点 widget
    final dotWidget = _isRunning && _rotationCtrl != null
        ? SizedBox(
            width: dotSize,
            height: dotSize,
            child: CustomPaint(
              painter: RunningDotPainter(
                color: widget.showDotColor,
                rotation: _rotationCtrl!.value,
              ),
            ),
          )
        : Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.bgPrimary,
              border: Border.all(color: lineColor, width: 2),
            ),
          );

    return Padding(
      padding: EdgeInsets.only(left: theme.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 时间轴列：圆点 + 竖线 ──
          SizedBox(
            width: gutterW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 竖线：充满可用高度，水平居中
                Positioned.fill(
                  top: dotCenterY,
                  bottom: widget.isLastBlock ? 8 : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Container(width: lineW, color: lineColor)],
                  ),
                ),
                // 圆点：水平居中，垂直在 dotCenterY
                Positioned(
                  left: 0,
                  right: 0,
                  top: dotCenterY - dotSize / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [dotWidget],
                  ),
                ),
              ],
            ),
          ),
          // ── 内容列：header + body ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _handleToggle,
                  child: buildBlockHeader(
                    context: context,
                    icon: _iconFor(widget.block),
                    label: _labelFor(widget.block, l10n),
                    color: animatedHeaderColor,
                    theme: theme,
                    showChevron: true,
                    expanded: _expanded,
                    startTime: widget.block.startTime,
                    elapsed: widget.block.elapsed,
                  ),
                ),
                // 内容
                AnimatedCrossFade(
                  alignment: Alignment.topLeft,
                  firstChild: const SizedBox.shrink(),
                  secondChild: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: theme.contentMaxHeight,
                    ),
                    child: SingleChildScrollView(
                      child: BlockRegistry.build(
                        context,
                        widget.block,
                        widget.bus,
                        widget.exchange,
                      ),
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(ChatBlock block, ChatL10n l10n) =>
      labelForBlock(block, l10n);

  IconData _iconFor(ChatBlock block) => iconForBlock(block);
}

// ═══════════════════════════════════════════════════════
//  Running Dot Painter — 旋转环 + 极坐标透明度渐变
// ═══════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════
//  Thinking Placeholder — 心跳脉冲 + 旋转环
