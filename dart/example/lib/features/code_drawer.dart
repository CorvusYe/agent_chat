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
          // 代码区 — 语法高亮
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SelectableText.rich(
              _highlight(snippet.code, isDark),
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

// ═══════════════════════════════════════════════════════════════
//  简易 Dart 语法高亮
// ═══════════════════════════════════════════════════════════════

final _dartKeywords = RegExp(
  r'\b(?:abstract|as|assert|async|await|break|case|catch|class|const|'
  r'continue|covariant|default|deferred|do|dynamic|else|enum|export|'
  r'extends|extension|external|factory|false|final|finally|for|Function|'
  r'get|hide|if|implements|import|in|interface|is|late|library|mixin|'
  r'new|null|on|operator|part|required|rethrow|return|sealed|set|show|'
  r'static|super|switch|sync|this|throw|true|try|type|typedef|var|void|'
  r'when|while|with|yield)\b',
);

final _dartTypeKeywords = RegExp(
  r'\b(?:bool|double|int|String|List|Map|Set|num|Record|Never|Null|Object|'
  r'Stream|Future|DateTime|Duration|Color|IconData|EdgeInsets)\b',
);

/// 将 Dart 代码文本转为带语法高亮的 TextSpan 列表
TextSpan _highlight(String code, bool isDark) {
  final spans = <TextSpan>[];
  final pal = _Palette(isDark);

  // 按行处理，保留换行
  final lines = code.split('\n');
  for (var li = 0; li < lines.length; li++) {
    if (li > 0) spans.add(const TextSpan(text: '\n'));
    final line = lines[li];
    int i = 0;

    while (i < line.length) {
      // 1. 注释 //
      if (i < line.length - 1 && line[i] == '/' && line[i + 1] == '/') {
        spans.add(
          TextSpan(
            text: line.substring(i),
            style: TextStyle(color: pal.comment),
          ),
        );
        break;
      }

      // 2. 多行注释 /* ... */（单行内）
      if (i < line.length - 1 && line[i] == '/' && line[i + 1] == '*') {
        final end = line.indexOf('*/', i + 2);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: line.substring(i, end + 2),
              style: TextStyle(color: pal.comment),
            ),
          );
          i = end + 2;
          continue;
        }
      }

      // 3. 字符串单引号 / 多行 '''
      if (line[i] == '\'') {
        final triple =
            (i < line.length - 2 && line[i + 1] == '\'' && line[i + 2] == '\'');
        final end = triple
            ? _findTripleEnd(line, i + 3)
            : line.indexOf("'", i + 1);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: line.substring(i, triple ? end + 3 : end + 1),
              style: TextStyle(color: pal.string),
            ),
          );
          i = triple ? end + 3 : end + 1;
          continue;
        }
      }

      // 4. 字符串双引号 / 多行 """
      if (line[i] == '"') {
        final triple =
            (i < line.length - 2 && line[i + 1] == '"' && line[i + 2] == '"');
        final end = triple
            ? _findTripleEnd(line, i + 3, '"')
            : line.indexOf('"', i + 1);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: line.substring(i, triple ? end + 3 : end + 1),
              style: TextStyle(color: pal.string),
            ),
          );
          i = triple ? end + 3 : end + 1;
          continue;
        }
      }

      // 5. 模板字符串 ${...}
      if (i < line.length - 1 && line[i] == r'$' && line[i + 1] == '{') {
        final end = line.indexOf('}', i + 2);
        if (end != -1) {
          spans.add(
            TextSpan(
              text: r'${',
              style: TextStyle(color: pal.string),
            ),
          );
          // 递归高亮内部表达式
          spans.add(_highlightInline(line.substring(i + 2, end), isDark));
          spans.add(
            TextSpan(
              text: '}',
              style: TextStyle(color: pal.string),
            ),
          );
          i = end + 1;
          continue;
        }
      }

      // 6. 占位符箭头符号
      if (line[i] == '→' ||
          line[i] == '←' ||
          line[i] == '├' ||
          line[i] == '└' ||
          line[i] == '─') {
        int end = i;
        while (end < line.length && "→←├└─│".contains(line[end])) end++;
        spans.add(
          TextSpan(
            text: line.substring(i, end),
            style: TextStyle(color: pal.symbol),
          ),
        );
        i = end;
        continue;
      }

      // 7. 标识符 / 关键字匹配
      if (_isIdentStart(line[i])) {
        int end = i + 1;
        while (end < line.length && _isIdentPart(line[end])) end++;
        final word = line.substring(i, end);

        if (_dartKeywords.hasMatch(word)) {
          spans.add(
            TextSpan(
              text: word,
              style: TextStyle(color: pal.keyword, fontWeight: FontWeight.w600),
            ),
          );
        } else if (_dartTypeKeywords.hasMatch(word)) {
          spans.add(
            TextSpan(
              text: word,
              style: TextStyle(color: pal.type),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: word,
              style: TextStyle(color: pal.defaultText),
            ),
          );
        }
        i = end;
        continue;
      }

      // 8. 数字
      if (_isDigit(line[i]) ||
          (line[i] == '.' && i + 1 < line.length && _isDigit(line[i + 1]))) {
        int end = i + 1;
        bool hasDot = line[i] == '.';
        while (end < line.length &&
            (_isDigit(line[end]) || (!hasDot && line[end] == '.'))) {
          if (line[end] == '.') hasDot = true;
          end++;
        }
        spans.add(
          TextSpan(
            text: line.substring(i, end),
            style: TextStyle(color: pal.number),
          ),
        );
        i = end;
        continue;
      }

      // 9. 普通字符
      spans.add(
        TextSpan(
          text: line[i],
          style: TextStyle(color: pal.defaultText),
        ),
      );
      i++;
    }
  }

  return TextSpan(children: spans);
}

TextSpan _highlightInline(String code, bool isDark) {
  // 对内联表达式重用高亮逻辑
  final pal = _Palette(isDark);
  final spans = <TextSpan>[];
  int i = 0;
  while (i < code.length) {
    if (_isIdentStart(code[i])) {
      int end = i + 1;
      while (end < code.length && _isIdentPart(code[end])) end++;
      final word = code.substring(i, end);
      if (_dartKeywords.hasMatch(word)) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(color: pal.keyword, fontWeight: FontWeight.w600),
          ),
        );
      } else if (_dartTypeKeywords.hasMatch(word)) {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(color: pal.type),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(color: pal.defaultText),
          ),
        );
      }
      i = end;
    } else {
      spans.add(
        TextSpan(
          text: code[i],
          style: TextStyle(color: pal.defaultText),
        ),
      );
      i++;
    }
  }
  return TextSpan(children: spans);
}

int _findTripleEnd(String line, int start, [String quote = "'"]) {
  for (int i = start; i < line.length - 2; i++) {
    if (line[i] == quote[0] &&
        line[i + 1] == quote[0] &&
        line[i + 2] == quote[0])
      return i;
  }
  return -1;
}

bool _isIdentStart(String ch) =>
    (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) ||
    (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122) ||
    ch == '_' ||
    ch == r'$';

bool _isIdentPart(String ch) => _isIdentStart(ch) || _isDigit(ch);

bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

/// 语法高亮配色
class _Palette {
  final bool isDark;
  _Palette(this.isDark);

  Color get defaultText =>
      isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E);
  Color get keyword =>
      isDark ? const Color(0xFFcba6f7) : const Color(0xFF7c3aed); // 紫色
  Color get type =>
      isDark ? const Color(0xFF89b4fa) : const Color(0xFF2563eb); // 蓝色
  Color get string =>
      isDark ? const Color(0xFFa6e3a1) : const Color(0xFF16a34a); // 绿色
  Color get comment =>
      isDark ? const Color(0xFF6c7086) : const Color(0xFF94a3b8); // 灰色
  Color get number =>
      isDark ? const Color(0xFFfab387) : const Color(0xFFea580c); // 橙色
  Color get symbol =>
      isDark ? const Color(0xFF94e2d5) : const Color(0xFF0891b2); // 青色
}
