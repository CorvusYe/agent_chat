import 'dart:async';
import 'package:flutter/material.dart';
import '../models/exchange.dart';
import '../models/exchange_event.dart';
import '../models/chat_block.dart';
import 'chat_bus.dart';

/// DefaultChatBus — 内置的 ChatBus 实现。
///
/// 管理 Exchange 状态、处理事件流、支持确认门暂停。
/// example 层可以通过 onGenerate 回调提供 AI 事件流，
/// 或直接继承此类覆写 sendMessage。
class DefaultChatBus with ChangeNotifier implements ChatBus {
  final List<Exchange> _exchanges = [];
  final List<String> _queue = [];
  final Set<String> _trustedTools = {};
  String? _globalAlwaysAllow;
  final Map<String, Completer<void>> _pendingConfirms = {};
  final Set<String> _activeExchanges = {};
  DateTime? _startTime;
  Duration? _lastElapsed;

  /// AI 事件生成回调。设置后 sendMessage 自动调用此回调。
  Stream<ExchangeEvent> Function(String text)? onGenerate;

  bool _disposed = false;

  int _nextId = 0;
  String _genId() => 'ex_${DateTime.now().millisecondsSinceEpoch}_${_nextId++}';

  DefaultChatBus({this.onGenerate});

  // ── ChatBus ──

  @override
  List<Exchange> get exchanges => List.unmodifiable(_exchanges);

  @override
  bool get isLoadingHistory => false;

  @override
  bool get isStreaming => _activeExchanges.isNotEmpty;

  @override
  List<String> get queueItems => List.unmodifiable(_queue);

  @override
  int get queueCount => _queue.length;

  @override
  int get totalTokens => 0;

  @override
  Duration? get elapsed => _startTime != null
      ? DateTime.now().difference(_startTime!)
      : _lastElapsed;

  @override
  int get activeExchangeCount => _activeExchanges.length;

  @override
  void sendMessage(String text) {
    final id = _genId();
    _exchanges.add(
      Exchange(id: id, userMessage: text, timestamp: DateTime.now()),
    );
    _activeExchanges.add(id);
    if (_activeExchanges.length == 1) _startTime = DateTime.now();
    notifyListeners();

    final stream = onGenerate?.call(text);
    if (stream != null) acceptEvents(id, stream);
  }

  @override
  void confirmTool(String exchangeId, String toolName, bool alwaysAllow) {
    if (alwaysAllow) {
      _trustedTools.add(toolName);
      _globalAlwaysAllow = toolName;
    }
    _updateBlockInExchange(
      exchangeId,
      toolName,
      (b) => b.copyWith(status: BlockStatus.approved),
    );
    _pendingConfirms.remove(exchangeId)?.complete();
    notifyListeners();
  }

  @override
  void cancelTool(String exchangeId, String toolName) {
    _updateBlockInExchange(
      exchangeId,
      toolName,
      (b) => b.copyWith(status: BlockStatus.cancelled),
    );
    _pendingConfirms.remove(exchangeId)?.complete();
    notifyListeners();
  }

  @override
  void toggleQueue() {
    // UI 管理的队列弹窗状态
  }

  @override
  void acceptEvents(String exchangeId, Stream<ExchangeEvent> events) {
    _processEventStream(exchangeId, events);
  }

  @override
  void init() {
    // 子类可在此处加载持久化数据
  }

  @override
  void dispose() {
    _disposed = true;
    _activeExchanges.clear();
    _pendingConfirms.clear();
    _exchanges.clear();
    _queue.clear();
    super.dispose();
  }

  // ── 内部 ──

  int _groupCounter = 0;

  Future<void> _processEventStream(
    String exchangeId,
    Stream<ExchangeEvent> stream,
  ) async {
    var pendingBlocks = <ChatBlock>[];
    _groupCounter = 0;

    try {
      await for (final event in stream) {
        switch (event) {
          case ThinkingStarted e:
            pendingBlocks.add(
              ChatBlock(
                id: e.blockId,
                type: BlockType.thinking,
                content: '',
                status: BlockStatus.running,
              ),
            );

          case ThinkingDelta e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(content: e.text),
            );

          case ThinkingCompleted e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(
                content: e.fullText,
                status: BlockStatus.completed,
              ),
            );

          case ToolCallStarted e:
            final autoApproved =
                e.autoApproved ||
                _trustedTools.contains(e.toolName) ||
                _globalAlwaysAllow == e.toolName;
            pendingBlocks.add(
              ChatBlock(
                id: e.blockId,
                type: BlockType.tool,
                toolName: e.toolName,
                toolArgs: e.arguments,
                requiresConfirm: e.requiresConfirm && !autoApproved,
                canAlwaysAllow: e.canAlwaysAllow,
                description: e.description,
                status: e.requiresConfirm && !autoApproved
                    ? BlockStatus.pending
                    : BlockStatus.running,
              ),
            );

          case ToolCallDelta e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(
                toolResult: (b.toolResult ?? '') + e.resultFragment,
              ),
            );

          case ToolCallCompleted e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(
                toolResult: e.result,
                status: BlockStatus.completed,
              ),
            );

          case ContentStarted e:
            pendingBlocks.add(
              ChatBlock(
                id: e.blockId,
                type: BlockType.content,
                content: '',
                status: BlockStatus.running,
              ),
            );

          case ContentDelta e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(content: e.text),
            );

          case ContentCompleted e:
            _updateBlockSafe(
              exchangeId,
              pendingBlocks,
              e.blockId,
              (b) => b.copyWith(
                content: e.fullText,
                status: BlockStatus.completed,
              ),
            );

          case ParallelBoundary _:
            _flushGroup(exchangeId, pendingBlocks);
            pendingBlocks = [];

          case ExchangeError e:
            _updateExchange(
              exchangeId,
              (ex) => ex.copyWith(
                status: ExchangeStatus.failed,
                errorMessage: e.errorMessage,
              ),
            );
            return;
        }

        notifyListeners();

        // 确认门暂停
        if (event is ToolCallStarted &&
            event.requiresConfirm &&
            !_trustedTools.contains(event.toolName) &&
            _globalAlwaysAllow != event.toolName &&
            !event.autoApproved) {
          // 先 flush 当前批 blocks，让确认门可以渲染
          _flushGroup(exchangeId, pendingBlocks);
          pendingBlocks = [];
          _updateExchange(
            exchangeId,
            (ex) => ex.copyWith(status: ExchangeStatus.waitingInput),
          );
          notifyListeners();
          final completer = Completer<void>();
          _pendingConfirms[exchangeId] = completer;
          await completer.future;
          _updateExchange(
            exchangeId,
            (ex) => ex.copyWith(status: ExchangeStatus.processing),
          );
          notifyListeners();
        }
      }

      // 刷新最后一批 blocks
      if (pendingBlocks.isNotEmpty) {
        _flushGroup(exchangeId, pendingBlocks);
      }
      _completeExchange(exchangeId);
    } catch (e) {
      _updateExchange(
        exchangeId,
        (ex) => ex.copyWith(
          status: ExchangeStatus.failed,
          errorMessage: e.toString(),
        ),
      );
      if (!_disposed) notifyListeners();
    } finally {
      _activeExchanges.remove(exchangeId);
      if (_activeExchanges.isEmpty) {
        if (_startTime != null) {
          _lastElapsed = DateTime.now().difference(_startTime!);
        }
        _startTime = null;
      }
      if (!_disposed) notifyListeners();
    }
  }

  void _flushGroup(String exchangeId, List<ChatBlock> blocks) {
    if (blocks.isEmpty) return;
    final group = BlockGroup(
      id: 'g_${_groupCounter++}',
      blocks: List.of(blocks),
    );
    _updateExchange(
      exchangeId,
      (ex) => ex.copyWith(groups: [...ex.groups, group]),
    );
  }

  void _updateBlockById(
    String exchangeId,
    String blockId,
    ChatBlock Function(ChatBlock) transform,
  ) {
    _updateExchange(exchangeId, (ex) {
      final updatedGroups = ex.groups.map((g) {
        final updatedBlocks = g.blocks.map((b) {
          return b.id == blockId ? transform(b) : b;
        }).toList();
        return g.copyWith(blocks: updatedBlocks);
      }).toList();
      return ex.copyWith(groups: updatedGroups);
    });
  }

  /// 在 pendingBlocks 或已刷新的 groups 中更新 block。
  /// pendingBlocks 是当前未刷新的块列表（_processEventStream 中局部变量）。
  void _updateBlockSafe(
    String exchangeId,
    List<ChatBlock> pendingBlocks,
    String blockId,
    ChatBlock Function(ChatBlock) transform,
  ) {
    final idx = pendingBlocks.indexWhere((b) => b.id == blockId);
    if (idx != -1) {
      pendingBlocks[idx] = transform(pendingBlocks[idx]);
    } else {
      _updateBlockById(exchangeId, blockId, transform);
    }
  }

  void _updateBlockInExchange(
    String exchangeId,
    String toolName,
    ChatBlock Function(ChatBlock) transform,
  ) {
    _updateExchange(exchangeId, (ex) {
      final updatedGroups = ex.groups.map((g) {
        final updatedBlocks = g.blocks.map((b) {
          if (b.toolName == toolName &&
              b.requiresConfirm &&
              b.status == BlockStatus.pending) {
            return transform(b);
          }
          return b;
        }).toList();
        return g.copyWith(blocks: updatedBlocks);
      }).toList();
      return ex.copyWith(groups: updatedGroups);
    });
  }

  void _completeExchange(String exchangeId) {
    _updateExchange(
      exchangeId,
      (ex) => ex.copyWith(status: ExchangeStatus.completed),
    );
  }

  void _updateExchange(
    String exchangeId,
    Exchange Function(Exchange) transform,
  ) {
    final idx = _exchanges.indexWhere((e) => e.id == exchangeId);
    if (idx == -1) return;
    _exchanges[idx] = transform(_exchanges[idx]);
  }

  // 子类可覆写
  void enqueueMessage(String text) {
    _queue.add(text);
    notifyListeners();
  }

  String? dequeueMessage() {
    if (_queue.isEmpty) return null;
    final item = _queue.removeAt(0);
    notifyListeners();
    return item;
  }
}
