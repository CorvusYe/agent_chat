import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../bus/chat_bus.dart';

/// 队列弹窗 — 显示等待发送的消息列表。
class QueuePopup extends StatelessWidget {
  final ChatBus bus;

  const QueuePopup({super.key, required this.bus});

  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    final items = bus.queueItems;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.bgPopup,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Text(
                  '待发送消息',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textContent,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => bus.toggleQueue(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.borderLight),
          // 列表
          Flexible(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '待发送队列为空',
                      style: TextStyle(fontSize: 12, color: theme.textTertiary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.borderLight),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.bgHover,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              items[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
