// Agent Chat × Vine AI — 基于 vine_ai 的动态工作流用例
//
// 启动时从 vine_ai_data/ 加载 YAML/MMD 文件，注册到 WorkflowRegistry。
// 用户消息 → LLM 评估现有工作流 → 匹配则选工作流，不匹配则动态创建。
// 动态创建的工作流只能使用已注册的 local_method 节点。
// 运行：cd dart/example && flutter run --dart-define-from-file=.env.test -t lib/main_vine_ai.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:agent_chat/agent_chat.dart';
import 'package:vine_ai/vine_ai.dart' as vine;
import 'vine_ai_dynamic_service.dart';

const String apiKey = String.fromEnvironment('API_KEY', defaultValue: '');
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.deepseek.com',
);
const String modelId = String.fromEnvironment(
  'API_MODEL_ID',
  defaultValue: 'deepseek-v4-flash',
);
final bool hasRealKey = apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY';

void main() {
  BlockRegistry.registerCustom(BlockDef(
    name: 'vine_yaml_node',
    builder: _yamlBlock,
    icon: Icons.code,
    dotColor: Color(0xFF7C3AED),
    headerColor: Color(0xFF7C3AED),
    label: 'YAML 节点',
  ));
  BlockRegistry.registerCustom(BlockDef(
    name: 'vine_mmd_workflow',
    builder: _mmdBlock,
    icon: Icons.account_tree,
    dotColor: Color(0xFF0EA5E9),
    headerColor: Color(0xFF0EA5E9),
    label: '工作流',
  ));
  runApp(const _App());
}

class _App extends StatefulWidget {
  const _App({super.key});
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  late final ChatBus bus;
  late final vine.WorkflowRegistry registry;
  late final vine.LlmClient llmClient;
  late final DynamicNodeService nodeService;
  late final DynamicWorkflowService wfService;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final dataDir =
        '${Directory.current.path}${Platform.pathSeparator}vine_ai_data';
    final nodesDir = '$dataDir${Platform.pathSeparator}dynamic_nodes';
    final wfsDir = '$dataDir${Platform.pathSeparator}dynamic_workflows';

    nodeService = DynamicNodeService(nodesDir);
    wfService = DynamicWorkflowService(wfsDir);
    registry = vine.WorkflowRegistry();
    llmClient = hasRealKey
        ? vine.OpenAIClientAdapter(apiKey: apiKey, baseUrl: baseUrl)
        : _MockLlmClient();

    bus = DefaultChatBus(
      onGenerate: _onUserMessage,
      onInterrupt: () => _cancelled = true,
    );

    // 异步加载 fixture / YAML/MMD
    _init(nodesDir, wfsDir);
  }

  Future<void> _init(String nodesDir, String wfsDir) async {
    await DynamicNodeService.ensureFixtures(nodesDir, wfsDir);
    _loadAll(nodesDir, wfsDir);
    _ready = true;
  }

  void _loadAll(String nodesDir, String wfsDir) {
    final nd = Directory(nodesDir);
    if (nd.existsSync()) {
      for (final f in nd.listSync().whereType<File>()) {
        if (!f.path.endsWith('.yaml') && !f.path.endsWith('.yml')) continue;
        final content = f.readAsStringSync();
        final result = vine.YamlParser.parseAll([content]);
        for (final n in result.nodes) registry.registerNode(n);
      }
    }
    final wd = Directory(wfsDir);
    if (wd.existsSync()) {
      for (final f in wd.listSync().whereType<File>()) {
        if (!f.path.endsWith('.mmd')) continue;
        final wf = vine.MermaidParser.parse(f.readAsStringSync());
        if (wf != null) registry.registerDefinition(wf);
      }
    }
  }

  @override
  void dispose() {
    bus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Agent Chat × Vine AI',
    theme: ThemeData(
      brightness: Brightness.dark,
      colorSchemeSeed: const Color(0xFF6C63FF),
    ),
    home: Scaffold(
      key: const ValueKey('vine_ai_scaffold'),
      appBar: AppBar(title: const Text('Vine AI 动态工作流')),
      body: ChatScreen(bus: bus),
    ),
  );

  // ─── 用户消息处理 ──────────────────────────────────

  bool _cancelled = false;

  Stream<ExchangeEvent> _onUserMessage(String userMsg) async* {
    _cancelled = false;
    final id = 'ex_${DateTime.now().millisecondsSinceEpoch}';

    yield ThinkingStarted(id, 'think');

    // 1. 从 registry 构建 tool 列表（每个工作流是一个 tool）
    final tools = registry.allWorkflows
        .map(
          (wf) => vine.ToolDefinition(
            function: vine.FunctionDefinition(
              name: wf.name,
              description: wf.description ?? wf.name,
              parameters: {
                'type': 'object',
                'properties': {},
                'required': <String>[],
              },
            ),
          ),
        )
        .toList();

    final localMethods = registry.allNodes
        .where((n) => n.type == 'local_method')
        .map((n) => n.name)
        .join(', ');

    final systemPrompt = StringBuffer()
      ..writeln('你是 Vine AI 工作流引擎的调度器。分析用户需求，选择最合适的工作流来执行。')
      ..writeln('已注册的 local_method 节点: $localMethods')
      ..writeln('已注册的工作流:')
      ..writeln(
        registry.allWorkflows
            .map((w) => '  - ${w.name}: ${w.description ?? w.name}')
            .join('\n'),
      )
      ..writeln()
      ..writeln('规则：')
      ..writeln('1. 优先选择已有工作流直接满足用户需求。')
      ..writeln('2. create_workflow_pipeline 是元工作流，当已有工作流都不匹配时选择它。')
      ..writeln('3. 选择工作流后传入必要的参数。')
      ..writeln('4. 用户只是提问时直接回答，不要调任何工具。');

    var messages = <vine.ChatMessage>[
      vine.ChatMessage(
        role: vine.MessageRole.system,
        content: systemPrompt.toString(),
      ),
      vine.ChatMessage(role: vine.MessageRole.user, content: userMsg),
    ];

    // 2. 调用 LLM
    vine.ChatResponse resp;
    try {
      resp = await llmClient.chat(
        vine.ChatRequest(
          model: modelId,
          messages: messages,
          tools: tools,
          maxTokens: 4096,
          stream: true,
        ),
      );
    } catch (e) {
      yield ExchangeError(id, 'LLM 调用失败: $e');
      return;
    }
    if (_cancelled) return;

    // 3. 流式输出思考内容
    if (resp.contentStream != null) {
      var displayed = '';
      await for (final chunk in resp.contentStream!) {
        if (_cancelled) return;
        displayed += chunk;
        yield ThinkingDelta(id, 'think', displayed);
        await _delay(10);
      }
      yield ThinkingCompleted(id, 'think', displayed);
    } else if (resp.content != null && resp.content!.isNotEmpty) {
      yield ThinkingDelta(id, 'think', resp.content!);
      yield ThinkingCompleted(id, 'think', resp.content!);
    }

    // 4. 处理工具调用
    final tcs = resp.toolCalls;
    if (tcs != null && tcs.isNotEmpty) {
      for (final tc in tcs) {
        if (_cancelled) return;
        yield ParallelBoundary(id);
        yield ToolCallStarted(
          id,
          'wf_${tc.name}',
          tc.name,
          tc.arguments,
          description: '执行: ${tc.name}',
        );
        yield ToolCallCompleted(id, 'wf_${tc.name}', '✓ 工作流 ${tc.name} 已选择');
      }
    }

    // 5. 最终回答
    if (_cancelled) return;
    yield ParallelBoundary(id);

    final finalResp = await llmClient.chat(
      vine.ChatRequest(
        model: modelId,
        messages: [
          ...messages,
          if (resp.content != null)
            vine.ChatMessage(
              role: vine.MessageRole.assistant,
              content: resp.content ?? "",
            ),
          if (tcs != null && tcs.isNotEmpty)
            vine.ChatMessage(
              role: vine.MessageRole.user,
              content:
                  '已选择工作流: ${tcs.map((t) => t.name).join(", ")}。请根据用户需求说明执行计划。',
            ),
          vine.ChatMessage(role: vine.MessageRole.user, content: '请回答用户。'),
        ],
        maxTokens: 4096,
        stream: true,
      ),
    );
    final text = finalResp.content ?? '';
    if (_cancelled || text.isEmpty) return;

    if (finalResp.contentStream != null) {
      var displayed = '';
      await for (final chunk in finalResp.contentStream!) {
        if (_cancelled) return;
        displayed += chunk;
        yield ContentDelta(id, 'content', displayed);
        await _delay(8);
      }
      yield ContentCompleted(id, 'content', displayed);
    } else {
      yield ContentStarted(id, 'content');
      yield ContentDelta(id, 'content', text);
      yield ContentCompleted(id, 'content', text);
    }
    yield TokenCount(id, text.length);
  }

  Future<void> _delay(int ms) => Future.delayed(Duration(milliseconds: ms));
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MockLlmClient
// ═══════════════════════════════════════════════════════════════════════════════

class _MockLlmClient implements vine.LlmClient {
  final _rand = Random(42);

  @override
  Future<vine.ChatResponse> chat(vine.ChatRequest request) async {
    // 模拟网络延迟：首 token 延迟 300-800ms
    await Future.delayed(Duration(milliseconds: 300 + _rand.nextInt(500)));

    final sp = request.messages.where((m) => m.role == vine.MessageRole.system).map((m) => m.content).join('\n');
    final last = request.messages.last.content;

    String content;
    List<vine.ToolCall>? toolCalls;

    if (sp.contains('调度器')) {
      if (last.toLowerCase().contains('变换') || last.toLowerCase().contains('transform')) {
        content = '检测到文本变换需求，选择 transform_pipeline 工作流。';
        toolCalls = [vine.ToolCall(name: 'transform_pipeline', arguments: {})];
      } else if (last.toLowerCase().contains('保存') || last.toLowerCase().contains('日志')) {
        content = '检测到日志保存需求，选择 echo_pipeline 工作流。';
        toolCalls = [vine.ToolCall(name: 'echo_pipeline', arguments: {})];
      } else if (last.toLowerCase().contains('知识图谱') || last.toLowerCase().contains('工作流')) {
        content = '需要创建新工作流，选择 create_workflow_pipeline 元工作流。';
        toolCalls = [vine.ToolCall(name: 'create_workflow_pipeline', arguments: {})];
      } else {
        content = '您好，我是 Vine AI 助手。请问有什么可以帮您？';
      }
    } else {
      content = '处理完成。';
    }

    // 模拟流式分块返回 contentStream
    final chunks = <String>[];
    if (content.length <= 10) {
      chunks.add(content);
    } else {
      // 按词切分，模拟流式 chunk
      int i = 0;
      while (i < content.length) {
        final end = (i + _rand.nextInt(5) + 2).clamp(0, content.length);
        chunks.add(content.substring(i, end));
        i = end;
      }
    }

    return vine.ChatResponse(
      content: content,
      toolCalls: toolCalls,
      contentStream: Stream<String>.fromIterable(chunks),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  自定义 Block 渲染器
// ═══════════════════════════════════════════════════════════════════════════════

Widget _yamlBlock(BuildContext c, ChatBlock b, ChatBus bus, Exchange ex) {
  final t = ChatTheme.of(c);
  final dark = Theme.of(c).brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      color: t.bgCard,
      border: Border.all(color: t.borderLight),
      borderRadius: BorderRadius.circular(t.radiusMd),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacingMd,
            vertical: t.spacingXs + 2,
          ),
          color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFF0EEFF),
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: t.textToolHeader),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b.description ?? 'YAML',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: t.fontSizeMd,
                    color: t.textToolHeader,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(t.spacingMd),
          color: dark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA),
          child: SelectableText(
            b.content ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: t.fontSizeSm,
              height: 1.6,
              color: dark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _mmdBlock(BuildContext c, ChatBlock b, ChatBus bus, Exchange ex) {
  final t = ChatTheme.of(c);
  final dark = Theme.of(c).brightness == Brightness.dark;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 4),
    decoration: BoxDecoration(
      color: t.bgCard,
      border: Border.all(color: t.borderLight),
      borderRadius: BorderRadius.circular(t.radiusMd),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacingMd,
            vertical: t.spacingXs + 2,
          ),
          color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFF0EEFF),
          child: Row(
            children: [
              Icon(Icons.account_tree, size: 16, color: t.textToolHeader),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b.description ?? 'MMD',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: t.fontSizeMd,
                    color: t.textToolHeader,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(t.spacingMd),
          color: dark ? const Color(0xFF1E1E2E) : const Color(0xFFF8F9FA),
          child: SelectableText(
            b.content ?? '',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: t.fontSizeSm,
              height: 1.5,
              color: dark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ],
    ),
  );
}
