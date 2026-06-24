import 'package:flutter/material.dart';
import '../app_l10n.dart';
import '../main.dart';
import 'streaming_output.dart';
import 'tool_calls_demo.dart';
import 'confirmation_gate.dart';
import 'queue_demo.dart';
import 'input_modes.dart';
import 'history_demo.dart';
import 'custom_blocks_demo.dart';
import 'theme_gallery.dart';
import 'stats_demo.dart';
import 'custom_theme_demo.dart';
import 'collapse_demo.dart';
import 'error_demo.dart';
import 'custom_language_demo.dart';
import 'code_drawer.dart';

/// 特性描述 — 含标题、说明、图标、构建器和对应 API 代码片段
class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  final List<CodeSnippet> snippets;
  const _Feature(
    this.title,
    this.subtitle,
    this.icon,
    this.builder,
    this.snippets,
  );
}

List<_Feature> _buildFeatures(AppL10n L) => <_Feature>[
  _Feature(
    L.featureTitles[0],
    L.featureSubtitles[0],
    Icons.text_fields,
    (_) => const StreamingOutputDemo(),
    L.featureSnippets[0],
  ),
  _Feature(
    L.featureTitles[1],
    L.featureSubtitles[1],
    Icons.build_circle,
    (_) => const ToolCallsDemo(),
    L.featureSnippets[1],
  ),
  _Feature(
    L.featureTitles[2],
    L.featureSubtitles[2],
    Icons.gpp_maybe,
    (_) => const ConfirmationGateDemo(),
    L.featureSnippets[2],
  ),
  _Feature(
    L.featureTitles[3],
    L.featureSubtitles[3],
    Icons.error_outline,
    (_) => const ErrorDemo(),
    L.featureSnippets[3],
  ),
  _Feature(
    L.featureTitles[4],
    L.featureSubtitles[4],
    Icons.queue,
    (_) => const QueueDemo(),
    L.featureSnippets[4],
  ),
  _Feature(
    L.featureTitles[5],
    L.featureSubtitles[5],
    Icons.keyboard,
    (_) => const InputModesDemo(),
    L.featureSnippets[5],
  ),
  _Feature(
    L.featureTitles[6],
    L.featureSubtitles[6],
    Icons.history,
    (_) => const HistoryDemo(),
    L.featureSnippets[6],
  ),
  _Feature(
    L.featureTitles[7],
    L.featureSubtitles[7],
    Icons.widgets,
    (_) => const CustomBlocksDemo(),
    L.featureSnippets[7],
  ),
  _Feature(
    L.featureTitles[8],
    L.featureSubtitles[8],
    Icons.palette,
    (_) => const ThemeGallery(),
    L.featureSnippets[8],
  ),
  _Feature(
    L.featureTitles[9],
    L.featureSubtitles[9],
    Icons.colorize,
    (_) => const CustomThemeDemo(),
    L.featureSnippets[9],
  ),
  _Feature(
    L.featureTitles[10],
    L.featureSubtitles[10],
    Icons.unfold_more,
    (_) => const CollapseDemo(),
    L.featureSnippets[10],
  ),
  _Feature(
    L.featureTitles[11],
    L.featureSubtitles[11],
    Icons.bar_chart,
    (_) => const StatsDemo(),
    L.featureSnippets[11],
  ),
  _Feature(
    L.featureTitles[12],
    L.featureSubtitles[12],
    Icons.translate,
    (_) => const CustomLanguageDemo(),
    L.featureSnippets[12],
  ),
];

class FeatureHub extends StatefulWidget {
  const FeatureHub({super.key});

  @override
  State<FeatureHub> createState() => _FeatureHubState();
}

class _FeatureHubState extends State<FeatureHub> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final L = AppL10n.of(context);
    final features = _buildFeatures(L);
    final feature = features[_current];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(feature.title),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.code),
              tooltip: L.viewApiCode,
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: L.switchLocale,
            onPressed: () => ShowcaseApp.of(context)?.cycleLocale(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L.appTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      L.appSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withAlpha(
                          179,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: features.length,
                  itemBuilder: (_, i) {
                    final f = features[i];
                    final selected = i == _current;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: theme.colorScheme.primaryContainer
                          .withAlpha(77),
                      leading: Icon(
                        f.icon,
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                      title: Text(
                        f.title,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: Text(
                        f.subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        setState(() => _current = i);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: CodeDrawer(
        snippets: feature.snippets,
        featureName: feature.title,
      ),
      body: features[_current].builder(context),
    );
  }
}
