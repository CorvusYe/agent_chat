import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../bus/chat_bus.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../theme/chat_theme.dart';
import '../theme/themes.dart';
import '../blocks/block_registry.dart';
import 'exchange_widget.dart';
import 'stats_bar.dart';

/// ChatScreen — 聊天界面主 Widget。
///
/// 接收 [ChatBus] 作为唯一必需参数，自动监听状态变化。
/// 可通过 [theme] 覆盖主题，[loadingIndicator] 和 [emptyPlaceholder]
/// 自定义加载中和空聊天时的视图。
class ChatScreen extends StatefulWidget {
  final ChatBus bus;
  final ChatTheme? theme;
  final Widget? loadingIndicator;
  final Widget? emptyPlaceholder;

  const ChatScreen({
    super.key,
    required this.bus,
    this.theme,
    this.loadingIndicator,
    this.emptyPlaceholder,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  bool _queueVisible = false;
  Timer? _statsTimer;
  late final AnimationController _focusAnimCtrl;

  int _lastExchangeCount = 0;
  int _lastBlockCount = 0;

  /// Blocks the user manually expanded — override auto-collapse.
  final Set<String> _manuallyExpandedKeys = {};

  /// Blocks the user manually collapsed — override auto-expand.
  final Set<String> _manuallyCollapsedKeys = {};

  ChatBus get bus => widget.bus;

  @override
  void initState() {
    super.initState();
    _focusAnimCtrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _inputFocus.addListener(() {
      if (mounted) {
        if (_inputFocus.hasFocus) {
          _focusAnimCtrl.forward();
        } else {
          _focusAnimCtrl.reverse();
        }
      }
    });
    bus.addListener(_onBusChanged);
    bus.init();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (bus.isStreaming && mounted) {
        setState(() {});
        _scrollToBottomIfNearEnd();
      }
    });
  }

  @override
  void dispose() {
    _focusAnimCtrl.dispose();
    _inputFocus.dispose();
    bus.removeListener(_onBusChanged);
    bus.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  void _onBusChanged() {
    if (!mounted) return;
    final exCount = bus.exchanges.length;
    final blockCount = bus.exchanges.fold<int>(
      0,
      (sum, ex) => sum + ex.groups.fold<int>(0, (s, g) => s + g.blocks.length),
    );
    final shouldScroll =
        exCount > _lastExchangeCount || blockCount > _lastBlockCount;
    _lastExchangeCount = exCount;
    _lastBlockCount = blockCount;
    setState(() {});
    if (shouldScroll) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToBottomIfNearEnd() {
    if (!_scrollCtrl.hasClients) return;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentScroll = _scrollCtrl.position.pixels;
    if (maxScroll - currentScroll > 150) return; // not near end, skip
    _scrollCtrl.jumpTo(maxScroll);
  }

  /// Whether this block is the single latest block across all exchanges.
  bool _isLatestBlock(ChatBlock block, Exchange exchange) {
    for (final ex in bus.exchanges.reversed) {
      for (final g in ex.groups.reversed) {
        if (g.blocks.isNotEmpty) {
          return '${exchange.id}_${block.id}' == '${ex.id}_${g.blocks.last.id}';
        }
      }
    }
    return false;
  }

  /// Computed dynamically: collapsed state = default (latest=expanded) with manual overrides.
  /// Parallel blocks in the same group stay expanded until all complete.
  bool _isCollapsed(ChatBlock block, Exchange exchange) {
    final key = '${exchange.id}_${block.id}';
    if (_manuallyExpandedKeys.contains(key)) return false;
    if (_manuallyCollapsedKeys.contains(key)) return true;

    // If any sibling in the same group is still running, keep expanded
    for (final group in exchange.groups) {
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

    return !_isLatestBlock(block, exchange);
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

  void _handleSend() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _toggleQueue();
      return;
    }
    bus.sendMessage(text);
    _textCtrl.clear();
  }

  void _toggleQueue() {
    setState(() => _queueVisible = !_queueVisible);
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = widget.theme ?? ChatThemes.fluentDark;

    return Theme(
      data: ThemeData(extensions: [chatTheme], brightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: chatTheme.bgPrimary,
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(chatTheme.spacingWindow),
              child: Column(
                children: [
                  Expanded(child: _buildMessages(chatTheme)),
                  StatsBar(totalTokens: bus.totalTokens),
                  _buildInput(chatTheme),
                ],
              ),
            ),
            // 队列弹窗 + 外部点击屏障
            if (_queueVisible) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _queueVisible = false),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 60,
                child: _QueuePopupContent(
                  bus: bus,
                  onClose: () => setState(() => _queueVisible = false),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatTheme theme) {
    if (bus.isLoadingHistory) {
      return Center(
        child:
            widget.loadingIndicator ??
            CircularProgressIndicator(color: theme.accent),
      );
    }

    if (bus.exchanges.isEmpty) {
      return Center(
        child:
            widget.emptyPlaceholder ??
            Text(
              '发送一条消息开始对话',
              style: TextStyle(
                color: theme.textTertiary,
                fontSize: theme.fontSizeLg,
              ),
            ),
      );
    }

    final viewportWidth = MediaQuery.of(context).size.width;
    final viewportHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: _buildExchangeSlivers(theme, viewportWidth, viewportHeight),
    );
  }

  List<Widget> _buildExchangeSlivers(
    ChatTheme theme,
    double viewportWidth,
    double viewportHeight,
  ) {
    final slivers = <Widget>[];
    for (final exchange in bus.exchanges) {
      final allBlocks = exchange.groups.expand((g) => g.blocks).toList();

      final exHeaderHeight = _UserMsgHeaderDelegate.computeHeight(
        exchange.userMessage,
        theme,
        viewportWidth,
      );

      // Exchange group: pinned exchange header + per-block inner groups.
      // Blocks get their own SliverMainAxisGroup so their pinned headers
      // push each other within the exchange without pushing the exchange header.
      final groupSlivers = <Widget>[
        SliverPinnedHeader(
          child: _LastUserStickyHeader(
            message: exchange.userMessage,
            theme: theme,
            height: exHeaderHeight,
          ),
        ),
      ];

      for (final block in allBlocks) {
        // 空内容的 content block 整体跳过（tool-only 响应不显示"回答"）
        if (block.type == BlockType.content &&
            (block.content == null || block.content!.isEmpty)) {
          continue;
        }
        final collapsed = _isCollapsed(block, exchange);
        final innerSlivers = <Widget>[
          SliverPinnedHeader(
            child: _buildInlineHeader(context, block, exchange, theme),
          ),
        ];
        if (!collapsed) {
          innerSlivers.add(
            SliverToBoxAdapter(
              child: _buildBlockContent(
                context,
                theme,
                block,
                bus,
                exchange,
                viewportHeight,
              ),
            ),
          );
        }
        groupSlivers.add(SliverMainAxisGroup(slivers: innerSlivers));
      }

      if (shouldShowThinkingPlaceholder(exchange)) {
        groupSlivers.add(
          SliverToBoxAdapter(
            child: buildThinkingPlaceholder(context, exchange),
          ),
        );
      }

      if (exchange.status == ExchangeStatus.failed &&
          exchange.errorMessage != null &&
          exchange.errorMessage!.isNotEmpty) {
        final errCollapsed = _isErrorCollapsed(exchange);
        final errKey = _errorCollapseKey(exchange);
        final errSlivers = <Widget>[
          SliverToBoxAdapter(
            child: _buildErrorHeader(context, theme, errKey, errCollapsed),
          ),
        ];
        if (!errCollapsed) {
          errSlivers.add(
            SliverToBoxAdapter(
              child: _buildErrorContent(context, exchange.errorMessage!, theme),
            ),
          );
        }
        groupSlivers.add(SliverMainAxisGroup(slivers: errSlivers));
      }

      slivers.add(SliverMainAxisGroup(slivers: groupSlivers));
    }
    return slivers;
  }

  Widget _buildBlockContent(
    BuildContext context,
    ChatTheme theme,
    ChatBlock block,
    ChatBus bus,
    Exchange exchange,
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
              // 左侧竖线
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: lineColor),
              ),
              // 内容
              Padding(
                padding: EdgeInsets.only(left: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: viewportHeight * 0.618,
                  ),
                  child: SingleChildScrollView(
                    child: BlockRegistry.build(context, block, bus, exchange),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _errorCollapseKey(Exchange exchange) => '${exchange.id}_error';

  bool _isErrorCollapsed(Exchange exchange) {
    final key = _errorCollapseKey(exchange);
    if (_manuallyExpandedKeys.contains(key)) return false;
    if (_manuallyCollapsedKeys.contains(key)) return true;
    return false; // 默认展开
  }

  Widget _buildErrorHeader(
    BuildContext context,
    ChatTheme theme,
    String collapseKey,
    bool collapsed,
  ) {
    return SizedBox(
      height: 28.0,
      child: Padding(
        padding: EdgeInsets.only(left: theme.spacingLg),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 圆点
            Positioned(
              left: -17,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.bgPrimary,
                    border: Border.all(color: theme.error, width: 2),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () => _onToggleCollapsed(collapseKey, collapsed),
              child: buildBlockHeader(
                context: context,
                icon: Icons.error_outline,
                label: '错误',
                color: theme.error,
                theme: theme,
                showChevron: true,
                expanded: !collapsed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    String errorMessage,
    ChatTheme theme,
  ) {
    final isLight = theme.bgPrimary.computeLuminance() > 0.5;
    final verticalAlpha = isLight ? 0.25 : 0.2;

    return Padding(
      padding: theme.blockPadding,
      child: Stack(
        children: [
          // 左侧竖线
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: theme.error.withValues(alpha: verticalAlpha),
            ),
          ),
          // 错误消息
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 4),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: theme.fontSizeSm,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInlineHeader(
    BuildContext context,
    ChatBlock block,
    Exchange exchange,
    ChatTheme theme,
  ) {
    final collapseKey = '${exchange.id}_${block.id}';
    final collapsed = _isCollapsed(block, exchange);
    final sub = collapsed ? _firstParagraph(block) : null;

    return BlockAnimController(
      block: block,
      builder: (context, anim) {
        final dotColor = dotColorFor(block, theme);

        return SizedBox(
          height: 28.0,
          child: Padding(
            padding: EdgeInsets.only(left: theme.spacingLg),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -17,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: anim.isActive
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CustomPaint(
                              painter: RunningDotPainter(
                                color: dotColor,
                                rotation: anim.rotationValue,
                              ),
                            ),
                          )
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.bgPrimary,
                              border: Border.all(color: dotColor, width: 2),
                            ),
                          ),
                  ),
                ),
                InkWell(
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(ChatTheme theme) {
    final animValue = _focusAnimCtrl.value;
    const inputContentPadding = EdgeInsets.fromLTRB(4, 6, 4, 8);
    final inputFillColor = Color.lerp(
      theme.bgSurface,
      theme.bgInput,
      animValue,
    )!;
    final underlineBorder = _AccentUnderlineBorder(
      animationValue: animValue,
      accentColor: theme.accent,
      borderSide: BorderSide(color: theme.border, width: 1),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.borderLight)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  focusNode: _inputFocus,
                  cursorColor: theme.accent,
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(
                    color: theme.textInput,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: inputContentPadding,
                    hintText: '输入消息…',
                    hintStyle: TextStyle(color: theme.textPlaceholder),
                    enabledBorder: underlineBorder,
                    focusedBorder: underlineBorder,
                    border: underlineBorder,
                  ),
                ),
              ),
              SizedBox(width: 4),
              SizedBox(
                width: 28,
                height: 28,
                child: Material(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: _handleSend,
                    child: Center(
                      child: Icon(
                        bus.isStreaming
                            ? Icons.playlist_add
                            : Icons.send_rounded,
                        size: theme.iconSizeMd,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Badge — outside Row to avoid layout interference
          if (bus.queueCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: theme.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${bus.queueCount}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: theme.fontSizeSm - 2,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Accent Underline Border — animated expand-from-center
// ═══════════════════════════════════════════════════════

class _AccentUnderlineBorder extends InputBorder {
  final double animationValue;
  final Color accentColor;

  const _AccentUnderlineBorder({
    required this.animationValue,
    required this.accentColor,
    super.borderSide = const BorderSide(color: Color(0xFF484848), width: 1),
  });

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: borderSide.width);

  @override
  _AccentUnderlineBorder copyWith({BorderSide? borderSide}) =>
      _AccentUnderlineBorder(
        animationValue: animationValue,
        accentColor: accentColor,
        borderSide: borderSide ?? this.borderSide,
      );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final y = rect.bottom - 0.5;
    // 1px base line — always visible
    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      Paint()
        ..color = borderSide.color
        ..strokeWidth = 1.0,
    );

    // 2px accent line — expands from center on focus
    if (animationValue > 0.001) {
      final t = animationValue;
      final spread = 0.5 * t;
      final r = Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              accentColor,
              accentColor,
              Colors.transparent,
            ],
            stops: [0, 0.5 - spread, 0.5 + spread, 1],
          ).createShader(r),
      );
    }
  }

  @override
  ShapeBorder scale(double t) => _AccentUnderlineBorder(
    animationValue: animationValue,
    accentColor: accentColor,
    borderSide: borderSide.scale(t),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);
}

// ═══════════════════════════════════════════════════════
//  Last User Sticky Header
// ═══════════════════════════════════════════════════════

class _LastUserStickyHeader extends StatelessWidget {
  final String message;
  final ChatTheme theme;
  final double height;

  const _LastUserStickyHeader({
    required this.message,
    required this.theme,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final lineHeight = theme.fontSizeLg * 1.5;
    final padH = theme.spacingLg;
    final padV = theme.spacingSm + 2;
    final contentWidth = MediaQuery.of(context).size.width - padH * 2;

    final tp = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: theme.fontSizeLg,
          height: 1.5,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);
    final needsExpand = tp.didExceedMaxLines;
    final gradientStart = padV + lineHeight;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.bgSurface,
        border: Border(
          top: BorderSide(color: theme.borderStrong),
          left: BorderSide(color: theme.borderStrong),
          right: BorderSide(color: theme.borderStrong),
          bottom: BorderSide(color: theme.borderUser),
        ),
      ),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: Text(
                message,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: theme.fontSizeLg,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.clip,
              ),
            ),
            if (needsExpand)
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
            if (needsExpand)
              Positioned(
                right: 6,
                bottom: 4,
                child: InkWell(
                  onTap: () => _showExpandDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      '展开全部',
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
      ),
    );
  }

  void _showExpandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(theme.spacingLg),
        child: Container(
          decoration: BoxDecoration(
            color: theme.bgSurface,
            borderRadius: BorderRadius.circular(theme.radiusXl),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  theme.spacingLg,
                  theme.spacingMd,
                  theme.spacingSm,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '用户消息',
                        style: TextStyle(
                          fontSize: theme.fontSizeXl,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Padding(
                        padding: EdgeInsets.all(theme.spacingSm),
                        child: Icon(
                          Icons.close,
                          color: theme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(theme.spacingLg),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: theme.fontSizeLg,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  User Message Header — height calculation helper
// ═══════════════════════════════════════════════════════

class _UserMsgHeaderDelegate {
  static double computeHeight(String text, ChatTheme theme, double vpWidth) {
    final lineHeight = theme.fontSizeLg * 1.5;
    final padH = theme.spacingLg;
    final padV = theme.spacingSm + 2;
    final contentWidth = vpWidth - padH * 2;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: theme.fontSizeLg,
          height: 1.5,
        ),
      ),
      maxLines: 3,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: contentWidth);

    final textHeight = tp.didExceedMaxLines ? lineHeight * 3 : tp.height;
    return padV * 2 + textHeight;
  }
}

// ═══════════════════════════════════════════════════════
//  Queue Popup
// ═══════════════════════════════════════════════════════

class _QueuePopupContent extends StatelessWidget {
  final ChatBus bus;
  final VoidCallback onClose;

  const _QueuePopupContent({required this.bus, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final items = bus.queueItems;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: theme.bgPopup,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacingLg,
                theme.spacingMd,
                theme.spacingSm,
                theme.spacingSm,
              ),
              child: Row(
                children: [
                  Text(
                    '待发送消息',
                    style: TextStyle(
                      fontSize: theme.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: theme.textContent,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(theme.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: theme.iconSizeMd - 2,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.borderLight),
            Expanded(
              child: items.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(theme.spacingLg),
                      child: Text(
                        '待发送队列为空',
                        style: TextStyle(
                          fontSize: theme.fontSizeSm,
                          color: theme.textTertiary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(theme.spacingMd),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: theme.borderLight),
                      itemBuilder: (_, i) => Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: theme.spacingXs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: theme.iconSizeMd + 2,
                              height: theme.iconSizeMd + 2,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.bgHover,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: theme.fontSizeSm - 2,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: theme.spacingSm),
                            Expanded(
                              child: Text(
                                items[i],
                                style: TextStyle(
                                  fontSize: theme.fontSizeMd,
                                  color: theme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
