import 'package:flutter/material.dart';
import '../../models/exchange.dart';
import '../../bus/chat_bus.dart';
import '../../theme/chat_theme.dart';
import 'block_utils.dart';
import 'block_timeline_item.dart';

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
    return BlockTimelineItem(
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
