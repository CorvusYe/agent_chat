import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../bus/chat_bus.dart';
import '../blocks/block_registry.dart';
import '../theme/chat_theme.dart';

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
  return const _ThinkingPlaceholder();
}

// ═══════════════════════════════════════════════════════
//  Public helpers — label & icon for block headers
// ═══════════════════════════════════════════════════════

String labelForBlock(ChatBlock block) {
  if (block.type == BlockType.thinking) return '思考';
  if (block.type == BlockType.tool) return '工具 · ${block.toolName ?? ""}';
  if (block.type == BlockType.content) return '回答';
  if (block.type == BlockType.confirmation) return '需要确认';
  // 自定义类型 — 从 BlockRegistry 取样式
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.label;
  return block.toolName ?? '自定义';
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

/// Shared block header row — used both in timeline and pinned header.
/// [subtitle] shows when collapsed with smooth size animation.
Widget buildBlockHeader({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required ChatTheme theme,
  bool showChevron = false,
  bool expanded = false,
  String? subtitle,
  DateTime? startTime,
  Duration? elapsed,
}) {
  String? elapsedText;
  if (elapsed != null) {
    elapsedText = '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s';
  } else if (startTime != null) {
    elapsedText =
        '${(DateTime.now().difference(startTime).inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  return Container(
    color: theme.bgPrimary,
    child: Padding(
      padding: theme.blockHeaderPadding,
      child: Row(
        children: [
          Icon(icon, size: theme.iconSizeSm, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: theme.fontSizeSm,
              fontWeight: FontWeight.w500,
              color: color,
              letterSpacing: 0.24,
            ),
          ),
          if (elapsedText != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                elapsedText,
                style: TextStyle(
                  fontSize: theme.fontSizeSm - 1,
                  color: theme.textTertiary,
                ),
              ),
            ),
          if (subtitle != null)
            Flexible(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.centerLeft,
                curve: Curves.easeInOut,
                child: expanded
                    ? const SizedBox(width: 0)
                    : Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: theme.fontSizeSm - 1,
                            color: theme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          if (showChevron)
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: theme.iconSizeSm,
                color: theme.chevronColor,
              ),
            ),
        ],
      ),
    ),
  );
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

        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: theme.bgSurface,
            border: Border(
              top: BorderSide(color: theme.borderStrong),
              left: BorderSide(color: theme.borderStrong),
              right: BorderSide(color: theme.borderStrong),
              bottom: BorderSide(color: theme.borderUser),
            ),
          ),
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
                        _expanded ? '收起' : '展开全部',
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

    return Padding(
      padding: EdgeInsets.only(left: theme.spacingLg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 纵向线段 — 使用与圆点一致的状态色
          Positioned(
            left: -12,
            top: 13,
            bottom: widget.isLastBlock ? 8 : 0,
            child: Container(width: 2, color: lineColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 折叠/展开头部 — outlined dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -17,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _isRunning && _rotationCtrl != null
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CustomPaint(
                                painter: RunningDotPainter(
                                  color: widget.showDotColor,
                                  rotation: _rotationCtrl!.value,
                                ),
                              ),
                            )
                          : Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.bgPrimary,
                                border: Border.all(color: lineColor, width: 2),
                              ),
                            ),
                    ),
                  ),
                  InkWell(
                    onTap: _handleToggle,
                    child: buildBlockHeader(
                      context: context,
                      icon: _iconFor(widget.block),
                      label: _labelFor(widget.block),
                      color: animatedHeaderColor,
                      theme: theme,
                      showChevron: true,
                      expanded: _expanded,
                      startTime: widget.block.startTime,
                      elapsed: widget.block.elapsed,
                    ),
                  ),
                ],
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
        ],
      ),
    );
  }

  String _labelFor(ChatBlock block) => labelForBlock(block);

  IconData _iconFor(ChatBlock block) => iconForBlock(block);
}

// ═══════════════════════════════════════════════════════
//  Running Dot Painter — 旋转环 + 极坐标透明度渐变
// ═══════════════════════════════════════════════════════

class RunningDotPainter extends CustomPainter {
  final Color color;
  final double rotation;

  RunningDotPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 基础圆环（微光）— 提示圆的位置
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius, bgPaint);

    // 用画布旋转代替改角度，避免 SweepGradient 在 0° wrap 跳变
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * pi);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 无缝全圆渐变：左侧带头不透明 → 顺时针渐隐到右侧透明 → 左侧不透明收尾
    paint.shader = SweepGradient(
      startAngle: -pi,
      endAngle: pi,
      colors: [
        color.withValues(alpha: 1.0),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 1.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RunningDotPainter old) => old.rotation != rotation;
}

// ═══════════════════════════════════════════════════════
//  AnimValues & BlockAnimController — 共用的呼吸/旋转动画
// ═══════════════════════════════════════════════════════

/// Animation values exposed by [BlockAnimController] during a block's running state.
class AnimValues {
  final bool isActive;
  final double breathingValue;
  final double rotationValue;

  const AnimValues({
    this.isActive = false,
    this.breathingValue = 0.0,
    this.rotationValue = 0.0,
  });

  Color applyBreathing(Color base) =>
      isActive ? base.withValues(alpha: 0.5 + 0.5 * breathingValue) : base;
}

/// Hosts breathing + rotation animations for a running block.
///
/// Calls [builder] on every animation tick so the parent can render
/// animated colors/shapes. The animation repeats until the block
/// transitions out of running/pending status.
class BlockAnimController extends StatefulWidget {
  final ChatBlock block;
  final Widget Function(BuildContext context, AnimValues anim) builder;

  const BlockAnimController({
    super.key,
    required this.block,
    required this.builder,
  });

  @override
  State<BlockAnimController> createState() => _BlockAnimControllerState();
}

class _BlockAnimControllerState extends State<BlockAnimController>
    with TickerProviderStateMixin {
  AnimationController? _breathingCtrl;
  AnimationController? _rotationCtrl;

  bool get _isRunning =>
      widget.block.status == BlockStatus.running ||
      widget.block.status == BlockStatus.pending;

  @override
  void initState() {
    super.initState();
    // _initAnimations deferred to didChangeDependencies — needs theme
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAnimations();
  }

  @override
  void didUpdateWidget(BlockAnimController old) {
    super.didUpdateWidget(old);
    if (widget.block.status != old.block.status) {
      _initAnimations();
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      AnimValues(
        isActive: _isRunning && _breathingCtrl != null,
        breathingValue: _breathingCtrl?.value ?? 0.0,
        rotationValue: _rotationCtrl?.value ?? 0.0,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Thinking Placeholder — 心跳脉冲 + 旋转环
// ═══════════════════════════════════════════════════════

class _ThinkingPlaceholder extends StatefulWidget {
  const _ThinkingPlaceholder();

  @override
  State<_ThinkingPlaceholder> createState() => _ThinkingPlaceholderState();
}

class _ThinkingPlaceholderState extends State<_ThinkingPlaceholder>
    with TickerProviderStateMixin {
  AnimationController? _breathingCtrl;
  AnimationController? _rotationCtrl;
  bool _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    final theme = ChatTheme.of(context);
    _breathingCtrl =
        AnimationController(
            vsync: this,
            duration: theme.placeholderBreathingDuration,
          )
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat(reverse: true);

    _rotationCtrl =
        AnimationController(vsync: this, duration: theme.rotationDuration)
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat();
  }

  @override
  void dispose() {
    _breathingCtrl?.dispose();
    _rotationCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final pulseOpacity = 0.5 + 0.5 * (_breathingCtrl?.value ?? 0.0);

    return Padding(
      padding: EdgeInsets.only(left: theme.spacingLg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 旋转环圆点（不参与脉冲，保持 SweepGradient 可见）
          Positioned(
            left: -17,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CustomPaint(
                  painter: RunningDotPainter(
                    color: theme.dotThinking,
                    rotation: _rotationCtrl?.value ?? 0.0,
                  ),
                ),
              ),
            ),
          ),
          // 心跳脉冲文字
          Padding(
            padding: theme.blockHeaderPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: theme.iconSizeSm,
                  color: theme.headerThinking.withValues(alpha: pulseOpacity),
                ),
                SizedBox(width: 6),
                Text(
                  '正在思考',
                  style: TextStyle(
                    fontSize: theme.fontSizeSm,
                    fontWeight: FontWeight.w500,
                    color: theme.headerThinking.withValues(alpha: pulseOpacity),
                    letterSpacing: 0.24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
