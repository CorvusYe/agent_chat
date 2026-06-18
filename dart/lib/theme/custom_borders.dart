import 'package:flutter/material.dart';

/// 强调下划线 — 1px 底色 + 焦点时从中心展开的彩色线。
class AccentUnderlineBorder extends InputBorder {
  final double animationValue;
  final Color accentColor;

  const AccentUnderlineBorder({
    required this.animationValue,
    required this.accentColor,
    super.borderSide = const BorderSide(color: Color(0xFF484848), width: 1),
  });

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: borderSide.width);

  @override
  AccentUnderlineBorder copyWith({BorderSide? borderSide}) =>
      AccentUnderlineBorder(
        animationValue: animationValue,
        accentColor: accentColor,
        borderSide: borderSide ?? this.borderSide,
      );

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final y = rect.bottom - 0.5;
    // 1px base line — always visible
    canvas.drawLine(
      Offset(rect.left, y),
      Offset(rect.right, y),
      Paint()
        ..color = borderSide.color
        ..strokeWidth = 1.0,
    );

    // 2px accent line — expands from center on focus
    if (animationValue > 0.001) {
      final t = animationValue;
      final spread = 0.5 * t;
      final r = Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2);
      canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              accentColor,
              accentColor,
              Colors.transparent,
            ],
            stops: [0, 0.5 - spread, 0.5 + spread, 1],
          ).createShader(r),
      );
    }
  }

  @override
  ShapeBorder scale(double t) => AccentUnderlineBorder(
    animationValue: animationValue,
    accentColor: accentColor,
    borderSide: borderSide.scale(t),
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);
}
