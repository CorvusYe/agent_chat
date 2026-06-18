import 'package:flutter/material.dart';
import 'chat_theme.dart';

/// Neumorphism（软 UI）工具集 — 凸起/凹陷装饰构建器。
///
/// 基于 [ChatTheme.shadowLight] / [shadowDark] 生成双阴影效果。
///
/// 使用示例：
/// ```dart
/// final neu = NeuTheme.of(context);
/// Container(
///   decoration: neu.extrude(borderRadius: 12),
///   child: ...
/// )
/// ```
class NeuTheme {
  final ChatTheme chat;

  const NeuTheme(this.chat);

  /// 从当前 BuildContext 提取 NeuTheme 实例。
  static NeuTheme of(BuildContext context) => NeuTheme(ChatTheme.of(context));

  /// ── 凸起（raised / extruded） ──
  ///
  /// 左上亮影 + 右下暗影，让元素看起来从背景中鼓起。
  BoxDecoration extrude({
    double borderRadius = 12,
    double blurRadius = 10,
    Offset lightOffset = const Offset(-4, -4),
    Offset darkOffset = const Offset(4, 4),
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? chat.bgSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: chat.shadowLight,
          offset: lightOffset,
          blurRadius: blurRadius,
          blurStyle: BlurStyle.normal,
        ),
        BoxShadow(
          color: chat.shadowDark,
          offset: darkOffset,
          blurRadius: blurRadius,
          blurStyle: BlurStyle.normal,
        ),
      ],
    );
  }

  /// ── 凹陷（inset / pressed） ──
  ///
  /// 通过内外阴影反转 + 背景渐变模拟内陷效果。
  BoxDecoration inset({
    double borderRadius = 12,
    double blurRadius = 8,
    Offset lightOffset = const Offset(-3, -3),
    Offset darkOffset = const Offset(3, 3),
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? chat.bgSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // 暗影移到左上（模拟内陷的顶部遮挡）
        BoxShadow(
          color: chat.shadowDark,
          offset: -lightOffset,
          blurRadius: blurRadius * 0.6,
          blurStyle: BlurStyle.normal,
        ),
        // 亮影移到右下（模拟内陷的底部反光）
        BoxShadow(
          color: chat.shadowLight,
          offset: -darkOffset,
          blurRadius: blurRadius * 0.6,
          blurStyle: BlurStyle.normal,
        ),
      ],
    );
  }

  /// ── 扁平（flat） ──
  ///
  ///  仅少量阴影，适合不需要明显立体感的次级容器。
  BoxDecoration flat({double borderRadius = 12, Color? color}) {
    return BoxDecoration(
      color: color ?? chat.bgSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: chat.shadowLight.withValues(alpha: 0.3),
          offset: const Offset(-2, -2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: chat.shadowDark.withValues(alpha: 0.3),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  /// ── 卡片式凸起（Card） ──
  ///
  /// 比 [extrude] 更柔和的阴影，适合大面积卡片。
  BoxDecoration card({
    double borderRadius = 16,
    Color? color,
    double intensity = 1.0,
  }) {
    final b = 14.0 * intensity;
    return BoxDecoration(
      color: color ?? chat.bgSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: chat.shadowLight,
          offset: Offset(-6 * intensity, -6 * intensity),
          blurRadius: b,
        ),
        BoxShadow(
          color: chat.shadowDark,
          offset: Offset(6 * intensity, 6 * intensity),
          blurRadius: b,
        ),
      ],
    );
  }
}

/// Neumorphism 装饰的便捷 widget。
///
/// 使用 [style] 指定效果类型，[child] 渲染子 widget。
///
/// ```dart
/// NeuBox(
///   style: NeuStyle.extrude,
///   borderRadius: 12,
///   child: Text('内容'),
/// )
/// ```
class NeuBox extends StatelessWidget {
  final NeuStyle style;
  final double borderRadius;
  final double blurRadius;
  final Color? color;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const NeuBox({
    super.key,
    this.style = NeuStyle.extrude,
    this.borderRadius = 12,
    this.blurRadius = 10,
    this.color,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final neu = NeuTheme.of(context);
    BoxDecoration decoration;
    switch (style) {
      case NeuStyle.extrude:
        decoration = neu.extrude(
          borderRadius: borderRadius,
          blurRadius: blurRadius,
          color: color,
        );
      case NeuStyle.inset:
        decoration = neu.inset(
          borderRadius: borderRadius,
          blurRadius: blurRadius,
          color: color,
        );
      case NeuStyle.flat:
        decoration = neu.flat(borderRadius: borderRadius, color: color);
      case NeuStyle.card:
        decoration = neu.card(borderRadius: borderRadius, color: color);
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

/// Neumorphism 样式枚举。
enum NeuStyle {
  /// 凸起 — 双阴影挤出效果。
  extrude,

  /// 凹陷 — 模拟按压/聚焦状态。
  inset,

  /// 扁平 — 微弱阴影，无立体感。
  flat,

  /// 卡片 — 大面积柔和双阴影。
  card,
}
