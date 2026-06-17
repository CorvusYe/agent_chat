// CodeDrawer — 右侧滑出的代码展示抽屉
//
// 每个特性定义一组 CodeSnippet，展示该特性用到的核心 API。

import 'package:flutter/material.dart';

/// 一段代码片段
class CodeSnippet {
  final String title;
  final String code;
  final String language;
  const CodeSnippet(this.title, this.code, {this.language = 'dart'});
}

/// 代码展示抽屉 — 在 Scaffold.endDrawer 中使用
class CodeDrawer extends StatelessWidget {
  final List<CodeSnippet> snippets;
  final String featureName;

  const CodeDrawer({
    super.key,
    required this.snippets,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.code, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$featureName — API',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '核心接口调用',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withAlpha(179),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 代码列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: snippets.length,
                itemBuilder: (_, i) {
                  final s = snippets[i];
                  return _CodeCard(snippet: s, isDark: isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final CodeSnippet snippet;
  final bool isDark;
  const _CodeCard({required this.snippet, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withAlpha(8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  snippet.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          // 代码区
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              snippet.code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.5,
                color: isDark
                    ? const Color(0xFFCDD6F4)
                    : const Color(0xFF1E1E2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
