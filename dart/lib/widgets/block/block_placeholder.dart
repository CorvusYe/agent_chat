import 'package:flutter/material.dart';
import '../../theme/chat_theme.dart';
import '../../l10n/chat_l10n.dart';
import 'block_header.dart';
import 'block_anim.dart';

/// "正在思考"占位 widget — 旋转环圆点 + 心跳脉冲文字，样式同 block 标题。
///
/// 在 exchange 正在处理但无 active block 时显示。
class ThinkingPlaceholder extends StatefulWidget {
  const ThinkingPlaceholder({super.key});

  @override
  State<ThinkingPlaceholder> createState() => _ThinkingPlaceholderState();
}

class _ThinkingPlaceholderState extends State<ThinkingPlaceholder>
    with TickerProviderStateMixin {
  AnimationController? _breathingCtrl;
  AnimationController? _rotationCtrl;
  bool _depsReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_depsReady) return;
    _depsReady = true;
    final theme = ChatTheme.of(context);
    _breathingCtrl =
        AnimationController(
            vsync: this,
            duration: theme.placeholderBreathingDuration,
          )
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat(reverse: true);

    _rotationCtrl =
        AnimationController(vsync: this, duration: theme.rotationDuration)
          ..addListener(() {
            if (mounted) setState(() {});
          })
          ..repeat();
  }

  @override
  void dispose() {
    _breathingCtrl?.dispose();
    _rotationCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final pulseOpacity = 0.5 + 0.5 * (_breathingCtrl?.value ?? 0.0);
    final dotColor = theme.dotThinking.withValues(alpha: pulseOpacity);
    final headerColor = theme.headerThinking.withValues(alpha: pulseOpacity);

    return BlockHeader(
      dot: SizedBox(
        width: theme.timelineDotSize,
        height: theme.timelineDotSize,
        child: CustomPaint(
          painter: RunningDotPainter(
            color: dotColor,
            rotation: _rotationCtrl?.value ?? 0.0,
          ),
        ),
      ),
      icon: Icons.psychology_outlined,
      label: ChatL10n.of(context).thinkingPlaceholder,
      color: headerColor,
      showChevron: false,
      onTap: null,
    );
  }
}
