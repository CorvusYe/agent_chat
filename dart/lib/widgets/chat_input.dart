import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';

/// 自动调整高度的多行输入框。
class AutoResizeTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const AutoResizeTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<AutoResizeTextField> createState() => _AutoResizeTextFieldState();
}

class _AutoResizeTextFieldState extends State<AutoResizeTextField> {
  @override
  Widget build(BuildContext context) {
    final theme = ChatTheme.of(context);
    return TextField(
      controller: widget.controller,
      maxLines: null,
      minLines: 1,
      style: TextStyle(
        color: theme.textInput,
        fontSize: 14,
        height: 1.5,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        hintText: widget.hintText,
        hintStyle: TextStyle(color: theme.textPlaceholder),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      onChanged: widget.onChanged,
    );
  }
}
