// 主题画廊 — 暗色/亮色/多彩切换 + ChatScreen 预览
//
// 展示 agent_chat 支持的主题能力：
//   - Brightness.dark 暗色主题
//   - Brightness.light 亮色主题
//   - 多种 colorSchemeSeed 色彩
//   - ChatTheme / themes.dart 的自定义

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import '../main.dart';

class ThemeGallery extends StatefulWidget {
  const ThemeGallery({super.key});

  @override
  State<ThemeGallery> createState() => _ThemeGalleryState();
}

class _ThemeGalleryState extends State<ThemeGallery> {
  late final ChatBus bus;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockReply,
      onInterrupt: () => _cancelled = true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDemo());
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  bool _cancelled = false;

  Future<void> _autoDemo() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    bus.sendMessage('测试主题视觉效果');
  }

  Stream<ExchangeEvent> _mockReply(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 't');
    yield ThinkingDelta(id, 't', '正在思考…');
    await Future.delayed(const Duration(milliseconds: 300));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 't', '正在思考…');

    yield ToolCallStarted(id, 'tc', 'demo_tool', {'mode': 'theme_preview'});
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tc', '✓ 主题切换演示');

    yield ParallelBoundary(id);
    yield ContentStarted(id, 'c');
    const reply = '当前主题效果预览。可以通过上方的控制面板切换主题。';
    yield ContentDelta(id, 'c', reply);
    yield ContentCompleted(id, 'c', reply);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ShowcaseApp.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // 主题控制面板
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              // 亮色 / 暗色 切换
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('亮色'),
                    icon: Icon(Icons.light_mode, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('暗色'),
                    icon: Icon(Icons.dark_mode, size: 16),
                  ),
                ],
                selected: {appState?.themeMode ?? ThemeMode.dark},
                onSelectionChanged: (modes) {
                  appState?.setThemeMode(modes.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              // 色彩切换按钮
              IconButton(
                onPressed: () => appState?.cycleColorSeed(),
                icon: const Icon(Icons.palette_outlined, size: 20),
                tooltip: '切换配色',
              ),
              const Spacer(),
              // 当前配色指示
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: appState?.colorSeed ?? Colors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _themeNames[appState?.colorSeed] ?? 'teal',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Chat 预览
        Expanded(child: ChatScreen(bus: bus)),
      ],
    );
  }
}

final _themeNames = <MaterialColor, String>{
  Colors.teal: 'teal',
  Colors.indigo: 'indigo',
  Colors.deepPurple: 'purple',
  Colors.deepOrange: 'orange',
  Colors.blueGrey: 'blue grey',
  Colors.pink: 'pink',
};
