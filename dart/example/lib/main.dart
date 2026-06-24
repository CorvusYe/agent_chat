// agent_chat Feature Showcase — 切换式 UI API 验证应用
//
// 通过左侧 Drawer 切换不同的特性示例，每个示例独立展示 agent_chat 库
// 的某个具体 UI API。所有示例共享全局主题，可通过 Theme Gallery 切换。
//
// 运行方式：
//   cd dart/example && flutter run

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import 'features/feature_hub.dart';
import 'app_l10n.dart';

void main() {
  runApp(const ShowcaseApp());
}

ThemeMode _themeMode = ThemeMode.dark;
int _colorSeedIndex = 0;
final _colorSeeds = <Color>[
  Colors.teal,
  Colors.indigo,
  Colors.deepPurple,
  Colors.deepOrange,
  Colors.blueGrey,
  Colors.pink,
];

// ── 内置 ChatTheme 配置 ──
int _chatThemeIndex = 0;

ChatTheme _currentChatTheme(Brightness brightness) {
  switch (_chatThemeIndex) {
    case 0:
      return brightness == Brightness.light
          ? ChatThemes.fluent
          : ChatThemes.fluentDark;
    case 1:
      return brightness == Brightness.light
          ? ChatThemes.light
          : ChatThemes.dark;
    case 2:
      return brightness == Brightness.light
          ? ChatThemes.neumorphicLight
          : ChatThemes.neumorphicDark;
    default:
      return brightness == Brightness.light
          ? ChatThemes.fluent
          : ChatThemes.fluentDark;
  }
}

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  static ShowcaseAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShowcaseAppState>();

  @override
  State<ShowcaseApp> createState() => ShowcaseAppState();
}

class ShowcaseAppState extends State<ShowcaseApp> {
  Locale _locale = WidgetsBinding.instance.platformDispatcher.locale;

  ThemeMode get themeMode => _themeMode;
  Color get colorSeed => _colorSeeds[_colorSeedIndex];
  int get chatThemeIndex => _chatThemeIndex;

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void cycleColorSeed() {
    setState(() {
      _colorSeedIndex = (_colorSeedIndex + 1) % _colorSeeds.length;
    });
  }

  void setChatThemeIndex(int index) {
    setState(() {
      _chatThemeIndex = index.clamp(0, 2);
    });
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  /// Cycle through supported locales: zh-Hans → zh-Hant → en → zh-Hans …
  void cycleLocale() {
    final isHans = _locale.languageCode == 'zh' && _locale.scriptCode != 'Hant';
    final isHant =
        _locale.languageCode == 'zh' &&
        (_locale.scriptCode == 'Hant' ||
            _locale.countryCode == 'TW' ||
            _locale.countryCode == 'HK');

    if (isHans) {
      setLocale(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
    } else if (isHant) {
      setLocale(const Locale('en'));
    } else {
      setLocale(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _themeMode == ThemeMode.light
        ? Brightness.light
        : _themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.dark;
    final chatTheme = _currentChatTheme(brightness);
    final appL10n = AppL10n.fromLocale(_locale);
    final chatL10n = ChatL10n.fromLocale(_locale);

    return AppL10nScope(
      l10n: appL10n,
      child: ChatL10nScope(
        l10n: chatL10n,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Agent Chat Showcase',
          themeMode: _themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: colorSeed,
            useMaterial3: true,
            fontFamily: 'AlibabaPuHuiTi',
            extensions: [chatTheme],
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: colorSeed,
            useMaterial3: true,
            fontFamily: 'AlibabaPuHuiTi',
            extensions: [chatTheme],
          ),
          home: const FeatureHub(),
        ),
      ),
    );
  }
}
