import 'chat_l10n.dart';

/// 中文繁体（zh-Hant）实现。
class ChatL10nZhHant extends ChatL10n {
  const ChatL10nZhHant();

  @override
  String get emptyChatHint => '發送一則訊息開始對話';
  @override
  String get inputHint => '輸入訊息…';
  @override
  String get expandAll => '展開全部';
  @override
  String get collapse => '收起';
  @override
  String get userMessageTitle => '使用者訊息';
  @override
  String get queueTitle => '待發送訊息';
  @override
  String get queueEmpty => '待發送佇列為空';
  @override
  String get labelThinking => '思考';
  @override
  String get labelContent => '回答';
  @override
  String get labelConfirm => '需要確認';
  @override
  String get labelCustom => '自訂';
  @override
  String labelToolWith(String toolName) => '工具 · $toolName';
  @override
  String get thinkingPlaceholder => '正在思考';
  @override
  String statsTokens(int count) => '$count 詞元';
  @override
  String get errorLabel => '錯誤';
  @override
  String get btnAllow => '允許';
  @override
  String get btnAlwaysAllow => '始終允許';
  @override
  String get btnCancel => '取消';
}
