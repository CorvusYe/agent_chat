// 自定义语言演示
//
// 展示如何通过 ChatL10n 继承 + ChatL10nScope 注入自定义语言。
// 本例使用法语（Français）作为自定义语言示例。

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';

/// 法语翻译实现 — 开发者自己项目中的代码。
///
/// 继承 [ChatL10n]，编译器强制覆盖全部 getter，不会漏翻。
class ChatL10nFrench extends ChatL10n {
  const ChatL10nFrench();

  @override
  String get emptyChatHint => 'Envoyez un message pour commencer';
  @override
  String get inputHint => 'Entrez un message…';
  @override
  String get expandAll => 'Tout développer';
  @override
  String get collapse => 'Réduire';
  @override
  String get userMessageTitle => 'Message utilisateur';
  @override
  String get queueTitle => 'Messages en attente';
  @override
  String get queueEmpty => "La file d'attente est vide";
  @override
  String get labelThinking => 'Réflexion';
  @override
  String get labelContent => 'Réponse';
  @override
  String get labelConfirm => 'Confirmation requise';
  @override
  String get labelCustom => 'Personnalisé';
  @override
  String labelToolWith(String toolName) => 'Outil · $toolName';
  @override
  String get thinkingPlaceholder => 'En train de réfléchir…';
  @override
  String statsTokens(int count) => '$count tokens';
  @override
  String get errorLabel => 'Erreur';
  @override
  String get btnAllow => 'Autoriser';
  @override
  String get btnAlwaysAllow => 'Toujours autoriser';
  @override
  String get btnCancel => 'Annuler';
}

class CustomLanguageDemo extends StatefulWidget {
  const CustomLanguageDemo({super.key});

  @override
  State<CustomLanguageDemo> createState() => _CustomLanguageDemoState();
}

class _CustomLanguageDemoState extends State<CustomLanguageDemo> {
  late final ChatBus bus;
  bool _useFrench = true;

  @override
  void initState() {
    super.initState();
    bus = DefaultChatBus(
      onGenerate: _mockReply,
      onInterrupt: () => _cancelled = true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoDemo());
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  bool _cancelled = false;

  Future<void> _autoDemo() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    bus.sendMessage('Bonjour!');
  }

  Stream<ExchangeEvent> _mockReply(String text) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 'think');
    const thinkText = 'Laissez-moi analyser votre demande…';
    for (var i = 0; i < thinkText.length; i += 4) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (_cancelled) return;
      yield ThinkingDelta(
        id,
        'think',
        thinkText.substring(0, (i + 4).clamp(0, thinkText.length)),
      );
    }
    if (_cancelled) return;
    yield ThinkingCompleted(id, 'think', thinkText);

    yield ToolCallStarted(id, 'tool', 'recherche', {'query': 'doc'});
    await Future.delayed(const Duration(milliseconds: 300));
    if (_cancelled) return;
    yield ToolCallCompleted(id, 'tool', '✓ Résultat trouvé');

    yield ParallelBoundary(id);
    yield ContentStarted(id, 'content');
    const reply =
        'Voici un exemple de ChatScreen en français.\n\n'
        'Tous les textes UI sont traduits via ChatL10nFrench.\n'
        'Cliquez sur le bouton ci-dessus pour basculer entre français et anglais.';
    for (var i = 0; i < reply.length; i += 3) {
      await Future.delayed(const Duration(milliseconds: 15));
      if (_cancelled) return;
      yield ContentDelta(
        id,
        'content',
        reply.substring(0, (i + 3).clamp(0, reply.length)),
      );
    }
    yield ContentCompleted(id, 'content', reply);
    yield TokenCount(id, 42);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 控制栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Icon(
                Icons.translate,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'ChatL10nFrench',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text('FR', style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('EN', style: const TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_useFrench},
                onSelectionChanged: (v) => setState(() => _useFrench = v.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ChatScreen 注入自定义语言
        Expanded(
          child: ChatL10nScope(
            l10n: _useFrench ? const ChatL10nFrench() : ChatL10n.en,
            child: ChatScreen(bus: bus),
          ),
        ),
      ],
    );
  }
}
