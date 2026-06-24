import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/chat_block.dart';
import '../bus/chat_bus.dart';
import '../theme/chat_theme.dart';
import 'block/block_utils.dart';
import 'block/block_timeline_item.dart';

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
        _buildUserMessage(context),
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
          return BlockTimelineItem(
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
    final lineHeight = theme.fontSizeLg * 1.5;
    final padH = theme.spacingLg;
    final padV = theme.spacingSm + 2;
    final collapsedHeight = padV * 2 + lineHeight * 3;
    final gradientStart = padV + lineHeight;
    final expandedMaxHeight = MediaQuery.of(context).size.height * 0.5;

    final textStyle = TextStyle(
      color: theme.textPrimary,
      fontSize: theme.fontSizeLg,
      height: 1.5,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - padH * 2;
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
          clipBehavior: Clip.hardEdge,
          decoration: decoration,
          child: Stack(
            children: [
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
