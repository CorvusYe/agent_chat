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

class ExchangeError extends ExchangeEvent {
  final String errorMessage;
  const ExchangeError(super.exchangeId, this.errorMessage);
}
