import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  //  Input Padding — Fluent 2 4px grid spacing tokens
  // ═══════════════════════════════════════════════════════

  group('Input Padding', () {
    testWidgets('outer Container uses Fluent 2 spacing tokens (12,4,12,4)',
        (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      expect(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.padding == const EdgeInsets.fromLTRB(12, 4, 12, 4)),
        findsOneWidget,
      );
    });

    testWidgets('contentPadding is LTRB(4, 8, 4, 8)', (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.contentPadding,
          const EdgeInsets.fromLTRB(4, 8, 4, 8));
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Underline Border — enabled & focused highlight
  // ═══════════════════════════════════════════════════════

  group('Underline Border', () {
    testWidgets('enabled underline is 1px theme.border (0xFF484848)',
        (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      final border = tf.decoration?.enabledBorder;
      expect(border, isA<InputBorder>());
      expect(border!.borderSide.color, const Color(0xFF484848));
      expect(border.borderSide.width, 1.0);
    });

    testWidgets('focused underline uses same borderSide, accent via animation',
        (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      final border = tf.decoration?.focusedBorder;
      expect(border, isA<InputBorder>());
      // base line color matches enabled state; accent color appears
      // through the animated gradient in _AccentUnderlineBorder.paint
      expect(border!.borderSide.color, const Color(0xFF484848));
      expect(border.borderSide.width, 1.0);
    });
  });

  // ═══════════════════════════════════════════════════════
  //  Placeholder Style
  // ═══════════════════════════════════════════════════════

  group('Placeholder Style', () {
    testWidgets('hint text uses fluentDark textPlaceholder (0xFF5c5c5c)',
        (tester) async {
      final bus = DefaultChatBus();
      await tester.pumpWidget(MaterialApp(home: ChatScreen(bus: bus)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.hintText, '输入消息…');
      expect(tf.decoration?.hintStyle?.color, const Color(0xFF5c5c5c));
    });
  });
}
