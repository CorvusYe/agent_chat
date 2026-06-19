import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/exchange_event.dart';

/// 外壳总线 — UI 层与业务逻辑的桥梁。
///
/// UI 层通过此接口读取状态并触发用户动作。
/// example 层实现此接口来对接 AI API 和业务逻辑。
abstract class ChatBus implements Listenable {
  // ── 状态数据（UI 只读） ──
  List<Exchange> get exchanges;
  bool get isLoadingHistory;
  bool get isStreaming;
  List<String> get queueItems;
  int get queueCount;
  int get totalTokens;
  Duration? get elapsed;
  int get activeExchangeCount;

  // ── 用户动作 ──
  void sendMessage(String text);
  void confirmTool(String exchangeId, String toolName, bool alwaysAllow);
  void cancelTool(String exchangeId, String toolName);
  void toggleQueue();

  // ── Token API（example 层调用） ──
  void addTokens(int count);

  // ── UI 注意信号：确认门待处理时用户滚动触发，块可据此闪烁 ──
  ValueNotifier<int> get attentionSignal;

  // ── AI 事件入口 ──
  void acceptEvents(String exchangeId, Stream<ExchangeEvent> events);

  // ── 生命周期 ──
  void init();
  void dispose();

  // ── 链式构造 ──
  static ChatBus withDecorators({
    required ChatBus impl,
    required List<ChatBus Function(ChatBus inner)> decorators,
  }) {
    var result = impl;
    for (final d in decorators) {
      result = d(result);
    }
    return result;
  }
}
