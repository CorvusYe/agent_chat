// 自定义主题 Demo — macOS 风格 ChatTheme
//
// 展示如何构建一个完整的 macOS 风格 ChatTheme，
// 包含亮色/暗色两套完整配色方案。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

/// macOS 风格亮色主题
ChatTheme macOSLightTheme() => ChatTheme(
  // ── 背景 ──
  bgPrimary: const Color(0xFFF5F5F7), // 系统灰白底
  bgSurface: const Color(0xFFFFFFFF), // 白色表面
  bgPopup: const Color(0xFFFFFFFF),
  bgInput: const Color(0xFFE8E8ED), // 输入框灰底
  bgCard: const Color(0xFFFFFFFF),
  bgCardHeader: const Color(0xFFF0F0F5),
  bgCommand: const Color(0xFFF0F0F5),
  bgHover: const Color(0xFFE8E8ED),
  bgHoverStrong: const Color(0xFFDCDCE0),
  bgWarning: const Color(0xFFFFF8E1),

  // ── 文字 ──
  textPrimary: const Color(0xFF1D1D1F), // 近乎黑
  textInput: const Color(0xFF1D1D1F),
  textContent: const Color(0xFF1D1D1F),
  textSecondary: const Color(0xFF86868B), // 次要灰
  textTertiary: const Color(0xFFAEAEB2), // 三级灰
  textToolResult: const Color(0xFF86868B),
  textToolHeader: const Color(0xFF007AFF), // macOS 蓝
  textPlaceholder: const Color(0xFFC7C7CC),

  // ── 强调色 ──
  accent: const Color(0xFF007AFF), // macOS 标准蓝
  accentHover: const Color(0xFF0066D6),
  accentActive: const Color(0xFF0055BF),
  accentLight: const Color(0xFF409CFF),
  accentAlpha: const Color(0x1F007AFF),
  success: const Color(0xFF34C759), // macOS 绿
  error: const Color(0xFFFF3B30), // macOS 红
  warning: const Color(0xFFFF9500), // macOS 橙
  // ── 边框 ──
  border: const Color(0xFFD2D2D7),
  borderLight: const Color(0xFFE5E5EA),
  borderStrong: const Color(0xFFB8B8BE),
  borderUser: const Color(0xFFC7C7CC),
  borderAccent: const Color(0x4D007AFF),
  borderWarning: const Color(0x33FF9500),

  // ── 状态点 ──
  dotThinking: const Color(0xFFAEAEB2),
  dotTool: const Color(0xFF007AFF),
  dotContent: const Color(0xFF007AFF),
  dotConfirm: const Color(0xFFFF9500),
  headerThinking: const Color(0xFFAEAEB2),
  headerTool: const Color(0xFF007AFF),
  headerContent: const Color(0xFF007AFF),
  headerConfirm: const Color(0xFFFF9500),

  // ── 装饰 ──
  chevronColor: const Color(0xFFAEAEB2),
  statColor: const Color(0xFFAEAEB2),
  spinnerColor: const Color(0xFFAEAEB2),
  btnSecondaryBg: const Color(0x1F007AFF),
);

/// macOS 风格暗色主题
ChatTheme macOSDarkTheme() => ChatTheme(
  // ── 背景 ──
  bgPrimary: const Color(0xFF1C1C1E), // 深灰底
  bgSurface: const Color(0xFF2C2C2E), // 表面
  bgPopup: const Color(0xFF2C2C2E),
  bgInput: const Color(0xFF3A3A3C),
  bgCard: const Color(0xFF2C2C2E),
  bgCardHeader: const Color(0xFF363638),
  bgCommand: const Color(0xFF363638),
  bgHover: const Color(0xFF3A3A3C),
  bgHoverStrong: const Color(0xFF48484A),
  bgWarning: const Color(0x1AFF9500),

  // ── 文字 ──
  textPrimary: const Color(0xFFF5F5F7), // 近乎白
  textInput: const Color(0xFFF5F5F7),
  textContent: const Color(0xFFF5F5F7),
  textSecondary: const Color(0xFF98989D),
  textTertiary: const Color(0xFF6E6E73),
  textToolResult: const Color(0xFF98989D),
  textToolHeader: const Color(0xFF64B5F6), // 浅蓝
  textPlaceholder: const Color(0xFF56565A),

  // ── 强调色 ──
  accent: const Color(0xFF64B5F6), // 浅蓝
  accentHover: const Color(0xFF4CA9F5),
  accentActive: const Color(0xFF339EF4),
  accentLight: const Color(0xFF82C5F8),
  accentAlpha: const Color(0x2F64B5F6),
  success: const Color(0xFF30D158), // macOS 暗绿
  error: const Color(0xFFFF453A), // macOS 暗红
  warning: const Color(0xFFFF9F0A), // macOS 暗橙
  // ── 边框 ──
  border: const Color(0xFF48484A),
  borderLight: const Color(0xFF3A3A3C),
  borderStrong: const Color(0xFF56565A),
  borderUser: const Color(0xFF48484A),
  borderAccent: const Color(0x4D64B5F6),
  borderWarning: const Color(0x40FF9F0A),

  // ── 状态点 ──
  dotThinking: const Color(0xFF6E6E73),
  dotTool: const Color(0xFF64B5F6),
  dotContent: const Color(0xFF64B5F6),
  dotConfirm: const Color(0xFFFF9F0A),
  headerThinking: const Color(0xFF6E6E73),
  headerTool: const Color(0xFF64B5F6),
  headerContent: const Color(0xFF64B5F6),
  headerConfirm: const Color(0xFFFF9F0A),

  // ── 装饰 ──
  chevronColor: const Color(0xFF6E6E73),
  statColor: const Color(0xFF6E6E73),
  spinnerColor: const Color(0xFF6E6E73),
  btnSecondaryBg: const Color(0x2F64B5F6),
);

class CustomThemeDemo extends StatefulWidget {
  const CustomThemeDemo({super.key});

  @override
  State<CustomThemeDemo> createState() => _CustomThemeDemoState();
}

class _CustomThemeDemoState extends State<CustomThemeDemo> {
  late final ChatBus bus;
  bool _dark = false;

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
    bus.sendMessage('展示 macOS 风格主题');
  }

  Stream<ExchangeEvent> _mockReply(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 't');
    yield ThinkingDelta(id, 't', '使用 macOS 风格渲染…');
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 't', '使用 macOS 风格渲染…');
    yield ToolCallStarted(id, 'tc', 'macOS_style', {
      'theme': _dark ? 'dark' : 'light',
    }, autoApproved: true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tc', '✓ macOS 风格主题已应用');
    yield ParallelBoundary(id);
    yield ContentStarted(id, 'c');
    const reply =
        '当前使用的是完整的 macOS 风格 ChatTheme。\n'
        '亮色模式：#F5F5F7 系统灰白底 + #007AFF 蓝色强调色\n'
        '暗色模式：#1C1C1E 深灰底 + #64B5F6 浅蓝强调色';
    yield ContentDelta(id, 'c', reply);
    yield ContentCompleted(id, 'c', reply);
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = _dark ? macOSDarkTheme() : macOSLightTheme();
    final theme = Theme.of(context);

    return Column(
      children: [
        // 控制面板
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              const Text(
                'macOS 风格',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('亮色'),
                    icon: Icon(Icons.light_mode, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('暗色'),
                    icon: Icon(Icons.dark_mode, size: 16),
                  ),
                ],
                selected: {_dark},
                onSelectionChanged: (v) => setState(() => _dark = v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.desktop_mac_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 预览
        Expanded(
          child: Theme(
            data: ThemeData(
              brightness: _dark ? Brightness.dark : Brightness.light,
              extensions: [chatTheme],
            ),
            child: ChatScreen(bus: bus),
          ),
        ),
      ],
    );
  }
}
