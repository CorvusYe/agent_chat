import 'chat_block.dart';

enum ExchangeStatus {
  queuing,
  processing,
  waitingInput,
  completed,
  failed,
  cancelled;

  bool get isActive =>
      this == ExchangeStatus.processing ||
      this == ExchangeStatus.waitingInput;
}

class Exchange {
  final String id;
  final String userMessage;
  final DateTime timestamp;
  final List<BlockGroup> groups;
  final ExchangeStatus status;
  final int totalTokens;
  final Duration? elapsed;
  final String? errorMessage;

  const Exchange({
    required this.id,
    required this.userMessage,
    required this.timestamp,
    this.groups = const [],
    this.status = ExchangeStatus.processing,
    this.totalTokens = 0,
    this.elapsed,
    this.errorMessage,
  });

  Exchange copyWith({
    List<BlockGroup>? groups,
    ExchangeStatus? status,
    int? totalTokens,
    Duration? elapsed,
    String? errorMessage,
  }) {
    return Exchange(
      id: id,
      userMessage: userMessage,
      timestamp: timestamp,
      groups: groups ?? this.groups,
      status: status ?? this.status,
      totalTokens: totalTokens ?? this.totalTokens,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get shortUserMessage =>
      userMessage.length > 60
          ? '${userMessage.substring(0, 60)}…'
          : userMessage;
}
