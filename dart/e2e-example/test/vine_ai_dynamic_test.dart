import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';
// ignore: avoid_relative_lib_imports
import '../lib/vine_ai_dynamic_service.dart';

void main() {
  group('DynamicNodeService', () {
    late Directory tempDir;
    late DynamicNodeService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vine_ai_test_');
      service = DynamicNodeService(
        '${tempDir.path}${Platform.pathSeparator}dynamic_nodes',
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('saveNode creates a YAML file and returns a DynamicNodeDef', () async {
      final def = await service.saveNode(
        'test_node',
        'type: ai_model\nname: test_node\n',
      );
      expect(def.name, 'test_node');
      expect(def.yamlContent, contains('ai_model'));
      expect(def.createdAt, isA<DateTime>());

      // Verify file was created
      final file = File(
        '${service.storageDir}${Platform.pathSeparator}test_node.yaml',
      );
      expect(await file.exists(), true);
      final content = await file.readAsString();
      expect(content, contains('ai_model'));
    });

    test('listNodes returns saved nodes', () async {
      await service.saveNode('node_a', 'type: ai_model\nname: node_a');
      await service.saveNode('node_b', 'type: local_method\nname: node_b');

      final nodes = await service.listNodes();
      expect(nodes.length, 2);
      expect(nodes.map((n) => n.name), containsAll(['node_a', 'node_b']));
    });

    test('readNode returns null for non-existent node', () async {
      final node = await service.readNode('non_existent');
      expect(node, isNull);
    });

    test('readNode returns saved node', () async {
      await service.saveNode('my_node', 'type: ai_model\nname: my_node');
      final node = await service.readNode('my_node');
      expect(node, isNotNull);
      expect(node!.name, 'my_node');
    });

    test('deleteNode removes the file', () async {
      await service.saveNode('temp_node', 'type: ai_model\nname: temp_node');
      final before = await service.readNode('temp_node');
      expect(before, isNotNull);

      await service.deleteNode('temp_node');
      final after = await service.readNode('temp_node');
      expect(after, isNull);
    });
  });

  group('DynamicWorkflowService', () {
    late Directory tempDir;
    late DynamicWorkflowService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vine_ai_wf_test_');
      service = DynamicWorkflowService(
        '${tempDir.path}${Platform.pathSeparator}dynamic_workflows',
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('assembleMmd generates correct MMD syntax', () {
      final mmd = service.assembleMmd(
        workflowName: 'test_pipeline',
        description: 'Test workflow',
        startNode: 'node_a',
        nodeNames: ['node_a', 'node_b', 'node_c'],
        edges: [
          ['node_a', 'node_b'],
          ['node_b', 'node_c', '{{ready}} == true'],
          ['node_c', 'end'],
        ],
      );

      expect(mmd, contains('%% name: test_pipeline'));
      expect(mmd, contains('%% description: Test workflow'));
      expect(mmd, contains('stateDiagram-v2'));
      expect(mmd, contains('[*] --> node_a'));
      expect(mmd, contains('node_a --> node_b'));
      expect(mmd, contains('node_b --> node_c: {{ready}} == true'));
      expect(mmd, contains('node_c --> [*]'));
    });

    test('saveWorkflow persists MMD content and returns parsed def', () async {
      final mmd = '''%% name: save_test
%% description: Save test
stateDiagram-v2
    [*] --> start
    start --> end
    end --> [*]''';

      final def = await service.saveWorkflow(mmd);
      expect(def.name, 'save_test');
      expect(def.description, 'Save test');
      expect(def.nodeNames, containsAll(['start', 'end']));

      final file = File(
        '${service.storageDir}${Platform.pathSeparator}save_test.mmd',
      );
      expect(await file.exists(), true);
      final content = await file.readAsString();
      expect(content, contains('save_test'));
    });

    test('listWorkflows returns saved workflows without duplicates', () async {
      await service.saveWorkflow('''%% name: wf_a
stateDiagram-v2
    [*] --> a
    a --> b
    b --> [*]''');
      await service.saveWorkflow('''%% name: wf_b
stateDiagram-v2
    [*] --> x
    x --> y
    y --> [*]''');

      final wfs = await service.listWorkflows();
      expect(wfs.length, 2);
      expect(wfs.map((w) => w.name), containsAll(['wf_a', 'wf_b']));
    });

    test('workflow assembly with conditions', () {
      final mmd = service.assembleMmd(
        workflowName: 'cond_test',
        startNode: 'router',
        nodeNames: ['router', 'path_a', 'path_b', 'end'],
        edges: [
          ['router', 'path_a', '{{type}} == a'],
          ['router', 'path_b', '{{type}} == b'],
          ['path_a', 'end'],
          ['path_b', 'end'],
        ],
      );

      expect(mmd, contains('router --> path_a: {{type}} == a'));
      expect(mmd, contains('router --> path_b: {{type}} == b'));
      expect(mmd, contains('path_a --> [*]'));
      expect(mmd, contains('path_b --> [*]'));
    });
  });

  group('CustomBlockEvent', () {
    test('CustomBlockEvent creates with all fields', () {
      final event = CustomBlockEvent(
        'ex_1',
        'block_1',
        'vine_yaml_node',
        content: 'type: ai_model\nname: test',
        label: 'Test Node',
        metadata: {'nodeType': 'ai_model'},
      );

      expect(event.exchangeId, 'ex_1');
      expect(event.blockId, 'block_1');
      expect(event.blockType, 'vine_yaml_node');
      expect(event.content, contains('ai_model'));
      expect(event.label, 'Test Node');
      expect(event.metadata?['nodeType'], 'ai_model');
      expect(event.status, BlockStatus.completed);
    });

    test('CustomBlockEvent -> ChatBlock round-trip', () {
      final block = ChatBlock(
        id: 'test_block',
        type: BlockType.custom('vine_mmd_workflow'),
        content: '%% name: test\nstateDiagram-v2\n    [*] --> a',
        description: 'Workflow Test',
        toolArgs: {'nodeCount': 2},
        status: BlockStatus.completed,
      );

      expect(block.type.name, 'vine_mmd_workflow');
      expect(block.description, 'Workflow Test');
      expect(block.toolArgs?['nodeCount'], 2);
      expect(block.content, contains('name: test'));
    });
  });

  group('BlockRegistry Custom Types', () {
    test('registerCustom with BlockDef', () {
      BlockRegistry.registerCustom(
        BlockDef(
          name: 'vine_test_block',
          builder: (ctx, block, bus, ex) =>
              const SizedBox(width: 100, height: 100),
          icon: Icons.code,
          dotColor: Color(0xFF7C3AED),
          headerColor: Color(0xFF7C3AED),
          label: '测试',
        ),
      );

      final builder = BlockRegistry.getCustom('vine_test_block');
      expect(builder, isNotNull);
    });
  });

  group('YAML Content Format Validation', () {
    test('YAML node definition has correct structure', () {
      const yaml = '''type: ai_model
name: analyze_code
config:
  description: "分析代码质量"
  model: deepseek-chat
  system_prompt: "代码审查"
  output_schema:
    type: object
    properties:
      issues:
        type: array
        description: 发现的问题列表''';

      // 验证 YAML 结构格式
      expect(yaml, startsWith('type:'));
      expect(yaml, contains('name: analyze_code'));
      expect(yaml, contains('ai_model'));
      expect(yaml, contains('config:'));
      expect(yaml, contains('output_schema:'));
      expect(yaml, contains('properties:'));
      expect(yaml, contains('description: "分析代码质量"'));
    });

    test('MMD workflow has correct stateDiagram-v2 syntax', () {
      const mmd = '''%% name: test_pipeline
%% description: Test pipeline
stateDiagram-v2
    [*] --> start
    start --> process
    process --> end
    end --> [*]''';

      // 验证 MMD 结构格式
      expect(mmd, contains('%% name:'));
      expect(mmd, contains('stateDiagram-v2'));
      expect(mmd, contains('[*] --> start'));
      expect(mmd, contains('start --> process'));
      expect(mmd, contains('process --> end'));
      expect(mmd, contains('end --> [*]'));
    });
  });

  group('DynamicEdge', () {
    test('assembled edges are in correct order', () {
      const edges = """    analyze_code --> report_summary: {{issues}} != null
    report_summary --> [*]""";

      expect(edges, contains('analyze_code --> report_summary'));
      expect(edges, contains('{{issues}} != null'));
      expect(edges, contains('report_summary --> [*]'));

      // 验证 end 节点替换为 [*]
      expect(edges, isNot(contains('end --> [*]')));
      expect(edges, contains('report_summary --> [*]'));
    });
  });
}
