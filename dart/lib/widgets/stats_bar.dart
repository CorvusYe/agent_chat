import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../l10n/chat_l10n.dart';

/// 统计栏 — 显示 token 数。
class StatsBar extends StatefulWidget {
  final int totalTokens;

  const StatsBar({super.key, this.totalTokens = 0});

  @override
  State<StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<StatsBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _to = widget.totalTokens;
  }

  @override
  void didUpdateWidget(StatsBar old) {
    super.didUpdateWidget(old);
    if (old.totalTokens != widget.totalTokens) {
      _from = _displayed;
      _to = widget.totalTokens;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _displayed {
    if (_ctrl.isAnimating || _ctrl.value > 0) {
      return _from + ((_to - _from) * _ctrl.value).round();
    }
    return _to;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final l10n = ChatL10n.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _StatItem(
          icon: Icons.timeline,
          label: l10n.statsTokens(_displayed),
          color: theme.statColor,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: theme.fontSizeSm, color: color),
        SizedBox(width: theme.spacingXs),
        Text(
          label,
          style: TextStyle(
            fontSize: theme.fontSizeSm - 1,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
