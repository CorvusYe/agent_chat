// 自定义主题 Demo — macOS Neumorphism 风格 ChatTheme
//
// 展示基于 Neumorphism（软 UI / 新拟态）设计规范的 macOS 风格主题，
// 包含亮色/暗色两套完整配色 + NeuBox / NeuTheme 装饰示例。
//
// Neumorphism 设计规范要点：
//   1. 单色系 — 元素与背景颜色一致，仅靠双阴影区分层次
//   2. 双阴影 — 左上亮影 + 右下暗影，产生"挤出"立体感
//   3. 大圆角 — 比传统风格更圆润
//   4. 无硬边框 — 用阴影替代描边
//   5. 柔和背景 — 暖灰/冷灰色调，避免纯白/纯黑
//   6. 凹陷交互 — 激活/聚焦时阴影反转（inset 效果）

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

// ═══════════════════════════════════════════════════════════
//  macOS Neumorphism 亮色主题
// ═══════════════════════════════════════════════════════════

ChatTheme neumorphicMacOSLight() => ChatTheme(
  // ── 背景（Neumorphic：所有背景色高度统一） ──
  bgPrimary: const Color(0xFFECF0F4), // 冷灰主背景（经典 Neumorphic 底色）
  bgSurface: const Color(0xFFECF0F4), // = bgPrimary
  bgPopup: const Color(0xFFECF0F4), // 弹窗同背景，用阴影分离
  bgInput: const Color(0xFFECF0F4), // 输入框同背景，用 inset 阴影
  bgCard: const Color(0xFFECF0F4), // 卡片同背景
  bgCardHeader: const Color(0xFFE8ECF1), // 极微弱区分
  bgCommand: const Color(0xFFE5E9EE),
  bgHover: const Color(0xFFE2E6EB),
  bgHoverStrong: const Color(0xFFD8DCE3),
  bgWarning: const Color(0xFFFDF3DC),

  // ── Neumorphism 双阴影颜色 ──
  shadowLight: const Color(0xCCFFFFFF), // 纯白高光（左上，80%）
  shadowDark: const Color(0x738B939C), // 灰影（右下，45%，层次更深）
  // ── 文字 ──
  textPrimary: const Color(0xFF1C1C1E),
  textInput: const Color(0xFF1C1C1E),
  textContent: const Color(0xFF1C1C1E),
  textSecondary: const Color(0xFF6E6E73),
  textTertiary: const Color(0xFF8E8E93),
  textToolResult: const Color(0xFF6E6E73),
  textToolHeader: const Color(0xFF007AFF),
  textPlaceholder: const Color(0xFFB8B8BE),

  // ── 强调色（macOS 标准） ──
  accent: const Color(0xFF007AFF),
  accentHover: const Color(0xFF0066D6),
  accentActive: const Color(0xFF0055BF),
  accentLight: const Color(0xFF409CFF),
  accentAlpha: const Color(0x1F007AFF),
  success: const Color(0xFF34C759),
  error: const Color(0xFFFF3B30),
  warning: const Color(0xFFFF9500),

  // ── 边框（Neumorphic: 极淡或透明，仅做后备） ──
  border: const Color(0x1A8B939C),
  borderLight: const Color(0x0D8B939C),
  borderStrong: const Color(0x268B939C),
  borderUser: const Color(0x1A8B939C),
  borderAccent: const Color(0x4D007AFF),
  borderWarning: const Color(0x33FF9500),

  // ── 状态点 ──
  dotThinking: const Color(0xFF8E8E93),
  dotTool: const Color(0xFF007AFF),
  dotContent: const Color(0xFF007AFF),
  dotConfirm: const Color(0xFFFF9500),
  headerThinking: const Color(0xFF8E8E93),
  headerTool: const Color(0xFF007AFF),
  headerContent: const Color(0xFF007AFF),
  headerConfirm: const Color(0xFFFF9500),

  // ── 装饰 ──
  chevronColor: const Color(0xFF8E8E93),
  statColor: const Color(0xFF8E8E93),
  spinnerColor: const Color(0xFF8E8E93),
  btnSecondaryBg: const Color(0x1A007AFF),
  resultBg: const Color(0x08000000),
  buttonBorderColor: const Color(0x268B939C),

  // ── 尺寸（Neumorphic: 大圆角 + 宽间距） ──
  timelineGutter: 24,
  timelineDotSize: 12,
  timelineLineWidth: 2,
  radiusSm: 6,
  radiusMd: 10,
  radiusLg: 14,
  radiusXl: 18,
  spacingWindow: 16,
  spacingLg: 20,
);

// ═══════════════════════════════════════════════════════════
//  macOS Neumorphism 暗色主题
// ═══════════════════════════════════════════════════════════

ChatTheme neumorphicMacOSDark() => ChatTheme(
  // ── 背景（Neumorphic：高度统一） ──
  bgPrimary: const Color(0xFF1C1C1E), // 深灰主背景
  bgSurface: const Color(0xFF1C1C1E), // = bgPrimary
  bgPopup: const Color(0xFF222224), // 弹窗微微提亮（仍很近）
  bgInput: const Color(0xFF1C1C1E), // 输入框同背景
  bgCard: const Color(0xFF1C1C1E), // 卡片同背景
  bgCardHeader: const Color(0xFF1F1F21),
  bgCommand: const Color(0xFF222224),
  bgHover: const Color(0xFF252527),
  bgHoverStrong: const Color(0xFF2C2C2E),
  bgWarning: const Color(0x1AFF9500),

  // ── Neumorphism 双阴影颜色（暗色：亮影 > 背景，暗影 < 背景） ──
  shadowLight: const Color(0x6638383A), // 亮灰（左上，40%，明显亮于背景）
  shadowDark: const Color(0x66000000), // 纯黑（右下，40%，深邃感）
  // ── 文字 ──
  textPrimary: const Color(0xFFF5F5F7),
  textInput: const Color(0xFFF5F5F7),
  textContent: const Color(0xFFF5F5F7),
  textSecondary: const Color(0xFF98989D),
  textTertiary: const Color(0xFF6E6E73),
  textToolResult: const Color(0xFF98989D),
  textToolHeader: const Color(0xFF64B5F6),
  textPlaceholder: const Color(0xFF48484A),

  // ── 强调色 ──
  accent: const Color(0xFF64B5F6),
  accentHover: const Color(0xFF4CA9F5),
  accentActive: const Color(0xFF339EF4),
  accentLight: const Color(0xFF82C5F8),
  accentAlpha: const Color(0x2F64B5F6),
  success: const Color(0xFF30D158),
  error: const Color(0xFFFF453A),
  warning: const Color(0xFFFF9F0A),

  // ── 边框（极淡） ──
  border: const Color(0x1AFFFFFF),
  borderLight: const Color(0x0DFFFFFF),
  borderStrong: const Color(0x26FFFFFF),
  borderUser: const Color(0x1AFFFFFF),
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
  btnSecondaryBg: const Color(0x2A64B5F6),
  resultBg: const Color(0x1A000000),
  buttonBorderColor: const Color(0x33FFFFFF),

  // ── 尺寸 ──
  timelineGutter: 24,
  timelineDotSize: 12,
  timelineLineWidth: 2,
  radiusSm: 6,
  radiusMd: 10,
  radiusLg: 14,
  radiusXl: 18,
  spacingWindow: 16,
  spacingLg: 20,
);

// ═══════════════════════════════════════════════════════════
//  Demo — 展示 macOS Neumorphism 效果
// ═══════════════════════════════════════════════════════════

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
    bus.sendMessage('macOS Neumorphism 主题预览');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    bus.sendMessage('检查系统状态');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    bus.sendMessage('清理临时文件');
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    bus.sendMessage('分析项目');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    bus.sendMessage('报告错误');
  }

  Stream<ExchangeEvent> _mockReply(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    if (text == 'macOS Neumorphism 主题预览') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(
        id,
        'think',
        '正在应用 macOS Neumorphism 主题…\n'
            '亮色：暖灰 #E8ECF0 + 双阴影 + #007AFF 强调\n'
            '暗色：深灰 #1C1C1E + 双阴影 + #64B5F6 强调',
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '主题已应用');
      yield ContentStarted(id, 'content');
      const reply =
          '当前使用的是完整 macOS Neumorphism 风格 ChatTheme，\n'
          '遵循软 UI 设计规范：单色系、双阴影挤出、大圆角、无硬边框。\n'
          '所有 UI 元素与背景同色，仅通过左上亮影 + 右下暗影产生层次感。';
      yield ContentDelta(id, 'content', reply);
      yield ContentCompleted(id, 'content', reply);
      yield TokenCount(id, 42);
      return;
    }

    if (text == '检查系统状态') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '正在检查各项系统状态…');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '开始检查');

      yield ToolCallStarted(id, 'cpu', 'system.cpu', {
        'target': 'usage',
      }, autoApproved: true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'cpu', 'CPU 使用率: 23% | 温度: 52°C');

      yield ToolCallStarted(id, 'mem', 'system.memory', {
        'target': 'usage',
      }, autoApproved: true);
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'mem', '内存使用: 8.2GB / 16GB (51%)');

      yield ParallelBoundary(id);
      yield ContentStarted(id, 'content');
      const reply = '系统状态良好，各项指标均在正常范围。';
      yield ContentDelta(id, 'content', reply);
      yield ContentCompleted(id, 'content', reply);
      yield TokenCount(id, 24);
      return;
    }

    if (text == '清理临时文件') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '需要确认清理操作…');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '需要用户确认');

      yield ToolCallStarted(
        id,
        'clean',
        'file.cleanup',
        {'target': '/tmp/cache', 'size': '245MB'},
        requiresConfirm: true,
        description: '将要删除 /tmp/cache 目录中的临时文件',
        canAlwaysAllow: true,
      );
      yield ParallelBoundary(id);

      await Future.delayed(const Duration(milliseconds: 600));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'clean', '✓ 已清理 245MB 临时文件');

      yield ContentStarted(id, 'content');
      const reply = '清理完成，释放了 245MB 磁盘空间。';
      yield ContentDelta(id, 'content', reply);
      yield ContentCompleted(id, 'content', reply);
      yield TokenCount(id, 16);
      return;
    }

    if (text == '分析项目') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '并行分析中…');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '启动并行分析');

      yield ToolCallStarted(id, 'lint', 'project.lint', {
        'target': 'src/',
      }, autoApproved: true);
      yield ToolCallStarted(id, 'test', 'project.test', {
        'target': 'tests/',
      }, autoApproved: true);
      yield ToolCallStarted(id, 'dep', 'project.deps', {
        'target': 'pubspec.yaml',
      }, autoApproved: true);
      yield ParallelBoundary(id);

      await Future.delayed(const Duration(milliseconds: 300));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'lint', '✓ 0 errors, 3 warnings');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'test', '✓ 42/42 tests passed');
      await Future.delayed(const Duration(milliseconds: 200));
      if (_cancelled) return;
      yield ToolCallCompleted(id, 'dep', '✓ 所有依赖无已知漏洞');

      yield ContentStarted(id, 'content');
      const reply = '项目分析完成：代码检查通过，测试全部通过，依赖安全。';
      yield ContentDelta(id, 'content', reply);
      yield ContentCompleted(id, 'content', reply);
      yield TokenCount(id, 32);
      return;
    }

    if (text == '报告错误') {
      yield ThinkingStarted(id, 'think');
      yield ThinkingDelta(id, 'think', '正在连接远程服务…');
      await Future.delayed(const Duration(milliseconds: 400));
      if (_cancelled) return;
      yield ThinkingCompleted(id, 'think', '连接超时');
      yield ExchangeError(
        id,
        '请求超时: 服务器无响应 (30s)\n\n'
        '可能的原因：\n'
        '  • 网络连接不稳定\n'
        '  • 服务器负载过高\n\n'
        '建议稍后重试。',
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = _dark ? neumorphicMacOSDark() : neumorphicMacOSLight();
    final neu = NeuTheme(chatTheme);

    return Column(
      children: [
        // ── 控制面板（Neumorphic 凸起效果） ──
        NeuBox(
          style: NeuStyle.flat,
          borderRadius: 0,
          color: chatTheme.bgSurface,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: chatTheme.accent),
                const SizedBox(width: 8),
                const Text(
                  'macOS Neumorphism',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 12),
                _NeuToggle(
                  value: _dark,
                  onChanged: (v) => setState(() => _dark = v),
                  neu: neu,
                ),
                const Spacer(),
                // Neumorphic 图标按钮（微凸起）
                _NeuIconButton(
                  icon: Icons.info_outline,
                  tooltip: 'Neumorphism: 双阴影挤出 + 单色系',
                  neu: neu,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Colors.transparent),
        // ── ChatScreen 预览 ──
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

// ═══════════════════════════════════════════════════════════
//  Neumorphic Toggle Switch
// ═══════════════════════════════════════════════════════════

class _NeuToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final NeuTheme neu;

  const _NeuToggle({
    required this.value,
    required this.onChanged,
    required this.neu,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: NeuBox(
        style: value ? NeuStyle.inset : NeuStyle.extrude,
        borderRadius: 14,
        blurRadius: 6,
        color: neu.chat.bgSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.light_mode_outlined,
              size: 13,
              color: value ? neu.chat.textTertiary : neu.chat.accent,
            ),
            const SizedBox(width: 6),
            Text(
              value ? '暗色' : '亮色',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value ? neu.chat.textSecondary : neu.chat.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.dark_mode_outlined,
              size: 13,
              color: value ? neu.chat.accent : neu.chat.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Neumorphic Icon Button
// ═══════════════════════════════════════════════════════════

class _NeuIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final NeuTheme neu;

  const _NeuIconButton({
    required this.icon,
    required this.tooltip,
    required this.neu,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: NeuBox(
        style: NeuStyle.extrude,
        borderRadius: 8,
        blurRadius: 4,
        color: neu.chat.bgSurface,
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: neu.chat.textSecondary),
      ),
    );
  }
}
