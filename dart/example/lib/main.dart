// agent_chat Feature Showcase — 切换式 UI API 验证应用
//
// 通过左侧 Drawer 切换不同的特性示例，每个示例独立展示 agent_chat 库
// 的某个具体 UI API。所有示例共享全局主题，可通过 Theme Gallery 切换。
//
// 运行方式：
//   cd dart/example && flutter run

import 'package:flutter/material.dart';
import 'features/feature_hub.dart';

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

class ShowcaseApp extends StatefulWidget {
  const ShowcaseApp({super.key});

  static ShowcaseAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShowcaseAppState>();

  @override
  State<ShowcaseApp> createState() => ShowcaseAppState();
}

class ShowcaseAppState extends State<ShowcaseApp> {
  ThemeMode get themeMode => _themeMode;
  Color get colorSeed => _colorSeeds[_colorSeedIndex];

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void cycleColorSeed() {
    setState(() {
      _colorSeedIndex = (_colorSeedIndex + 1) % _colorSeeds.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agent Chat Showcase',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: colorSeed,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: colorSeed,
        useMaterial3: true,
      ),
      home: const FeatureHub(),
    );
  }
}
