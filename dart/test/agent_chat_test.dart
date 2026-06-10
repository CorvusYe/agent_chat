import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

void main() {
  test('BlockType equality', () {
    expect(BlockType.thinking, BlockType.thinking);
    expect(BlockType.tool, BlockType.tool);
    expect(BlockType.content, BlockType.content);
    expect(BlockType.confirmation, BlockType.confirmation);
    expect(BlockType.custom('foo'), BlockType.custom('foo'));
    expect(BlockType.custom('foo') == BlockType.custom('bar'), false);
  });

  test('ChatBlock copyWith', () {
    final block = ChatBlock(
      id: '1',
      type: BlockType.thinking,
      status: BlockStatus.pending,
    );
    final updated = block.copyWith(status: BlockStatus.completed);
    expect(updated.status, BlockStatus.completed);
    expect(updated.id, '1');
  });

  test('Exchange copyWith', () {
    final ex = Exchange(
      id: '1',
      userMessage: 'hello',
      timestamp: DateTime.now(),
    );
    final updated = ex.copyWith(status: ExchangeStatus.completed);
    expect(updated.status, ExchangeStatus.completed);
    expect(updated.userMessage, 'hello');
  });
}
