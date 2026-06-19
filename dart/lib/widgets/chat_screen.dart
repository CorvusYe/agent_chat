import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../bus/chat_bus.dart';
import '../models/exchange.dart';
import '../theme/chat_theme.dart';
import 'exchange_widget.dart';
import 'block_timeline_section.dart';
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
    final chatTheme = widget.theme ?? ChatTheme.of(context);

    return Theme(
      data: ThemeData(
        extensions: [chatTheme],
        brightness: Theme.of(context).brightness,
      ),
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

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        controller: _scrollCtrl,
        clipBehavior: Clip.none,
        slivers: _buildExchangeSlivers(theme, viewportWidth, viewportHeight),
      ),
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

      final groupSlivers = <Widget>[
        SliverPinnedHeader(
          child: _LastUserStickyHeader(
            message: exchange.userMessage,
            theme: theme,
            height: exHeaderHeight,
          ),
        ),
      ];

      final hasBlocks = allBlocks.isNotEmpty;
      final hasThinking = shouldShowThinkingPlaceholder(exchange);
      final hasError =
          exchange.status == ExchangeStatus.failed &&
          exchange.errorMessage != null &&
          exchange.errorMessage!.isNotEmpty;
      if (hasBlocks || hasThinking || hasError) {
        if (theme.timelineTopGap > 0) {
          groupSlivers.add(
            SliverToBoxAdapter(child: SizedBox(height: theme.timelineTopGap)),
          );
        }
        groupSlivers.add(BlockTimelineSection(exchange: exchange, bus: bus));
      }

      slivers.add(SliverMainAxisGroup(slivers: groupSlivers));
    }
    return slivers;
  }

  Widget _buildInput(ChatTheme theme) {
    final animValue = _focusAnimCtrl.value;
    final inputField = Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: theme.inputContainerDecoration(animValue),
      child: TextField(
        controller: _textCtrl,
        focusNode: _inputFocus,
        cursorColor: theme.accent,
        textAlignVertical: TextAlignVertical.center,
        maxLines: 5,
        minLines: 1,
        style: TextStyle(color: theme.textInput, fontSize: 14, height: 1.5),
        decoration: InputDecoration(
          isCollapsed: true,
          filled: true,
          fillColor: theme.inputFillColor(animValue),
          contentPadding: theme.inputContentPadding,
          hintText: '输入消息…',
          hintStyle: TextStyle(color: theme.textPlaceholder),
          enabledBorder: theme.inputUnderlineBorder(animValue),
          focusedBorder: theme.inputUnderlineBorder(animValue),
          border: theme.inputUnderlineBorder(animValue),
        ),
      ),
    );

    final sendButton = SizedBox(
      width: 28,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: theme.shadowLight,
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: theme.shadowDark,
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _handleSend,
            child: Center(
              child: Icon(
                bus.isStreaming ? Icons.playlist_add : Icons.send_rounded,
                size: theme.iconSizeMd,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.bgSurface,
        border: Border(top: BorderSide(color: theme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowDark,
            offset: const Offset(0, -2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: inputField),
              SizedBox(width: theme.inputButtonGap),
              sendButton,
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

    final decoration = theme.cardDecoration();

    return Container(
      width: double.infinity,
      decoration: decoration,
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

    final decoration = BoxDecoration(
      color: theme.bgPopup,
      borderRadius: BorderRadius.circular(theme.radiusXl),
      border: Border.all(color: theme.border),
      boxShadow: [
        BoxShadow(
          color: theme.shadowLight,
          offset: const Offset(-6, -6),
          blurRadius: 16,
        ),
        BoxShadow(
          color: theme.shadowDark,
          offset: const Offset(6, 6),
          blurRadius: 16,
        ),
        if (theme.shadowLight.a == 0 && theme.shadowDark.a == 0)
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: decoration,
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
