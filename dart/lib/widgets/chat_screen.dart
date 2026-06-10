import 'dart:async';
import 'dart:ui' show ImageFilter;
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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  bool _queueVisible = false;
  Timer? _statsTimer;
  final Set<String> _userCollapsedBlockIds = {};

  ChatBus get bus => widget.bus;

  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(() {
      if (mounted) setState(() {});
    });
    bus.addListener(_onBusChanged);
    bus.init();
    _statsTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (bus.isStreaming && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _inputFocus.dispose();
    bus.removeListener(_onBusChanged);
    bus.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }

  void _onBusChanged() {
    if (mounted) setState(() {});
  }

  void _onToggleCollapsed(String collapseKey, bool currentlyCollapsed) {
    setState(() {
      if (currentlyCollapsed) {
        _userCollapsedBlockIds.remove(collapseKey);
      } else {
        _userCollapsedBlockIds.add(collapseKey);
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
      data: ThemeData(
        extensions: [chatTheme],
        brightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: chatTheme.bgPrimary,
        body: Column(
          children: [
            Expanded(
              child: _buildMessages(chatTheme),
            ),
            StatsBar(
              elapsed: bus.elapsed,
              totalTokens: bus.totalTokens,
            ),
            _buildInput(chatTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(ChatTheme theme) {
    if (bus.isLoadingHistory) {
      return Center(
        child: widget.loadingIndicator ??
            CircularProgressIndicator(color: theme.accent),
      );
    }

    if (bus.exchanges.isEmpty) {
      return Center(
        child: widget.emptyPlaceholder ??
            Text(
              '发送一条消息开始对话',
              style: TextStyle(
                  color: theme.textTertiary, fontSize: theme.fontSizeLg),
            ),
      );
    }

    final viewportWidth = MediaQuery.of(context).size.width;
    final viewportHeight = MediaQuery.of(context).size.height;

    return CustomScrollView(
      controller: _scrollCtrl,
      slivers:
          _buildExchangeSlivers(theme, viewportWidth, viewportHeight),
    );
  }

  List<Widget> _buildExchangeSlivers(
      ChatTheme theme, double viewportWidth, double viewportHeight) {
    final slivers = <Widget>[];
    for (final exchange in bus.exchanges) {
      final allBlocks = exchange.groups.expand((g) => g.blocks).toList();

      final exHeaderHeight = _UserMsgHeaderDelegate.computeHeight(
          exchange.userMessage, theme, viewportWidth);

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
        final collapseKey = '${exchange.id}_${block.id}';
        final collapsed = _userCollapsedBlockIds.contains(collapseKey);
        final innerSlivers = <Widget>[
          SliverPinnedHeader(
            child: _buildInlineHeader(context, block, exchange, theme),
          ),
        ];
        if (!collapsed) {
          innerSlivers.add(
            SliverToBoxAdapter(
              child: _buildBlockContent(
                  context, theme, block, bus, exchange, viewportHeight),
            ),
          );
        }
        groupSlivers.add(
          SliverMainAxisGroup(slivers: innerSlivers),
        );
      }

      slivers.add(
        SliverMainAxisGroup(slivers: groupSlivers),
      );
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
    return Padding(
      padding: EdgeInsets.only(left: theme.spacingLg),
      child: Stack(
        children: [
          // 左侧竖线
          Positioned(
            left: 4,
            top: 0,
            bottom: 8,
            child: Container(
              width: 2,
              color: theme.border,
            ),
          ),
          // 内容
          Padding(
            padding: EdgeInsets.only(left: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: viewportHeight * 0.618,
              ),
              child: SingleChildScrollView(
                child: BlockRegistry.build(
                    context, block, bus, exchange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineHeader(BuildContext context, ChatBlock block, Exchange exchange, ChatTheme theme) {
    final collapseKey = '${exchange.id}_${block.id}';
    final collapsed = _userCollapsedBlockIds.contains(collapseKey);
    final dotColor = dotColorFor(block, theme);

    return SizedBox(
      height: 28.0,
      child: Padding(
        padding: EdgeInsets.only(left: theme.spacingLg),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -17, top: 0, bottom: 0,
              child: Center(
                child: Container(
                  width: 12, height: 12,
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
                color: headerColorFor(block, theme),
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

  Widget _buildInput(ChatTheme theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        theme.spacingXl,
        theme.spacingXs + 2,
        theme.spacingXl,
        theme.spacingSm + MediaQuery.of(context).padding.bottom,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.bgInput,
                  border: Border.all(
                    color: _inputFocus.hasFocus
                        ? theme.accentLight
                        : theme.border,
                    width: _inputFocus.hasFocus ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          contentPadding: EdgeInsets.fromLTRB(
                              16, 8, 0, 6),
                          hintText: '输入消息…',
                          hintStyle: TextStyle(
                              color: theme.textPlaceholder),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Material(
                        color: theme.accent,
                        borderRadius:
                            BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(8),
                          onTap: _handleSend,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Icon(
                                  bus.isStreaming
                                      ? Icons.playlist_add
                                      : Icons.send_rounded,
                                  size: theme.iconSizeMd,
                                  color: Colors.white,
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
            ),
          ),
          // Badge — outside ClipRRect to avoid clipping
          if (bus.queueCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(
                    minWidth: 18, minHeight: 18),
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
          if (_queueVisible)
            Positioned(
              right: 0,
              bottom: 60,
              child: _QueuePopupContent(
                bus: bus,
                onClose: _toggleQueue,
              ),
            ),
        ],
      ),
    );
  }
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
              padding: EdgeInsets.symmetric(
                  horizontal: padH, vertical: padV),
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
                        color: theme.accentLight
                            .withValues(alpha: 0.75),
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
            borderRadius:
                BorderRadius.circular(theme.radiusXl),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(theme.spacingLg,
                    theme.spacingMd, theme.spacingSm, 0),
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
                        padding:
                            EdgeInsets.all(theme.spacingSm),
                        child: Icon(Icons.close,
                            color: theme.textSecondary,
                            size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.all(theme.spacingLg),
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
  static double computeHeight(
      String text, ChatTheme theme, double vpWidth) {
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

    final textHeight =
        tp.didExceedMaxLines ? lineHeight * 3 : tp.height;
    return padV * 2 + textHeight;
  }
}


// ═══════════════════════════════════════════════════════
//  Queue Popup
// ═══════════════════════════════════════════════════════

class _QueuePopupContent extends StatelessWidget {
  final ChatBus bus;
  final VoidCallback onClose;

  const _QueuePopupContent({
    required this.bus,
    required this.onClose,
  });

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
                  theme.spacingLg, theme.spacingMd, theme.spacingSm, theme.spacingSm),
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
            Flexible(
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
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: theme.borderLight),
                      itemBuilder: (_, i) => Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: theme.spacingXs),
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
