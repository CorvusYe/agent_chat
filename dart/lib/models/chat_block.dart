class BlockType {
  final String name;
  const BlockType._(this.name);

  static const thinking = BlockType._('thinking');
  static const tool = BlockType._('tool');
  static const content = BlockType._('content');
  static const confirmation = BlockType._('confirmation');

  BlockType.custom(this.name) : assert(name.isNotEmpty);

  @override
  bool operator ==(Object other) => other is BlockType && other.name == name;
  @override
  int get hashCode => name.hashCode;
  @override
  String toString() => 'BlockType($name)';
}

enum BlockStatus { pending, running, approved, cancelled, completed, error }

class ChatBlock {
  final String id;
  final BlockType type;
  final String? content;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? toolResult;
  final String? description;
  final bool requiresConfirm;
  final bool canAlwaysAllow;
  final BlockStatus status;

  const ChatBlock({
    required this.id,
    required this.type,
    this.content,
    this.toolName,
    this.toolArgs,
    this.toolResult,
    this.description,
    this.requiresConfirm = false,
    this.canAlwaysAllow = true,
    this.status = BlockStatus.pending,
  });

  ChatBlock copyWith({
    String? content,
    String? toolResult,
    BlockStatus? status,
    Map<String, dynamic>? toolArgs,
  }) {
    return ChatBlock(
      id: id,
      type: type,
      content: content ?? this.content,
      toolName: toolName,
      toolArgs: toolArgs ?? this.toolArgs,
      toolResult: toolResult ?? this.toolResult,
      description: description,
      requiresConfirm: requiresConfirm,
      canAlwaysAllow: canAlwaysAllow,
      status: status ?? this.status,
    );
  }

  ChatBlock withStatus(BlockStatus newStatus) => copyWith(status: newStatus);
}

class BlockGroup {
  final String id;
  final List<ChatBlock> blocks;

  const BlockGroup({required this.id, required this.blocks});

  BlockGroup copyWith({List<ChatBlock>? blocks}) =>
      BlockGroup(id: id, blocks: blocks ?? this.blocks);
}
