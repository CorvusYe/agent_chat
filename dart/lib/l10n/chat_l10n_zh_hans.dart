import 'chat_l10n.dart';

/// 中文简体（zh-Hans）实现。
class ChatL10nZhHans extends ChatL10n {
  const ChatL10nZhHans();

  @override
  String get emptyChatHint => '发送一条消息开始对话';
  @override
  String get inputHint => '输入消息…';
  @override
  String get expandAll => '展开全部';
  @override
  String get collapse => '收起';
  @override
  String get userMessageTitle => '用户消息';
  @override
  String get queueTitle => '待发送消息';
  @override
  String get queueEmpty => '待发送队列为空';
  @override
  String get labelThinking => '思考';
  @override
  String get labelContent => '回答';
  @override
  String get labelConfirm => '需要确认';
  @override
  String get labelCustom => '自定义';
  @override
  String labelToolWith(String toolName) => '工具 · $toolName';
  @override
  String get thinkingPlaceholder => '正在思考';
  @override
  String statsTokens(int count) => '$count 词元';
  @override
  String get errorLabel => '错误';
  @override
  String get btnAllow => '允许';
  @override
  String get btnAlwaysAllow => '始终允许';
  @override
  String get btnCancel => '取消';
}
