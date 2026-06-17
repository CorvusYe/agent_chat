import 'chat_block.dart';

sealed class ExchangeEvent {
  final String exchangeId;
  const ExchangeEvent(this.exchangeId);
}

class ThinkingStarted extends ExchangeEvent {
  final String blockId;
  const ThinkingStarted(super.exchangeId, this.blockId);
}

class ThinkingDelta extends ExchangeEvent {
  final String blockId;
  final String text;
  const ThinkingDelta(super.exchangeId, this.blockId, this.text);
}

class ThinkingCompleted extends ExchangeEvent {
  final String blockId;
  final String fullText;
  const ThinkingCompleted(super.exchangeId, this.blockId, this.fullText);
}

class ToolCallStarted extends ExchangeEvent {
  final String blockId;
  final String toolName;
  final Map<String, dynamic> arguments;
  final bool requiresConfirm;
  final bool autoApproved;
  final String? description;
  final bool canAlwaysAllow;

  const ToolCallStarted(
    super.exchangeId,
    this.blockId,
    this.toolName,
    this.arguments, {
    this.requiresConfirm = false,
    this.autoApproved = false,
    this.description,
    this.canAlwaysAllow = true,
  });
}

class ToolCallDelta extends ExchangeEvent {
  final String blockId;
  final String resultFragment;
  const ToolCallDelta(super.exchangeId, this.blockId, this.resultFragment);
}

class ToolCallCompleted extends ExchangeEvent {
  final String blockId;
  final String result;
  const ToolCallCompleted(super.exchangeId, this.blockId, this.result);
}

class ContentStarted extends ExchangeEvent {
  final String blockId;
  const ContentStarted(super.exchangeId, this.blockId);
}

class ContentDelta extends ExchangeEvent {
  final String blockId;
  final String text;
  const ContentDelta(super.exchangeId, this.blockId, this.text);
}

class ContentCompleted extends ExchangeEvent {
  final String blockId;
  final String fullText;
  const ContentCompleted(super.exchangeId, this.blockId, this.fullText);
}

class ParallelBoundary extends ExchangeEvent {
  const ParallelBoundary(super.exchangeId);
}

class TokenCount extends ExchangeEvent {
  final int count;
  const TokenCount(super.exchangeId, this.count);
}

class ExchangeError extends ExchangeEvent {
  final String errorMessage;
  const ExchangeError(super.exchangeId, this.errorMessage);
}

/// 自定义块事件 — 用于渲染非标准 BlockType（如 vine_ai 的 YAML/MMD 块）。
///
/// 通过此事件，任何自定义 BlockType 都可以在 Exchange 的事件流中传递，
/// DefaultChatBus 会将其创建为 ChatBlock 并传递给 BlockRegistry 渲染。
///
/// [blockType] — 自定义块类型名称（对应 BlockType.custom(name)）。
/// [content] — 块主体文本内容（如 YAML/MMD 原始文本）。
/// [label] — 块标题标签（如节点名称或工作流名称）。
/// [status] — 块状态（默认 completed，渲染器可直接显示）。
/// [metadata] — 额外元数据（可供渲染器按需使用）。
class CustomBlockEvent extends ExchangeEvent {
  final String blockId;
  final String blockType;
  final String? content;
  final String? label;
  final BlockStatus status;
  final Map<String, dynamic>? metadata;

  const CustomBlockEvent(
    super.exchangeId,
    this.blockId,
    this.blockType, {
    this.content,
    this.label,
    this.status = BlockStatus.completed,
    this.metadata,
  });
}
