import 'package:flutter/material.dart';
import '../../models/exchange.dart';
import '../../models/chat_block.dart';
import '../../blocks/block_registry.dart';
import '../../theme/chat_theme.dart';
import '../../l10n/chat_l10n.dart';
import 'block_placeholder.dart';

/// 根据 block 状态/类型返回圆点颜色。
Color dotColorFor(ChatBlock block, ChatTheme theme) {
  if (block.status == BlockStatus.cancelled) return theme.error;
  if (block.status == BlockStatus.alwaysAllowed) return theme.success;
  if (block.status == BlockStatus.approved) return theme.accent;
  if (block.type == BlockType.thinking) return theme.dotThinking;
  if (block.type == BlockType.tool) return theme.dotTool;
  if (block.type == BlockType.content) return theme.dotContent;
  if (block.type == BlockType.confirmation) return theme.dotConfirm;
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.dotColor;
  return theme.dotContent;
}

/// 根据 block 类型返回 header 颜色。
Color headerColorFor(ChatBlock block, ChatTheme theme) {
  if (block.type == BlockType.thinking) return theme.headerThinking;
  if (block.type == BlockType.tool) return theme.headerTool;
  if (block.type == BlockType.content) return theme.headerContent;
  if (block.type == BlockType.confirmation) return theme.headerConfirm;
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.headerColor;
  return theme.headerContent;
}

/// 根据 block 类型返回标签文字。
String labelForBlock(ChatBlock block, [ChatL10n? l10n]) {
  final L = l10n ?? ChatL10n.zhHans;
  if (block.type == BlockType.thinking) return L.labelThinking;
  if (block.type == BlockType.tool) {
    return L.labelToolWith(block.toolName ?? '');
  }
  if (block.type == BlockType.content) return L.labelContent;
  if (block.type == BlockType.confirmation) return L.labelConfirm;
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.label;
  return block.toolName ?? L.labelCustom;
}

/// 根据 block 类型返回图标。
IconData iconForBlock(ChatBlock block) {
  if (block.type == BlockType.thinking) return Icons.psychology_outlined;
  if (block.type == BlockType.tool) return Icons.build_outlined;
  if (block.type == BlockType.content) return Icons.chat_bubble_outline;
  if (block.type == BlockType.confirmation) return Icons.help_outline;
  final style = BlockRegistry.getDef(block.type);
  if (style != null) return style.icon;
  return Icons.extension_outlined;
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

/// "正在思考"占位 widget。
Widget buildThinkingPlaceholder(BuildContext context, Exchange exchange) {
  return const ThinkingPlaceholder();
}
