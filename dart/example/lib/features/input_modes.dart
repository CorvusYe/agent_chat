// 输入组件演示 — ChatInput 多种按钮配置
//
// 展示 ChatInput 在不同配置下的外观和行为：
//   - 默认（仅发送按钮）
//   - 带队列切换按钮
//   - 带 Token 附加按钮
//   - 纯文本模式
// 每个示例创建一个独立的 ChatBus + ChatScreen。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import '../app_l10n.dart';

class InputModesDemo extends StatefulWidget {
  const InputModesDemo({super.key});

  @override
  State<InputModesDemo> createState() => _InputModesDemoState();
}

class _InputModesDemoState extends State<InputModesDemo>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: AppL10n.of(context).inputDefault),
            Tab(text: AppL10n.of(context).inputQueue),
            Tab(text: AppL10n.of(context).inputToken),
            Tab(text: AppL10n.of(context).inputTextOnly),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _InputExample(
                showQueueBtn: false,
                showTokenBtn: false,
                label: '默认',
              ),
              _InputExample(
                showQueueBtn: true,
                showTokenBtn: false,
                label: '队列',
              ),
              _InputExample(
                showQueueBtn: false,
                showTokenBtn: true,
                label: 'Token',
              ),
              _TextOnlyInput(label: '纯文本'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 使用 ChatScreen（带完整 UI）的示例
class _InputExample extends StatefulWidget {
  final bool showQueueBtn;
  final bool showTokenBtn;
  final String label;
  const _InputExample({
    required this.showQueueBtn,
    required this.showTokenBtn,
    required this.label,
  });

  @override
  State<_InputExample> createState() => _InputExampleState();
}

class _InputExampleState extends State<_InputExample> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(onGenerate: (text) => _mock(text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) bus.sendMessage('测试 ${widget.label} 模式输入框');
      });
    });
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  Stream<ExchangeEvent> _mock(String text) async* {
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 't');
    yield ThinkingDelta(id, 't', '收到，正在处理…');
    await Future.delayed(const Duration(milliseconds: 200));
    yield ThinkingCompleted(id, 't', '收到，正在处理…');
    yield ContentStarted(id, 'c');
    final reply = '已响应："$text"';
    yield ContentDelta(id, 'c', reply);
    yield ContentCompleted(id, 'c', reply);
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(bus: bus);
  }
}

/// 纯文本模式 — 不使用 ChatScreen，仅展示输入框 + 消息列表
class _TextOnlyInput extends StatefulWidget {
  final String label;
  const _TextOnlyInput({required this.label});

  @override
  State<_TextOnlyInput> createState() => _TextOnlyInputState();
}

class _TextOnlyInputState extends State<_TextOnlyInput> {
  final _controller = TextEditingController();
  final _sentMessages = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sentMessages.add(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                AppL10n.of(context).textFieldOnlyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ..._sentMessages.map(
                (m) => Card(
                  child: ListTile(
                    title: Text(m),
                    leading: const Icon(Icons.send),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: ChatL10n.of(context).inputHint,
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send), onPressed: _send),
            ],
          ),
        ),
      ],
    );
  }
}
