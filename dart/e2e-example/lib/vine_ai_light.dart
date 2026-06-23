/// Vine AI 轻量导入 — 仅导入不依赖 dart:mirrors 的模块
///
/// Flutter AOT 会加载包内所有 dart 文件，即使未 import 也不行。
/// 只能隔离到真正不碰 mirrors 的子集。
library;

export 'package:vine_ai/src/models/models.dart';
export 'package:vine_ai/src/llm/llm_client.dart';
export 'package:vine_ai/src/llm/openai_adapter.dart';
export 'package:vine_ai/src/mermaid/mermaid_parser.dart';
