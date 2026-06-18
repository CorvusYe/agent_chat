import 'dart:ui';
import 'package:flutter/material.dart';

/// ChatTheme — 聊天 UI 专用主题，含颜色 + 排版 + 间距 + 圆角。
///
/// 通过 `ThemeExtension` 接入 Flutter 主题系统。
@immutable
class ChatTheme extends ThemeExtension<ChatTheme> {
  // ═══════════════════════════════════════
  //  颜色 — 背景
  // ═══════════════════════════════════════
  final Color bgPrimary;
  final Color bgSurface;
  final Color bgPopup;
  final Color bgInput;
  final Color bgCard;
  final Color bgCardHeader;
  final Color bgCommand;
  final Color bgHover;
  final Color bgHoverStrong;
  final Color bgWarning;

  // ═══════════════════════════════════════
  //  颜色 — 文字
  // ═══════════════════════════════════════
  final Color textPrimary;
  final Color textInput;
  final Color textContent;
  final Color textSecondary;
  final Color textTertiary;
  final Color textToolResult;
  final Color textToolHeader;
  final Color textPlaceholder;

  // ═══════════════════════════════════════
  //  颜色 — 强调 & 状态
  // ═══════════════════════════════════════
  final Color accent;
  final Color accentHover;
  final Color accentActive;
  final Color accentLight;
  final Color accentAlpha;
  final Color success;
  final Color error;
  final Color warning;

  // ═══════════════════════════════════════
  //  颜色 — 边框
  // ═══════════════════════════════════════
  final Color border;
  final Color borderLight;
  final Color borderStrong;
  final Color borderUser;
  final Color borderAccent;
  final Color borderWarning;

  // ═══════════════════════════════════════
  //  颜色 — 消息类型标识
  // ═══════════════════════════════════════
  final Color dotThinking;
  final Color dotTool;
  final Color dotContent;
  final Color dotConfirm;
  final Color headerThinking;
  final Color headerTool;
  final Color headerContent;
  final Color headerConfirm;

  // ═══════════════════════════════════════
  //  颜色 — 装饰 & 按钮
  // ═══════════════════════════════════════
  final Color chevronColor;
  final Color statColor;
  final Color spinnerColor;
  final Color btnSecondaryBg;
  final Color resultBg;
  final Color buttonBorderColor;

  // ═══════════════════════════════════════
  //  排版
  // ═══════════════════════════════════════
  final double fontSizeSm;
  final double fontSizeMd;
  final double fontSizeLg;
  final double fontSizeXl;

  // ═══════════════════════════════════════
  //  间距
  // ═══════════════════════════════════════
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacingWindow;
  final EdgeInsets blockPadding;
  final EdgeInsets blockHeaderPadding;
  final EdgeInsets confirmPadding;
  final EdgeInsets codeBlockPadding;
  final EdgeInsets buttonPadding;

  // ═══════════════════════════════════════
  //  圆角
  // ═══════════════════════════════════════
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;

  // ═══════════════════════════════════════
  //  尺寸
  // ═══════════════════════════════════════
  final double iconSizeSm;
  final double iconSizeMd;
  final double buttonHeight;
  final double smallButtonHeight;
  final double inputMinHeight;
  final double contentMaxHeight;

  // ═══════════════════════════════════════
  //  动画周期
  // ═══════════════════════════════════════
  final Duration breathingDuration;
  final Duration rotationDuration;
  final Duration placeholderBreathingDuration;

  const ChatTheme({
    // 颜色
    required this.bgPrimary,
    required this.bgSurface,
    required this.bgPopup,
    required this.bgInput,
    required this.bgCard,
    required this.bgCardHeader,
    required this.bgCommand,
    required this.bgHover,
    required this.bgHoverStrong,
    required this.bgWarning,
    required this.textPrimary,
    required this.textInput,
    required this.textContent,
    required this.textSecondary,
    required this.textTertiary,
    required this.textToolResult,
    required this.textToolHeader,
    required this.textPlaceholder,
    required this.accent,
    required this.accentHover,
    required this.accentActive,
    required this.accentLight,
    required this.accentAlpha,
    required this.success,
    required this.error,
    required this.warning,
    required this.border,
    required this.borderLight,
    required this.borderStrong,
    required this.borderUser,
    required this.borderAccent,
    required this.borderWarning,
    required this.dotThinking,
    required this.dotTool,
    required this.dotContent,
    required this.dotConfirm,
    required this.headerThinking,
    required this.headerTool,
    required this.headerContent,
    required this.headerConfirm,
    required this.chevronColor,
    required this.statColor,
    required this.spinnerColor,
    required this.btnSecondaryBg,
    required this.resultBg,
    required this.buttonBorderColor,
    // 排版（可选的默认值）
    this.fontSizeSm = 12,
    this.fontSizeMd = 13,
    this.fontSizeLg = 14,
    this.fontSizeXl = 16,
    // 间距
    this.spacingXs = 4,
    this.spacingSm = 8,
    this.spacingMd = 12,
    this.spacingLg = 16,
    this.spacingXl = 24,
    this.spacingWindow = 12,
    this.blockPadding = const EdgeInsets.fromLTRB(0, 4, 0, 4),
    this.blockHeaderPadding = const EdgeInsets.fromLTRB(10, 6, 0, 4),
    this.confirmPadding = const EdgeInsets.fromLTRB(10, 8, 10, 8),
    this.codeBlockPadding = const EdgeInsets.all(8),
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 12),
    // 圆角
    this.radiusSm = 2,
    this.radiusMd = 3,
    this.radiusLg = 4,
    this.radiusXl = 6,
    // 尺寸
    this.iconSizeSm = 14,
    this.iconSizeMd = 18,
    this.buttonHeight = 32,
    this.smallButtonHeight = 24,
    this.inputMinHeight = 36,
    this.contentMaxHeight = 2000,
    // 动画
    this.breathingDuration = const Duration(milliseconds: 600),
    this.rotationDuration = const Duration(milliseconds: 1000),
    this.placeholderBreathingDuration = const Duration(milliseconds: 400),
  });

  static ChatTheme of(BuildContext context) {
    return Theme.of(context).extension<ChatTheme>() ?? _fallback;
  }

  static const _fallback = ChatTheme(
    bgPrimary: Color(0xFF1a1a2e),
    bgSurface: Color(0xFF2d3a5e),
    bgPopup: Color(0xFF1e1e38),
    bgInput: Color(0x0AFFFFFF),
    bgCard: Color(0x05FFFFFF),
    bgCardHeader: Color(0x0AFFFFFF),
    bgCommand: Color(0x33000000),
    bgHover: Color(0x0FFFFFFF),
    bgHoverStrong: Color(0x1FFFFFFF),
    bgWarning: Color(0x0AFBC324),
    textPrimary: Color(0xFFe0e0e0),
    textInput: Color(0xFFe8e8e8),
    textContent: Color(0xFFe2e8f0),
    textSecondary: Color(0xFF94a3b8),
    textTertiary: Color(0xFF64748b),
    textToolResult: Color(0xFFa0aec0),
    textToolHeader: Color(0xFFc4b5fd),
    textPlaceholder: Color(0x59FFFFFF),
    accent: Color(0xFF3b82f6),
    accentHover: Color(0xFF2563eb),
    accentActive: Color(0xFF1d4ed8),
    accentLight: Color(0xFF60a5fa),
    accentAlpha: Color(0x4060a5fa),
    success: Color(0xFF4ade80),
    error: Color(0xFFf87171),
    warning: Color(0xFFfbbf24),
    border: Color(0x1FFFFFFF),
    borderLight: Color(0x14FFFFFF),
    borderStrong: Color(0x26FFFFFF),
    borderUser: Color(0x40FFFFFF),
    borderAccent: Color(0x4D60a5fa),
    borderWarning: Color(0x40FBC324),
    dotThinking: Color(0xFF64748b),
    dotTool: Color(0xFFa78bfa),
    dotContent: Color(0xFF60a5fa),
    dotConfirm: Color(0xFFf59e0b),
    headerThinking: Color(0xFF64748b),
    headerTool: Color(0xFFa78bfa),
    headerContent: Color(0xFF60a5fa),
    headerConfirm: Color(0xFFf59e0b),
    chevronColor: Color(0x59FFFFFF),
    statColor: Color(0x4DFFFFFF),
    spinnerColor: Color(0x4DFFFFFF),
    btnSecondaryBg: Color(0x00000000),
    resultBg: Color(0x0A000000),
    buttonBorderColor: Color(0x26FFFFFF),
    contentMaxHeight: 2000,
  );

  @override
  ChatTheme copyWith({
    Color? bgPrimary,
    Color? bgSurface,
    Color? bgPopup,
    Color? bgInput,
    Color? bgCard,
    Color? bgCardHeader,
    Color? bgCommand,
    Color? bgHover,
    Color? bgHoverStrong,
    Color? bgWarning,
    Color? textPrimary,
    Color? textInput,
    Color? textContent,
    Color? textSecondary,
    Color? textTertiary,
    Color? textToolResult,
    Color? textToolHeader,
    Color? textPlaceholder,
    Color? accent,
    Color? accentHover,
    Color? accentActive,
    Color? accentLight,
    Color? accentAlpha,
    Color? success,
    Color? error,
    Color? warning,
    Color? border,
    Color? borderLight,
    Color? borderStrong,
    Color? borderUser,
    Color? borderAccent,
    Color? borderWarning,
    Color? dotThinking,
    Color? dotTool,
    Color? dotContent,
    Color? dotConfirm,
    Color? headerThinking,
    Color? headerTool,
    Color? headerContent,
    Color? headerConfirm,
    Color? chevronColor,
    Color? statColor,
    Color? spinnerColor,
    Color? btnSecondaryBg,
    Color? resultBg,
    Color? buttonBorderColor,
    double? fontSizeSm,
    double? fontSizeMd,
    double? fontSizeLg,
    double? fontSizeXl,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacingWindow,
    EdgeInsets? blockPadding,
    EdgeInsets? blockHeaderPadding,
    EdgeInsets? confirmPadding,
    EdgeInsets? codeBlockPadding,
    EdgeInsets? buttonPadding,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? iconSizeSm,
    double? iconSizeMd,
    double? buttonHeight,
    double? smallButtonHeight,
    double? inputMinHeight,
    double? contentMaxHeight,
    Duration? breathingDuration,
    Duration? rotationDuration,
    Duration? placeholderBreathingDuration,
  }) {
    return ChatTheme(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSurface: bgSurface ?? this.bgSurface,
      bgPopup: bgPopup ?? this.bgPopup,
      bgInput: bgInput ?? this.bgInput,
      bgCard: bgCard ?? this.bgCard,
      bgCardHeader: bgCardHeader ?? this.bgCardHeader,
      bgCommand: bgCommand ?? this.bgCommand,
      bgHover: bgHover ?? this.bgHover,
      bgHoverStrong: bgHoverStrong ?? this.bgHoverStrong,
      bgWarning: bgWarning ?? this.bgWarning,
      textPrimary: textPrimary ?? this.textPrimary,
      textInput: textInput ?? this.textInput,
      textContent: textContent ?? this.textContent,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textToolResult: textToolResult ?? this.textToolResult,
      textToolHeader: textToolHeader ?? this.textToolHeader,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentActive: accentActive ?? this.accentActive,
      accentLight: accentLight ?? this.accentLight,
      accentAlpha: accentAlpha ?? this.accentAlpha,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      borderStrong: borderStrong ?? this.borderStrong,
      borderUser: borderUser ?? this.borderUser,
      borderAccent: borderAccent ?? this.borderAccent,
      borderWarning: borderWarning ?? this.borderWarning,
      dotThinking: dotThinking ?? this.dotThinking,
      dotTool: dotTool ?? this.dotTool,
      dotContent: dotContent ?? this.dotContent,
      dotConfirm: dotConfirm ?? this.dotConfirm,
      headerThinking: headerThinking ?? this.headerThinking,
      headerTool: headerTool ?? this.headerTool,
      headerContent: headerContent ?? this.headerContent,
      headerConfirm: headerConfirm ?? this.headerConfirm,
      chevronColor: chevronColor ?? this.chevronColor,
      statColor: statColor ?? this.statColor,
      spinnerColor: spinnerColor ?? this.spinnerColor,
      btnSecondaryBg: btnSecondaryBg ?? this.btnSecondaryBg,
      resultBg: resultBg ?? this.resultBg,
      buttonBorderColor: buttonBorderColor ?? this.buttonBorderColor,
      fontSizeSm: fontSizeSm ?? this.fontSizeSm,
      fontSizeMd: fontSizeMd ?? this.fontSizeMd,
      fontSizeLg: fontSizeLg ?? this.fontSizeLg,
      fontSizeXl: fontSizeXl ?? this.fontSizeXl,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacingWindow: spacingWindow ?? this.spacingWindow,
      blockPadding: blockPadding ?? this.blockPadding,
      blockHeaderPadding: blockHeaderPadding ?? this.blockHeaderPadding,
      confirmPadding: confirmPadding ?? this.confirmPadding,
      codeBlockPadding: codeBlockPadding ?? this.codeBlockPadding,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      iconSizeSm: iconSizeSm ?? this.iconSizeSm,
      iconSizeMd: iconSizeMd ?? this.iconSizeMd,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      smallButtonHeight: smallButtonHeight ?? this.smallButtonHeight,
      inputMinHeight: inputMinHeight ?? this.inputMinHeight,
      contentMaxHeight: contentMaxHeight ?? this.contentMaxHeight,
      breathingDuration: breathingDuration ?? this.breathingDuration,
      rotationDuration: rotationDuration ?? this.rotationDuration,
      placeholderBreathingDuration:
          placeholderBreathingDuration ?? this.placeholderBreathingDuration,
    );
  }

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) return this;
    return ChatTheme(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgPopup: Color.lerp(bgPopup, other.bgPopup, t)!,
      bgInput: Color.lerp(bgInput, other.bgInput, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardHeader: Color.lerp(bgCardHeader, other.bgCardHeader, t)!,
      bgCommand: Color.lerp(bgCommand, other.bgCommand, t)!,
      bgHover: Color.lerp(bgHover, other.bgHover, t)!,
      bgHoverStrong: Color.lerp(bgHoverStrong, other.bgHoverStrong, t)!,
      bgWarning: Color.lerp(bgWarning, other.bgWarning, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textInput: Color.lerp(textInput, other.textInput, t)!,
      textContent: Color.lerp(textContent, other.textContent, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textToolResult: Color.lerp(textToolResult, other.textToolResult, t)!,
      textToolHeader: Color.lerp(textToolHeader, other.textToolHeader, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentActive: Color.lerp(accentActive, other.accentActive, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentAlpha: Color.lerp(accentAlpha, other.accentAlpha, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderUser: Color.lerp(borderUser, other.borderUser, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
      borderWarning: Color.lerp(borderWarning, other.borderWarning, t)!,
      dotThinking: Color.lerp(dotThinking, other.dotThinking, t)!,
      dotTool: Color.lerp(dotTool, other.dotTool, t)!,
      dotContent: Color.lerp(dotContent, other.dotContent, t)!,
      dotConfirm: Color.lerp(dotConfirm, other.dotConfirm, t)!,
      headerThinking: Color.lerp(headerThinking, other.headerThinking, t)!,
      headerTool: Color.lerp(headerTool, other.headerTool, t)!,
      headerContent: Color.lerp(headerContent, other.headerContent, t)!,
      headerConfirm: Color.lerp(headerConfirm, other.headerConfirm, t)!,
      chevronColor: Color.lerp(chevronColor, other.chevronColor, t)!,
      statColor: Color.lerp(statColor, other.statColor, t)!,
      spinnerColor: Color.lerp(spinnerColor, other.spinnerColor, t)!,
      btnSecondaryBg: Color.lerp(btnSecondaryBg, other.btnSecondaryBg, t)!,
      resultBg: Color.lerp(resultBg, other.resultBg, t)!,
      buttonBorderColor: Color.lerp(
        buttonBorderColor,
        other.buttonBorderColor,
        t,
      )!,
      fontSizeSm: lerpDouble(fontSizeSm, other.fontSizeSm, t) ?? fontSizeSm,
      fontSizeMd: lerpDouble(fontSizeMd, other.fontSizeMd, t) ?? fontSizeMd,
      fontSizeLg: lerpDouble(fontSizeLg, other.fontSizeLg, t) ?? fontSizeLg,
      fontSizeXl: lerpDouble(fontSizeXl, other.fontSizeXl, t) ?? fontSizeXl,
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t) ?? spacingXs,
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t) ?? spacingSm,
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t) ?? spacingMd,
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t) ?? spacingLg,
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t) ?? spacingXl,
      spacingWindow:
          lerpDouble(spacingWindow, other.spacingWindow, t) ?? spacingWindow,
      blockPadding:
          EdgeInsets.lerp(blockPadding, other.blockPadding, t) ?? blockPadding,
      blockHeaderPadding:
          EdgeInsets.lerp(blockHeaderPadding, other.blockHeaderPadding, t) ??
          blockHeaderPadding,
      confirmPadding:
          EdgeInsets.lerp(confirmPadding, other.confirmPadding, t) ??
          confirmPadding,
      codeBlockPadding:
          EdgeInsets.lerp(codeBlockPadding, other.codeBlockPadding, t) ??
          codeBlockPadding,
      buttonPadding:
          EdgeInsets.lerp(buttonPadding, other.buttonPadding, t) ??
          buttonPadding,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusXl: lerpDouble(radiusXl, other.radiusXl, t) ?? radiusXl,
      iconSizeSm: lerpDouble(iconSizeSm, other.iconSizeSm, t) ?? iconSizeSm,
      iconSizeMd: lerpDouble(iconSizeMd, other.iconSizeMd, t) ?? iconSizeMd,
      buttonHeight:
          lerpDouble(buttonHeight, other.buttonHeight, t) ?? buttonHeight,
      smallButtonHeight:
          lerpDouble(smallButtonHeight, other.smallButtonHeight, t) ??
          smallButtonHeight,
      inputMinHeight:
          lerpDouble(inputMinHeight, other.inputMinHeight, t) ?? inputMinHeight,
      contentMaxHeight:
          lerpDouble(contentMaxHeight, other.contentMaxHeight, t) ??
          contentMaxHeight,
      breathingDuration: t < 0.5 ? breathingDuration : other.breathingDuration,
      rotationDuration: t < 0.5 ? rotationDuration : other.rotationDuration,
      placeholderBreathingDuration: t < 0.5
          ? placeholderBreathingDuration
          : other.placeholderBreathingDuration,
    );
  }
}
