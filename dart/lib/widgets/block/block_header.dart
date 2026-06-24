import 'package:flutter/material.dart';
import '../../theme/chat_theme.dart';

/// 时间轴 block 头部。
///
/// 布局：Row(gutter + dot) + Expanded(header)
class BlockHeader extends StatelessWidget {
  final Widget dot;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool expanded;
  final String? subtitle;
  final DateTime? startTime;
  final Duration? elapsed;

  const BlockHeader({
    super.key,
    required this.dot,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.showChevron = true,
    this.expanded = false,
    this.subtitle,
    this.startTime,
    this.elapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: theme.timelineGutter,
          child: Center(child: dot),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: buildBlockHeader(
              context: context,
              icon: icon,
              label: label,
              color: color,
              theme: theme,
              showChevron: showChevron,
              expanded: expanded,
              subtitle: subtitle,
              startTime: startTime,
              elapsed: elapsed,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared block header row — used both in timeline and pinned header.
/// [subtitle] shows when collapsed with smooth size animation.
Widget buildBlockHeader({
  required BuildContext context,
  required IconData icon,
  required String label,
  required Color color,
  required ChatTheme theme,
  bool showChevron = false,
  bool expanded = false,
  String? subtitle,
  DateTime? startTime,
  Duration? elapsed,
}) {
  String? elapsedText;
  if (elapsed != null) {
    elapsedText = '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)}s';
  } else if (startTime != null) {
    elapsedText =
        '${(DateTime.now().difference(startTime).inMilliseconds / 1000).toStringAsFixed(1)}s';
  }

  return Container(
    color: theme.bgPrimary,
    child: Padding(
      padding: theme.blockHeaderPadding,
      child: Row(
        children: [
          Icon(icon, size: theme.iconSizeSm, color: color),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: theme.fontSizeSm,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 0.24,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (elapsedText != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                elapsedText,
                style: TextStyle(
                  fontSize: theme.fontSizeSm - 1,
                  color: theme.textTertiary,
                ),
              ),
            ),
          if (subtitle != null)
            Flexible(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.centerLeft,
                curve: Curves.easeInOut,
                child: expanded
                    ? const SizedBox(width: 0)
                    : Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: theme.fontSizeSm - 1,
                            color: theme.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          if (showChevron)
            AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: theme.iconSizeSm,
                color: theme.chevronColor,
              ),
            ),
        ],
      ),
    ),
  );
}
