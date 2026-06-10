import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 统计栏 — 显示耗时和 token 数。
class StatsBar extends StatelessWidget {
  final Duration? elapsed;
  final int totalTokens;

  const StatsBar({
    super.key,
    this.elapsed,
    this.totalTokens = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final visible = elapsed != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: visible ? theme.spacingXl : 0,
      padding: visible
          ? EdgeInsets.symmetric(horizontal: theme.spacingXl)
          : EdgeInsets.zero,
      child: visible
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _StatItem(
                  icon: Icons.access_time,
                  label: '${(elapsed!.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  color: theme.statColor,
                ),
                SizedBox(width: theme.spacingMd),
                _StatItem(
                  icon: Icons.timeline,
                  label: _formatNumber(totalTokens),
                  color: theme.statColor,
                ),
              ],
            )
          : null,
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    }
    return n.toString();
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
