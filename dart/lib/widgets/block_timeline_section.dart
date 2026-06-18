import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';
import '../blocks/block_registry.dart';
import 'exchange_widget.dart';

/// 单个 exchange 的 block 时间轴区域（Sliver 版本）。
///
/// 管理所有 block 的折叠/展开状态（含手动覆盖），
/// 输出 [SliverMainAxisGroup] 包含所有 block + thinking 占位 + 错误。
///
/// 设计放在外层 [SliverMainAxisGroup] 的 slivers 列表中。
class BlockTimelineSection extends StatefulWidget {
  final Exchange exchange;
  final ChatBus bus;

  const BlockTimelineSection({
    super.key,
    required this.exchange,
    required this.bus,
  });

  @override
  State<BlockTimelineSection> createState() => _BlockTimelineSectionState();
}

class _BlockTimelineSectionState extends State<BlockTimelineSection> {
  /// Blocks the user manually expanded — override auto-collapse.
  final Set<String> _manuallyExpandedKeys = {};

  /// Blocks the user manually collapsed — override auto-expand.
  final Set<String> _manuallyCollapsedKeys = {};

  List<ChatBlock> get _allBlocks =>
      widget.exchange.groups.expand((g) => g.blocks).toList();

  // ═══════════════════════════════════════════════════════
  //  Collapse / expand 逻辑
  // ═══════════════════════════════════════════════════════

  /// Whether this block is the single latest block across all exchanges.
  bool _isLatestBlock(ChatBlock block) {
    for (final ex in widget.bus.exchanges.reversed) {
      for (final g in ex.groups.reversed) {
        if (g.blocks.isNotEmpty) {
          return '${widget.exchange.id}_${block.id}' ==
              '${ex.id}_${g.blocks.last.id}';
        }
      }
    }
    return false;
  }

  /// Computed dynamically: collapsed state = default (latest=expanded) with
  /// manual overrides. Parallel blocks in the same group stay expanded until
  /// all complete.
  bool _isCollapsed(ChatBlock block) {
    final key = '${widget.exchange.id}_${block.id}';
    if (_manuallyExpandedKeys.contains(key)) return false;
    if (_manuallyCollapsedKeys.contains(key)) return true;

    // If any sibling in the same group is still running, keep expanded
    for (final group in widget.exchange.groups) {
      if (group.blocks.any((b) => b.id == block.id)) {
        if (group.blocks.any(
          (b) =>
              b.status == BlockStatus.running ||
              b.status == BlockStatus.pending,
        )) {
          return false;
        }
        break;
      }
    }

    return !_isLatestBlock(block);
  }

  void _onToggleCollapsed(String collapseKey, bool currentlyCollapsed) {
    setState(() {
      if (currentlyCollapsed) {
        _manuallyExpandedKeys.add(collapseKey);
        _manuallyCollapsedKeys.remove(collapseKey);
      } else {
        _manuallyCollapsedKeys.add(collapseKey);
        _manuallyExpandedKeys.remove(collapseKey);
      }
    });
  }

  String get _errorCollapseKey => '${widget.exchange.id}_error';

  bool get _isErrorCollapsed {
    final key = _errorCollapseKey;
    if (_manuallyExpandedKeys.contains(key)) return false;
    if (_manuallyCollapsedKeys.contains(key)) return true;
    return false; // 默认展开
  }

  /// Extract first paragraph of block content for collapsed subtext.
  String _firstParagraph(ChatBlock block) {
    final text = block.toolResult ?? block.content ?? block.description ?? '';
    if (text.isEmpty) return '';
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed.length > 50 ? '${trimmed.substring(0, 50)}…' : trimmed;
      }
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final viewportHeight = MediaQuery.of(context).size.height;

    final slivers = <Widget>[];

    for (final block in _allBlocks) {
      // 空内容的 content block 整体跳过（tool-only 响应不显示"回答"）
      if (block.type == BlockType.content &&
          (block.content == null || block.content!.isEmpty)) {
        continue;
      }
      final collapsed = _isCollapsed(block);
      final innerSlivers = <Widget>[
        SliverPinnedHeader(child: _buildInlineHeader(block, theme)),
      ];
      if (!collapsed) {
        innerSlivers.add(
          SliverToBoxAdapter(
            child: _buildBlockContent(block, theme, viewportHeight),
          ),
        );
      }
      slivers.add(SliverMainAxisGroup(slivers: innerSlivers));
    }

    if (shouldShowThinkingPlaceholder(widget.exchange)) {
      slivers.add(
        SliverToBoxAdapter(
          child: buildThinkingPlaceholder(context, widget.exchange),
        ),
      );
    }

    if (widget.exchange.status == ExchangeStatus.failed &&
        widget.exchange.errorMessage != null &&
        widget.exchange.errorMessage!.isNotEmpty) {
      final errCollapsed = _isErrorCollapsed;
      final errKey = _errorCollapseKey;
      final errSlivers = <Widget>[
        SliverToBoxAdapter(
          child: _buildErrorHeader(errKey, errCollapsed, theme),
        ),
      ];
      if (!errCollapsed) {
        errSlivers.add(SliverToBoxAdapter(child: _buildErrorContent(theme)));
      }
      slivers.add(SliverMainAxisGroup(slivers: errSlivers));
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  // ═══════════════════════════════════════════════════════
  //  Block header — Row(gutter + header)
  // ═══════════════════════════════════════════════════════

  Widget _buildInlineHeader(ChatBlock block, ChatTheme theme) {
    final collapseKey = '${widget.exchange.id}_${block.id}';
    final collapsed = _isCollapsed(block);
    final sub = collapsed ? _firstParagraph(block) : null;

    return BlockAnimController(
      block: block,
      builder: (context, anim) {
        final dotColor = dotColorFor(block, theme);

        return SizedBox(
          height: 28.0,
          child: Row(
            children: [
              // 时间轴列：gutter + 圆点居中
              SizedBox(
                width: theme.timelineGutter,
                child: Center(
                  child: anim.isActive
                      ? SizedBox(
                          width: theme.timelineDotSize,
                          height: theme.timelineDotSize,
                          child: CustomPaint(
                            painter: RunningDotPainter(
                              color: dotColor,
                              rotation: anim.rotationValue,
                            ),
                          ),
                        )
                      : Container(
                          width: theme.timelineDotSize,
                          height: theme.timelineDotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.bgPrimary,
                            border: Border.all(color: dotColor, width: 2),
                          ),
                        ),
                ),
              ),
              // 内容列
              Expanded(
                child: InkWell(
                  onTap: () => _onToggleCollapsed(collapseKey, collapsed),
                  child: buildBlockHeader(
                    context: context,
                    icon: iconForBlock(block),
                    label: labelForBlock(block),
                    color: anim.applyBreathing(headerColorFor(block, theme)),
                    theme: theme,
                    showChevron: true,
                    expanded: !collapsed,
                    subtitle: sub,
                    startTime: block.startTime,
                    elapsed: block.elapsed,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Block content — Stack(竖线 + content)
  // ═══════════════════════════════════════════════════════
  //
  // 用 Stack 而非 Row：竖线需要拉伸到与内容等高的完整高度，
  // 而 Row 在 sliver 中无法约束纵轴高度（CrossAxisAlignment.stretch 会报无限高）。

  Widget _buildBlockContent(
    ChatBlock block,
    ChatTheme theme,
    double viewportHeight,
  ) {
    return BlockAnimController(
      block: block,
      builder: (context, anim) {
        final lineColor = anim.applyBreathing(dotColorFor(block, theme));

        return Padding(
          padding: theme.blockPadding,
          child: Stack(
            children: [
              // 竖线 — 在 gutter 区域内水平居中
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: theme.timelineGutter,
                  child: Center(
                    child: Container(
                      width: theme.timelineLineWidth,
                      color: lineColor,
                    ),
                  ),
                ),
              ),
              // 内容 — 从 gutter 右侧开始
              Padding(
                padding: EdgeInsets.only(left: theme.timelineGutter),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: viewportHeight * 0.618,
                  ),
                  child: SingleChildScrollView(
                    child: BlockRegistry.build(
                      context,
                      block,
                      widget.bus,
                      widget.exchange,
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

  // ═══════════════════════════════════════════════════════
  //  Error header — Row(gutter + header)
  // ═══════════════════════════════════════════════════════

  Widget _buildErrorHeader(
    String collapseKey,
    bool collapsed,
    ChatTheme theme,
  ) {
    return SizedBox(
      height: 28.0,
      child: Row(
        children: [
          // 时间轴列：gutter + 圆点居中
          SizedBox(
            width: theme.timelineGutter,
            child: Center(
              child: Container(
                width: theme.timelineDotSize,
                height: theme.timelineDotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.bgPrimary,
                  border: Border.all(color: theme.error, width: 2),
                ),
              ),
            ),
          ),
          // 内容列
          Expanded(
            child: InkWell(
              onTap: () => _onToggleCollapsed(collapseKey, collapsed),
              child: buildBlockHeader(
                context: context,
                icon: Icons.error_outline,
                label: '错误',
                color: theme.error,
                theme: theme,
                showChevron: true,
                expanded: !collapsed,
                subtitle: collapsed ? widget.exchange.errorMessage : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  Error content — Stack(竖线 + content)
  // ═══════════════════════════════════════════════════════

  Widget _buildErrorContent(ChatTheme theme) {
    final isLight = theme.bgPrimary.computeLuminance() > 0.5;
    final verticalAlpha = isLight ? 0.25 : 0.2;

    return Padding(
      padding: theme.blockPadding,
      child: Stack(
        children: [
          // 竖线 — 在 gutter 区域内水平居中
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: theme.timelineGutter,
              child: Center(
                child: Container(
                  width: theme.timelineLineWidth,
                  color: theme.error.withValues(alpha: verticalAlpha),
                ),
              ),
            ),
          ),
          // 内容 — 从 gutter 右侧开始
          Padding(
            padding: EdgeInsets.only(
              left: theme.timelineGutter + 10,
              bottom: 4,
            ),
            child: Text(
              widget.exchange.errorMessage!,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: theme.fontSizeSm,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
