import 'package:flutter/material.dart';
import 'streaming_output.dart';
import 'tool_calls_demo.dart';
import 'confirmation_gate.dart';
import 'queue_demo.dart';
import 'input_modes.dart';
import 'history_demo.dart';
import 'custom_blocks_demo.dart';
import 'theme_gallery.dart';
import 'stats_demo.dart';
import 'custom_theme_demo.dart';

/// 特性描述
class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  const _Feature(this.title, this.subtitle, this.icon, this.builder);
}

final _features = <_Feature>[
  _Feature(
    '流输出展示',
    '打字机效果的 thinking / content delta',
    Icons.text_fields,
    (_) => const StreamingOutputDemo(),
  ),
  _Feature(
    '工具调用展示',
    'ToolCall block 各状态渲染',
    Icons.build_circle,
    (_) => const ToolCallsDemo(),
  ),
  _Feature(
    '确认门演示',
    '工具需确认时的对话框流程',
    Icons.gpp_maybe,
    (_) => const ConfirmationGateDemo(),
  ),
  _Feature('队列模式', '流式发送消息入队 → 自动排空', Icons.queue, (_) => const QueueDemo()),
  _Feature(
    '输入组件',
    'ChatInput 多种按钮配置',
    Icons.keyboard,
    (_) => const InputModesDemo(),
  ),
  _Feature('历史加载', '模拟载入多轮对话历史', Icons.history, (_) => const HistoryDemo()),
  _Feature(
    '自定义块',
    'CustomBlock + BlockRegistry',
    Icons.widgets,
    (_) => const CustomBlocksDemo(),
  ),
  _Feature(
    '主题画廊',
    '暗色/亮色/内置 ChatTheme 切换',
    Icons.palette,
    (_) => const ThemeGallery(),
  ),
  _Feature(
    '自定义主题',
    '动态创建 ChatTheme 实时预览',
    Icons.colorize,
    (_) => const CustomThemeDemo(),
  ),
  _Feature('统计栏', 'Token 计数 / 耗时显示', Icons.bar_chart, (_) => const StatsDemo()),
];

class FeatureHub extends StatefulWidget {
  const FeatureHub({super.key});

  @override
  State<FeatureHub> createState() => _FeatureHubState();
}

class _FeatureHubState extends State<FeatureHub> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final feature = _features[_current];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Agent Chat',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '特性展示',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withAlpha(
                          179,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _features.length,
                  itemBuilder: (_, i) {
                    final f = _features[i];
                    final selected = i == _current;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: theme.colorScheme.primaryContainer
                          .withAlpha(77),
                      leading: Icon(
                        f.icon,
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        f.title,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: Text(
                        f.subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        setState(() => _current = i);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _features[_current].builder(context),
    );
  }
}
