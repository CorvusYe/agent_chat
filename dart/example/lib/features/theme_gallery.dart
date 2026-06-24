// 主题画廊 — 暗色/亮色/内置 ChatTheme 切换 + ChatScreen 预览
//
// 展示 agent_chat 支持的主题能力：
//   - Brightness.dark / Brightness.light 切换
//   - 6 种 colorSchemeSeed 色彩
//   - 3 类 ChatTheme × 亮暗 = 6 种变体
//   - ChatTheme 全局应用

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import '../main.dart';
import '../app_l10n.dart';

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
    final L = AppL10n.of(context);

    return Column(
      children: [
        // 主题控制面板
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第1行：亮色/暗色 + 配色切换
              Row(
                children: [
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(L.light),
                        icon: const Icon(Icons.light_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(L.dark),
                        icon: const Icon(Icons.dark_mode, size: 16),
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
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => appState?.cycleColorSeed(),
                    icon: const Icon(Icons.palette_outlined, size: 20),
                    tooltip: L.switchColor,
                  ),
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
                    L.colorName(_themeNames[appState?.colorSeed] ?? 'teal'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 第2行：内置 ChatTheme 选择
              Row(
                children: [
                  Text(L.chatThemeLabel, style: theme.textTheme.labelSmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<int>(
                      value: appState?.chatThemeIndex ?? 0,
                      isDense: true,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Text(
                            L.themeFluent,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text(
                            L.themeDefault,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text(
                            L.themeNeumorphism,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) appState?.setChatThemeIndex(v);
                      },
                    ),
                  ),
                ],
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

final _themeNames = {
  Colors.teal: 'teal',
  Colors.indigo: 'indigo',
  Colors.deepPurple: 'purple',
  Colors.deepOrange: 'orange',
  Colors.blueGrey: 'blue grey',
  Colors.pink: 'pink',
};
