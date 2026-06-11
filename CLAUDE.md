# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a Flutter project located in the `dart/` directory. The source code is structured as a standard Flutter app:

- `dart/lib/main.dart` — App entry point and widget tree
- `dart/test/` — Flutter widget and unit tests
- `dart/pubspec.yaml` — Dependencies and project config
- `dart/analysis_options.yaml` — Dart linter configuration

## Build & Run Commands

```bash
cd dart

# Get dependencies
flutter pub get

# Run the app
flutter run

# Analyze code
flutter analyze

# Run all tests
flutter test

# Run a specific test
flutter test test/widget_test.dart
```

## Architecture

The project follows standard Flutter architecture with Material Design. Currently uses the default Flutter counter app template. Key patterns:

- **State management**: `StatefulWidget` + `setState()` (standard Flutter)
- **Testing**: `flutter_test` with `WidgetTester` for widget tests
- **Linting**: `flutter_lints` recommended rules (configured in `analysis_options.yaml`)
- **Dart SDK**: ^3.12.0


## AI编码必须遵循的

- 改完一个 dart 文件，必须对该文件运行 dart format xxx.dart (注意文件所在路径)


## 提交规范

- Co-Authored-By: DeepSeek V4 Flash <service@deepseek.com>
