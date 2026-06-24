import 'package:flutter/material.dart';
import '../../theme/chat_theme.dart';

/// 时间轴 block 内容区。
///
/// 布局：Stack(竖线居中于 gutter + content)
/// 用 Stack 而非 Row：竖线通过 Positioned(top:0, bottom:0) 拉伸到与内容等高。
class BlockContent extends StatelessWidget {
  final Color lineColor;
  final Widget child;

  const BlockContent({super.key, required this.lineColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return Padding(
      padding: theme.blockPadding,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(
              width: theme.timelineGutter,
              child: Center(
                child: Container(
                  width: theme.timelineLineWidth,
                  color: lineColor,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: theme.timelineGutter),
            child: child,
          ),
        ],
      ),
    );
  }
}
