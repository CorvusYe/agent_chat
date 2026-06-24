import 'package:flutter/widgets.dart';
import 'chat_l10n_zh_hans.dart';
import 'chat_l10n_zh_hant.dart';
import 'chat_l10n_en.dart';

export 'chat_l10n_zh_hans.dart';
export 'chat_l10n_zh_hant.dart';
export 'chat_l10n_en.dart';

/// ChatL10n — 聊天 UI 的国际化支持。
///
/// 提供中文简体（zh-Hans）、中文繁体（zh-Hant）、英文（en）三种内置语言。
/// 通过 [ChatL10nScope] InheritedWidget 注入到 widget 树，
/// 子 widget 通过 [ChatL10n.of] 获取当前实例。
///
/// 使用方式：
///
/// ```dart
/// // 在 MaterialApp 外层注入：
/// ChatL10nScope(
///   l10n: ChatL10n.zhHans,
///   child: MaterialApp(...),
/// )
///
/// // 或在 ChatScreen 指定：
/// ChatScreen(bus: bus, l10n: ChatL10n.en)
/// ```
///
/// 子 widget 中获取：
/// ```dart
/// final l10n = ChatL10n.of(context);
/// ```
///
/// ## 添加新语言
///
/// 继承 [ChatL10n] 实现所有 getter，然后用 [ChatL10nScope] 注入：
///
/// ```dart
/// ChatL10nScope(
///   l10n: MyFrenchChatL10n(),
///   child: ChatScreen(bus: bus),
/// )
/// ```
@immutable
abstract class ChatL10n {
  const ChatL10n();

  // ──────────────────────────────────────────────
  //  Chat hints
  // ──────────────────────────────────────────────

  /// 空聊天时的占位提示。
  String get emptyChatHint;

  /// 输入框占位文本。
  String get inputHint;

  // ──────────────────────────────────────────────
  //  User message expand/collapse
  // ──────────────────────────────────────────────

  /// "展开全部" — 用户消息折叠后展开按钮。
  String get expandAll;

  /// "收起" — 用户消息展开后的折叠按钮。
  String get collapse;

  /// "用户消息" — 展开对话框的标题。
  String get userMessageTitle;

  // ──────────────────────────────────────────────
  //  Queue popup
  // ──────────────────────────────────────────────

  /// "待发送消息" — 队列弹窗标题。
  String get queueTitle;

  /// "待发送队列为空" — 队列为空时的提示。
  String get queueEmpty;

  // ──────────────────────────────────────────────
  //  Block labels (timeline headers)
  // ──────────────────────────────────────────────

  /// 思考块标签。
  String get labelThinking;

  /// 内容块标签。
  String get labelContent;

  /// 确认门标签。
  String get labelConfirm;

  /// 自定义块标签（无注册信息时的回退）。
  String get labelCustom;

  /// 工具块标签（带工具名）。
  String labelToolWith(String toolName);

  // ──────────────────────────────────────────────
  //  Thinking placeholder
  // ──────────────────────────────────────────────

  /// "正在思考" — 处理中的占位文字。
  String get thinkingPlaceholder;

  // ──────────────────────────────────────────────
  //  Stats bar
  // ──────────────────────────────────────────────

  /// Token 统计文字。
  String statsTokens(int count);

  // ──────────────────────────────────────────────
  //  Error
  // ──────────────────────────────────────────────

  /// "错误" — 错误块头部标签。
  String get errorLabel;

  // ──────────────────────────────────────────────
  //  Confirm gate buttons
  // ──────────────────────────────────────────────

  /// "允许" — 确认门允许按钮。
  String get btnAllow;

  /// "始终允许" — 确认门始终允许按钮。
  String get btnAlwaysAllow;

  /// "取消" — 确认门取消按钮。
  String get btnCancel;

  // ──────────────────────────────────────────────
  //  Built-in instances
  // ──────────────────────────────────────────────

  /// 中文简体（zh-Hans）。
  static const ChatL10n zhHans = ChatL10nZhHans();

  /// 中文繁体（zh-Hant）。
  static const ChatL10n zhHant = ChatL10nZhHant();

  /// 英文。
  static const ChatL10n en = ChatL10nEn();

  /// 根据 [Locale] 返回合适的实例，默认中文简体。
  ///
  /// 优先通过 [scriptCode] 区分简体（Hans）和繁体（Hant），
  /// 降级兼容 [countryCode] 判断（TW / HK / MO → 繁体）。
  static ChatL10n fromLocale(Locale locale) {
    if (locale.languageCode == 'en') return en;
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') return zhHant;
      if (locale.countryCode == 'TW' ||
          locale.countryCode == 'HK' ||
          locale.countryCode == 'MO') {
        return zhHant;
      }
      return zhHans;
    }
    return zhHans;
  }

  /// 从 widget 树中获取当前 [ChatL10n]，未注入时默认中文简体。
  static ChatL10n of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ChatL10nScope>();
    return scope?.l10n ?? zhHans;
  }
}

// ═══════════════════════════════════════════════════
//  InheritedWidget — 将 ChatL10n 注入 widget 树
// ═══════════════════════════════════════════════════

/// 通过 InheritedWidget 提供 [ChatL10n] 实例。
class ChatL10nScope extends InheritedWidget {
  final ChatL10n l10n;

  const ChatL10nScope({super.key, required this.l10n, required super.child});

  @override
  bool updateShouldNotify(ChatL10nScope old) => old.l10n != l10n;
}

/// 便捷组件 — 将特定 [ChatL10n] 注入子树。
class ChatL10nProvider extends StatelessWidget {
  final ChatL10n l10n;
  final Widget child;

  const ChatL10nProvider({super.key, required this.l10n, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChatL10nScope(l10n: l10n, child: child);
  }
}
