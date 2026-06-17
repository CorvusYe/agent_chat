/// Vine AI 动态节点 / 工作流存储服务
///
/// 将 AI 动态创建的 YAML 节点定义和 MMD 工作流定义持久化到文件系统。
/// 后续将迁移至 Isar 数据库。
library;

import 'dart:io';
import 'dart:convert';

// ═══════════════════════════════════════════════════════════════════════════
//  动态节点服务 — 管理 YAML 节点定义的增删查
// ═══════════════════════════════════════════════════════════════════════════

/// 动态节点定义
class DynamicNodeDef {
  final String name;
  final String yamlContent;
  final DateTime createdAt;

  const DynamicNodeDef({
    required this.name,
    required this.yamlContent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'yamlContent': yamlContent,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DynamicNodeDef.fromJson(Map<String, dynamic> json) => DynamicNodeDef(
    name: json['name'] as String,
    yamlContent: json['yamlContent'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// 动态节点存储服务
class DynamicNodeService {
  final String storageDir;

  DynamicNodeService(this.storageDir);

  /// 创建存储目录（如不存在）
  Future<void> ensureDir() async {
    final dir = Directory(storageDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 列出所有动态节点
  Future<List<DynamicNodeDef>> listNodes() async {
    await ensureDir();
    final dir = Directory(storageDir);
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.yaml') || f.path.endsWith('.yml'),
    );
    final nodes = <DynamicNodeDef>[];
    for (final file in files) {
      final name = file.path
          .split(Platform.pathSeparator)
          .last
          .replaceAll(RegExp(r'\.(yaml|yml)$'), '');
      final content = await file.readAsString();
      final stat = await file.stat();
      nodes.add(
        DynamicNodeDef(
          name: name,
          yamlContent: content,
          createdAt: stat.modified,
        ),
      );
    }
    return nodes;
  }

  /// 保存动态节点（YAML 内容写入文件）
  Future<DynamicNodeDef> saveNode(String name, String yamlContent) async {
    await ensureDir();
    final file = File('$storageDir$pathSep$name.yaml');
    await file.writeAsString(yamlContent);
    final def = DynamicNodeDef(
      name: name,
      yamlContent: yamlContent,
      createdAt: DateTime.now(),
    );
    return def;
  }

  /// 读取单个节点
  Future<DynamicNodeDef?> readNode(String name) async {
    final file = File('$storageDir$pathSep$name.yaml');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final stat = await file.stat();
    return DynamicNodeDef(
      name: name,
      yamlContent: content,
      createdAt: stat.modified,
    );
  }

  /// 删除节点
  Future<void> deleteNode(String name) async {
    final file = File('$storageDir$pathSep$name.yaml');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 写入预注册的 local_method 节点（仅首次运行）
  static Future<void> ensureFixtures(
    String nodesDir,
    String workflowsDir,
  ) async {
    final nodeService = DynamicNodeService(nodesDir);
    final wfService = DynamicWorkflowService(workflowsDir);
    await nodeService.ensureDir();
    await wfService.ensureDir();

    // 预注册 local_method 节点
    for (final entry in _fixtureNodes.entries) {
      final file = File('$nodesDir$pathSep${entry.key}.yaml');
      if (!await file.exists()) {
        await file.writeAsString(entry.value);
      }
    }

    // 预注册示例工作流
    for (final entry in _fixtureWorkflows.entries) {
      final file = File('$workflowsDir$pathSep${entry.key}.mmd');
      if (!await file.exists()) {
        await file.writeAsString(entry.value);
      }
    }
  }

  static String get pathSep => Platform.pathSeparator;

  /// 预注册的 local_method 节点（LLM 不能新建 local_method，只能复用这些）
  static const Map<String, String> _fixtureNodes = {
    'log_message': '''type: local_method
name: log_message
config:
  class: BasicService
  method: log
  params:
    message: "{{message}}"
  output_key: log_result''',

    'save_file': '''type: local_method
name: save_file
config:
  class: BasicService
  method: saveToFile
  params:
    content: "{{content}}"
    filename: "{{filename}}"
  output_key: save_result''',

    'read_file': '''type: local_method
name: read_file
config:
  class: BasicService
  method: readFromFile
  params:
    filename: "{{filename}}"
  output_key: file_content''',

    'transform_text': '''type: local_method
name: transform_text
config:
  class: BasicService
  method: transform
  params:
    input: "{{input}}"
    rule: "{{rule}}"
  output_key: transformed''',

    // ── 创建工作流所需的节点 ──
    'select_nodes': '''type: ai_model
name: select_nodes
config:
  description: "根据用户意图从已注册的 local_method 节点中选出合适的节点列表"
  model: deepseek-chat
  system_prompt: "根据用户需求，从 available_nodes 中选择合适的节点并按执行顺序排列。只选择 local_method 节点。输出节点名称列表。"
  output_schema:
    type: object
    properties:
      selected:
        type: array
        items:
          type: string
        description: 选中的节点名列表''',

    'validate_edges': '''type: local_method
name: validate_edges
config:
  class: WorkflowMetaService
  method: validateEdges
  params:
    nodes: "{{selected_nodes}}"
    edges: "{{proposed_edges}}"
  output_key: validation_result''',

    'build_mmd': '''type: local_method
name: build_mmd
config:
  class: WorkflowMetaService
  method: buildMmd
  params:
    workflow_name: "{{workflow_name}}"
    description: "{{description}}"
    start_node: "{{start_node}}"
    nodes: "{{selected_nodes}}"
    edges: "{{proposed_edges}}"
  output_key: mmd_content''',

    'register_and_save': '''type: local_method
name: register_and_save
config:
  class: WorkflowMetaService
  method: registerAndSave
  params:
    mmd_content: "{{mmd_content}}"
  output_key: register_result''',
  };

  /// 预注册的工作流定义
  static const Map<String, String> _fixtureWorkflows = {
    'echo_pipeline': '''%% name: echo_pipeline
%% description: 简单日志流水线：将用户输入写入文件
stateDiagram-v2
    [*] --> log_message
    log_message --> save_file
    save_file --> [*]''',

    'transform_pipeline': '''%% name: transform_pipeline
%% description: 文本变换流水线：读取文件 → 变换 → 保存
stateDiagram-v2
    [*] --> read_file
    read_file --> transform_text
    transform_text --> save_file
    save_file --> [*]''',

    // ── 创建工作流的工作流 ──
    'create_workflow_pipeline': '''%% name: create_workflow_pipeline
%% description: 元工作流：根据用户需求，从已有 local_method 节点中挑选并组装为新工作流，注册后立即执行
stateDiagram-v2
    [*] --> select_nodes
    select_nodes --> validate_edges
    validate_edges --> build_mmd
    build_mmd --> register_and_save
    register_and_save --> [*]''',
  };

  /// 生成 AI 友好的节点类型 YAML 模板说明
  static String get nodeTypeDocs => '''
# YAML 节点定义模板
# 支持以下类型：

## AI 模型节点 (ai_model)
type: ai_model
name: my_ai_node
config:
  description: "节点描述"
  model: deepseek-chat
  system_prompt: "系统提示词"
  output_schema:
    type: object
    properties:
      result:
        type: string
        description: "输出结果"

## 本地方法节点 (local_method)
type: local_method
name: my_method_node
config:
  class: ServiceName
  method: methodName
  params:
    input_key: "{{context_key}}"
  output_key: result_key
''';
}

// ═══════════════════════════════════════════════════════════════════════════
//  动态工作流服务 — 管理 MMD 工作流定义的增删查
// ═══════════════════════════════════════════════════════════════════════════

/// 动态工作流定义
class DynamicWorkflowDef {
  final String name;
  final String? description;
  final List<String> nodeNames;
  final String mmdContent;
  final DateTime createdAt;

  const DynamicWorkflowDef({
    required this.name,
    this.description,
    required this.nodeNames,
    required this.mmdContent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'nodeNames': nodeNames,
    'mmdContent': mmdContent,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DynamicWorkflowDef.fromJson(Map<String, dynamic> json) =>
      DynamicWorkflowDef(
        name: json['name'] as String,
        description: json['description'] as String?,
        nodeNames: List<String>.from(json['nodeNames'] as List),
        mmdContent: json['mmdContent'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 动态工作流存储服务
class DynamicWorkflowService {
  final String storageDir;

  DynamicWorkflowService(this.storageDir);

  String get pathSep => Platform.pathSeparator;

  Future<void> ensureDir() async {
    final dir = Directory(storageDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 列出所有动态工作流
  Future<List<DynamicWorkflowDef>> listWorkflows() async {
    await ensureDir();
    final dir = Directory(storageDir);
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.mmd'),
    );
    final wfs = <DynamicWorkflowDef>[];
    for (final file in files) {
      final content = await file.readAsString();
      final name =
          _extractName(content) ??
          file.path.split(pathSep).last.replaceAll('.mmd', '');
      final desc = _extractDescription(content);
      final nodeNames = _extractNodeNames(content);
      final stat = await file.stat();
      wfs.add(
        DynamicWorkflowDef(
          name: name,
          description: desc,
          nodeNames: nodeNames,
          mmdContent: content,
          createdAt: stat.modified,
        ),
      );
    }
    return wfs;
  }

  /// 从已有的节点名称列表动态组装 MMD 工作流
  ///
  /// [workflowName] — 工作流名称
  /// [description] — 可选描述
  /// [nodeNames] — 参与工作流的节点名称列表（按执行顺序）
  /// [startNode] — 起始节点名称
  /// [edges] — 边定义列表，格式: [from, to] 或 [from, to, condition]
  String assembleMmd({
    required String workflowName,
    String? description,
    required String startNode,
    required List<String> nodeNames,
    required List<List<String>> edges,
  }) {
    final buf = StringBuffer();
    buf.writeln('%% name: $workflowName');
    if (description != null) {
      buf.writeln('%% description: $description');
    }
    buf.writeln('stateDiagram-v2');
    buf.writeln('    [*] --> $startNode');

    final declaredFrom = <String>{};
    for (final edge in edges) {
      final from = edge[0];
      final to = edge[1];
      declaredFrom.add(from);
      final condition = edge.length > 2 ? edge[2] : null;
      // 'end' 目标转换为终态 [*]
      if (to == 'end') {
        if (condition != null) {
          buf.writeln('    $from --> [*]: $condition');
        } else {
          buf.writeln('    $from --> [*]');
        }
        continue;
      }
      if (condition != null) {
        buf.writeln('    $from --> $to: $condition');
      } else {
        buf.writeln('    $from --> $to');
      }
    }

    // 自动补全终态边：未作过前置节点 && 不是 startNode && 不是 'end' 别名的节点
    for (final n in nodeNames) {
      if (n != startNode && n != 'end' && !declaredFrom.contains(n)) {
        buf.writeln('    $n --> [*]');
      }
    }

    return buf.toString();
  }

  /// 保存动态工作流（MMD 内容写入文件）
  Future<DynamicWorkflowDef> saveWorkflow(String mmdContent) async {
    await ensureDir();
    final name =
        _extractName(mmdContent) ??
        'unnamed_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('$storageDir$pathSep$name.mmd');
    await file.writeAsString(mmdContent);
    final stat = await file.stat();
    return DynamicWorkflowDef(
      name: name,
      description: _extractDescription(mmdContent),
      nodeNames: _extractNodeNames(mmdContent),
      mmdContent: mmdContent,
      createdAt: stat.modified,
    );
  }

  /// 从已有节点生成标准工作流组装指南（给 LLM 的文档）
  static String workflowAssemblyDocs(List<String> availableNodes) =>
      '''
# MMD 工作流组装指南
可用节点: ${availableNodes.join(', ')}

## MMD 语法示例
%% name: my_workflow
%% description: 工作流描述
stateDiagram-v2
    [*] --> start_node
    node_a --> node_b
    node_b --> node_c: {{condition}}
    node_c --> [*]

## 规则
1. 用 [*] --> startNode 指定起始节点
2. 用 NodeA --> NodeB 定义无条件边
3. 用 NodeA --> NodeB: {{key}} 定义条件边
4. 用 Node --> [*] 定义终止节点
5. 必须通过 %% name: 注释指定工作流名称
''';

  /// 从 MMD 内容中提取工作流名称
  static String? _extractName(String mmd) {
    final match = RegExp(
      r'^%%\s*name\s*:\s*(.+)$',
      multiLine: true,
    ).firstMatch(mmd);
    return match?.group(1)?.trim();
  }

  /// 从 MMD 内容中提取描述
  static String? _extractDescription(String mmd) {
    final match = RegExp(
      r'^%%\s*description\s*:\s*(.+)$',
      multiLine: true,
    ).firstMatch(mmd);
    return match?.group(1)?.trim();
  }

  /// 从 MMD 内容中提取节点名称
  static List<String> _extractNodeNames(String mmd) {
    final names = <String>{};
    final nodeRe = RegExp(r'(\w+)\s*-->\s*(\w+)');
    for (final match in nodeRe.allMatches(mmd)) {
      final from = match.group(1)!;
      final to = match.group(2)!;
      if (from != '[*]') names.add(from);
      if (to != '[*]') names.add(to);
    }
    return names.toList()..sort();
  }
}
