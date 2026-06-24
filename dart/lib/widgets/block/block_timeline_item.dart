import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/exchange.dart';
import '../../models/chat_block.dart';
import '../../bus/chat_bus.dart';
import '../../blocks/block_registry.dart';
import '../../theme/chat_theme.dart';
import '../../l10n/chat_l10n.dart';
import 'block_header.dart';
import 'block_anim.dart';
import 'block_utils.dart';

/// 时间轴上的单个 block — 圆点 + 竖线 + header + 内容区。
class BlockTimelineItem extends StatefulWidget {
  final ChatBlock block;
  final ChatBus bus;
  final Exchange exchange;
  final bool isExpanded;
  final Color showDotColor;
  final Color headerColor;
  final bool collapsed;
  final void Function(String blockId, bool expanded)? onCollapsedChanged;
  final bool isLastBlock;

  const BlockTimelineItem({
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
  State<BlockTimelineItem> createState() => BlockTimelineItemState();
}

class BlockTimelineItemState extends State<BlockTimelineItem>
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAnimations();
  }

  @override
  void didUpdateWidget(BlockTimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _expanded = true;
    }
    if (widget.collapsed != oldWidget.collapsed && !widget.isExpanded) {
      _expanded = !widget.collapsed;
    }
    if (widget.block.status != oldWidget.block.status ||
        widget.block.startTime != oldWidget.block.startTime) {
      _updateElapsedTimer();
    }
    if (widget.block.status != oldWidget.block.status) {
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
    final headerContentH = max(theme.iconSizeSm, theme.fontSizeSm * 1.2);
    final headerH =
        theme.blockHeaderPadding.top +
        headerContentH +
        theme.blockHeaderPadding.bottom;
    final dotCenterY = headerH / 2;
    final dotSize = theme.timelineDotSize;
    final lineW = theme.timelineLineWidth;
    final gutterW = theme.timelineGutter;
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
          SizedBox(
            width: gutterW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: dotCenterY,
                  bottom: widget.isLastBlock ? 8 : 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Container(width: lineW, color: lineColor)],
                  ),
                ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _handleToggle,
                  child: buildBlockHeader(
                    context: context,
                    icon: iconForBlock(widget.block),
                    label: labelForBlock(widget.block, l10n),
                    color: animatedHeaderColor,
                    theme: theme,
                    showChevron: true,
                    expanded: _expanded,
                    startTime: widget.block.startTime,
                    elapsed: widget.block.elapsed,
                  ),
                ),
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
}
