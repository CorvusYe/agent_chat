import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';
import '../blocks/block_registry.dart';
import '../l10n/chat_l10n.dart';
import 'block/block_utils.dart';
import 'block/block_header.dart';
import 'block/block_content.dart';
import 'block/block_anim.dart';

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
      final collapseKey = '${widget.exchange.id}_${block.id}';
      final collapsed = _isCollapsed(block);
      final sub = collapsed ? _firstParagraph(block) : null;

      final innerSlivers = <Widget>[
        SliverPinnedHeader(
          child: _buildHeader(
            context: context,
            block: block,
            theme: theme,
            collapseKey: collapseKey,
            collapsed: collapsed,
            subtitle: sub,
          ),
        ),
      ];
      if (!collapsed) {
        innerSlivers.add(
          SliverToBoxAdapter(
            child: _buildContent(
              context: context,
              block: block,
              theme: theme,
              viewportHeight: viewportHeight,
            ),
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
          child: _buildHeader(
            context: context,
            block: null,
            theme: theme,
            collapseKey: errKey,
            collapsed: errCollapsed,
            subtitle: errCollapsed ? widget.exchange.errorMessage : null,
          ),
        ),
      ];
      if (!errCollapsed) {
        errSlivers.add(
          SliverToBoxAdapter(
            child: _buildContent(
              context: context,
              block: null,
              theme: theme,
              viewportHeight: 0,
            ),
          ),
        );
      }
      slivers.add(SliverMainAxisGroup(slivers: errSlivers));
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  /// 构建 block 或 error 的头部。
  /// [block] 不为 null → animated block header；null → static error header。
  Widget _buildHeader({
    required BuildContext context,
    required ChatBlock? block,
    required ChatTheme theme,
    required String collapseKey,
    required bool collapsed,
    String? subtitle,
  }) {
    if (block == null) {
      return BlockHeader(
        dot: Container(
          width: theme.timelineDotSize,
          height: theme.timelineDotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.bgPrimary,
            border: Border.all(color: theme.error, width: 2),
          ),
        ),
        icon: Icons.error_outline,
        label: ChatL10n.of(context).errorLabel,
        color: theme.error,
        onTap: () => _onToggleCollapsed(collapseKey, collapsed),
        expanded: !collapsed,
        subtitle: subtitle,
      );
    }

    final dotColor = dotColorFor(block, theme);
    return BlockAnimController(
      block: block,
      builder: (context, anim) => BlockHeader(
        dot: SizedBox(
          width: theme.timelineDotSize,
          height: theme.timelineDotSize,
          child: anim.isActive
              ? CustomPaint(
                  painter: RunningDotPainter(
                    color: dotColor,
                    rotation: anim.rotationValue,
                  ),
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.bgPrimary,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
        ),
        icon: iconForBlock(block),
        label: labelForBlock(block, ChatL10n.of(context)),
        color: anim.applyBreathing(headerColorFor(block, theme)),
        onTap: () => _onToggleCollapsed(collapseKey, collapsed),
        expanded: !collapsed,
        subtitle: subtitle,
        startTime: block.startTime,
        elapsed: block.elapsed,
      ),
    );
  }

  /// 构建 block 或 error 的内容。
  /// [block] 不为 null → animated block content；null → static error content。
  Widget _buildContent({
    required BuildContext context,
    required ChatBlock? block,
    required ChatTheme theme,
    required double viewportHeight,
  }) {
    if (block == null) {
      final isLight = theme.bgPrimary.computeLuminance() > 0.5;
      final verticalAlpha = isLight ? 0.25 : 0.2;
      return BlockContent(
        lineColor: theme.error.withValues(alpha: verticalAlpha),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Text(
            widget.exchange.errorMessage!,
            softWrap: true,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: theme.fontSizeSm,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return BlockAnimController(
      block: block,
      builder: (context, anim) => BlockContent(
        lineColor: anim.applyBreathing(dotColorFor(block, theme)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: viewportHeight * theme.contentMaxHeightFactor,
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
    );
  }
}

// ═══════════════════════════════════════════════════════
//  BlockContent — 统一的时间轴内容 Stack
// ═══════════════════════════════════════════════════════
