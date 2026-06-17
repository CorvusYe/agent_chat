// 自定义主题 Demo — 用代码创建 ChatTheme + 实时预览
//
// 展示如何从头构建一个 ChatTheme，通过颜色选择器实时调整效果。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

class CustomThemeDemo extends StatefulWidget {
  const CustomThemeDemo({super.key});

  @override
  State<CustomThemeDemo> createState() => _CustomThemeDemoState();
}

class _CustomThemeDemoState extends State<CustomThemeDemo> {
  late final ChatBus bus;
  bool _dark = true;

  // ── 可调颜色 ──
  Color _bgPrimary = const Color(0xFF1a1a2e);
  Color _accent = const Color(0xFF3b82f6);
  Color _textPrimary = const Color(0xFFe0e0e0);

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
    bus.sendMessage('展示自定义主题效果');
  }

  Stream<ExchangeEvent> _mockReply(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';
    yield ThinkingStarted(id, 't');
    yield ThinkingDelta(id, 't', '使用自定义主题渲染…');
    await Future.delayed(const Duration(milliseconds: 200));
    if (_cancelled) return;
    yield ThinkingCompleted(id, 't', '使用自定义主题渲染…');
    yield ContentStarted(id, 'c');
    const reply = '这是一个使用动态创建的 ChatTheme 渲染的界面。';
    yield ContentDelta(id, 'c', reply);
    yield ContentCompleted(id, 'c', reply);
  }

  ChatTheme _buildTheme() {
    final p = _bgPrimary;
    // 根据主色自动推导其他颜色
    final isDark = _dark;
    final s = _accent;
    final t = _textPrimary;
    final surface = isDark
        ? Color.lerp(p, Colors.white, 0.08)!
        : Color.lerp(p, Colors.white, 0.92)!;
    final card = isDark
        ? Color.lerp(p, Colors.white, 0.04)!
        : Color.lerp(p, Colors.white, 0.96)!;
    final border = isDark
        ? Color.lerp(p, Colors.white, 0.10)!
        : Color.lerp(p, Colors.black, 0.12)!;
    final textSec = isDark
        ? Color.lerp(t, Colors.white, 0.4)!
        : Color.lerp(t, Colors.black, 0.5)!;

    return ChatTheme(
      bgPrimary: p,
      bgSurface: surface,
      bgPopup: surface,
      bgInput: isDark ? const Color(0x0AFFFFFF) : const Color(0xFFF5F5F5),
      bgCard: card,
      bgCardHeader: isDark
          ? Color.lerp(p, Colors.white, 0.06)!
          : Color.lerp(p, Colors.black, 0.03)!,
      bgCommand: isDark ? const Color(0x33000000) : const Color(0xFFF0F0F0),
      bgHover: isDark ? const Color(0x0FFFFFFF) : const Color(0xFFF0F0F0),
      bgHoverStrong: isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE0E0E0),
      bgWarning: isDark ? const Color(0x0AFBC324) : const Color(0xFFFFF8E1),
      textPrimary: t,
      textInput: t,
      textContent: t,
      textSecondary: textSec,
      textTertiary: isDark ? const Color(0xFF64748b) : const Color(0xFFA0A0A0),
      textToolResult: textSec,
      textToolHeader: s,
      textPlaceholder: isDark
          ? const Color(0x59FFFFFF)
          : const Color(0xFFB0B0B0),
      accent: s,
      accentHover: Color.lerp(s, isDark ? Colors.white : Colors.black, 0.1)!,
      accentActive: Color.lerp(s, isDark ? Colors.white : Colors.black, 0.2)!,
      accentLight: Color.lerp(s, Colors.white, 0.4)!,
      accentAlpha: s.withAlpha(64),
      success: isDark ? const Color(0xFF4ade80) : const Color(0xFF107c10),
      error: isDark ? const Color(0xFFf87171) : const Color(0xFFd13438),
      warning: isDark ? const Color(0xFFfbbf24) : const Color(0xFFff8d00),
      border: border,
      borderLight: isDark ? const Color(0x14FFFFFF) : const Color(0xFFE0E0E0),
      borderStrong: isDark ? const Color(0x26FFFFFF) : const Color(0xFFABABAB),
      borderUser: isDark ? const Color(0x40FFFFFF) : const Color(0xFFC7C7C7),
      borderAccent: s.withAlpha(77),
      borderWarning: isDark ? const Color(0x40FBC324) : const Color(0x33FF8D00),
      dotThinking: textSec,
      dotTool: s,
      dotContent: s,
      dotConfirm: isDark ? const Color(0xFFf59e0b) : const Color(0xFFff8d00),
      headerThinking: textSec,
      headerTool: s,
      headerContent: s,
      headerConfirm: isDark ? const Color(0xFFf59e0b) : const Color(0xFFff8d00),
      chevronColor: textSec.withAlpha(90),
      statColor: textSec.withAlpha(77),
      spinnerColor: textSec.withAlpha(77),
      btnSecondaryBg: s.withAlpha(18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = _buildTheme();
    final theme = Theme.of(context);

    return Column(
      children: [
        // 颜色控制面板
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 明暗切换
              Row(
                children: [
                  const Text('明暗', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('暗'),
                        icon: Icon(Icons.dark_mode, size: 16),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('亮'),
                        icon: Icon(Icons.light_mode, size: 16),
                      ),
                    ],
                    selected: {_dark},
                    onSelectionChanged: (v) => setState(() => _dark = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 颜色拾取
              _colorRow(
                '背景主色',
                _bgPrimary,
                (c) => setState(() => _bgPrimary = c),
              ),
              const SizedBox(height: 4),
              _colorRow('强调色', _accent, (c) => setState(() => _accent = c)),
              const SizedBox(height: 4),
              _colorRow(
                '文字主色',
                _textPrimary,
                (c) => setState(() => _textPrimary = c),
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

  Widget _colorRow(String label, Color color, ValueChanged<Color> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _pickColor(label, color, onChanged),
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickColor(
    String label,
    Color current,
    ValueChanged<Color> onChanged,
  ) async {
    // 简单预设颜色选择（避免系统颜色选择器依赖）
    final presets = <Color>[
      const Color(0xFF1a1a2e),
      const Color(0xFF1f1f1f),
      const Color(0xFF292929),
      const Color(0xFF2d3a5e),
      const Color(0xFF0d1117),
      const Color(0xFFfafafa),
      const Color(0xFF3b82f6),
      const Color(0xFF6C63FF),
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFF10b981),
      const Color(0xFFf59e0b),
      const Color(0xFFef4444),
      const Color(0xFFe0e0e0),
      const Color(0xFF1a1a1a),
      const Color(0xFF94a3b8),
      const Color(0xFF0078d4),
      const Color(0xFF479ef5),
    ];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('选择 $label', style: const TextStyle(fontSize: 16)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets
              .map(
                (c) => GestureDetector(
                  onTap: () {
                    onChanged(c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
