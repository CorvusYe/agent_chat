import 'chat_l10n.dart';

/// 英文实现。
class ChatL10nEn extends ChatL10n {
  const ChatL10nEn();

  @override
  String get emptyChatHint => 'Send a message to start the conversation';
  @override
  String get inputHint => 'Type a message…';
  @override
  String get expandAll => 'Expand all';
  @override
  String get collapse => 'Collapse';
  @override
  String get userMessageTitle => 'User message';
  @override
  String get queueTitle => 'Queued messages';
  @override
  String get queueEmpty => 'The queue is empty';
  @override
  String get labelThinking => 'Thinking';
  @override
  String get labelContent => 'Response';
  @override
  String get labelConfirm => 'Requires confirmation';
  @override
  String get labelCustom => 'Custom';
  @override
  String labelToolWith(String toolName) => 'Tool · $toolName';
  @override
  String get thinkingPlaceholder => 'Thinking…';
  @override
  String statsTokens(int count) => '$count tokens';
  @override
  String get errorLabel => 'Error';
  @override
  String get btnAllow => 'Allow';
  @override
  String get btnAlwaysAllow => 'Always allow';
  @override
  String get btnCancel => 'Cancel';
}
