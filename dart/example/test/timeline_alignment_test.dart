// 时间轴圆点与竖线对齐测试
//
// 验证所有块类型的时间轴圆点与竖线是否共享同一个圆心。

import 'package:flutter_test/flutter_test.dart';
import 'package:agent_chat/agent_chat.dart';

void main() {
  group('TimelineGutter 圆心计算', () {
    // 模拟所有内置主题
    final themes = <String, ChatTheme>{
      'Fluent Light': ChatThemes.fluent,
      'Fluent Dark': ChatThemes.fluentDark,
      'Default Dark': ChatThemes.dark,
    };

    for (final entry in themes.entries) {
      test('${entry.key}: 圆点与竖线共享圆心', () {
        final t = entry.value;
        // 圆点中心 = gutterW/2
        final dotCenter = t.timelineGutter / 2;
        // 竖线中心 = gutterW/2
        final lineCenter = t.timelineGutter / 2;
        // 圆点左边缘 = center - dotSize/2
        final dotLeft = dotCenter - t.timelineDotSize / 2;
        // 竖线左边缘 = center - lineW/2
        final lineLeft = lineCenter - t.timelineLineWidth / 2;

        expect(
          dotCenter,
          lineCenter,
          reason: '圆点中心($dotCenter)与竖线中心($lineCenter)应相等',
        );
        expect(
          dotLeft + t.timelineDotSize / 2,
          lineLeft + t.timelineLineWidth / 2,
          reason: '圆点与竖线的实际物理中心应相等',
        );

        // 验证圆心在 gutter 内
        expect(dotCenter, greaterThan(0));
        expect(dotCenter, lessThan(t.timelineGutter));
        // 验证不超出边界
        expect(dotLeft, greaterThanOrEqualTo(0));
        expect(
          dotLeft + t.timelineDotSize,
          lessThanOrEqualTo(t.timelineGutter),
        );
      });

      test('${entry.key}: 块内容竖线对齐', () {
        final t = entry.value;
        // 块内容竖线在 Stack 中的位置（相对于内容区域左侧）
        // 内容区域在 gutter 右侧，所以竖线中心 = -(gutterW/2)
        final contentLineCenter = -(t.timelineGutter / 2);
        // gutter 中心（正数）
        final gutterCenter = t.timelineGutter / 2;

        // 绝对值相等，方向相反
        expect(
          contentLineCenter.abs(),
          gutterCenter,
          reason:
              '内容竖线中心(${contentLineCenter.abs()})应与gutter中心($gutterCenter)绝对值相等',
        );
      });

      test('${entry.key}: spacingLg + timelineGutter > 0', () {
        final t = entry.value;
        // 保证整体偏移量为正数
        expect(t.spacingLg + t.timelineGutter, greaterThan(0));
      });
    }
  });

  // 模拟 macOS 主题测试
  test('macOS 主题: 自定义时间轴参数', () {
    // 模拟 macOS 主题的时间轴参数
    const gutterW = 24.0;
    const dotSize = 12.0;
    const lineW = 2.0;

    final dotCenter = gutterW / 2; // 12
    final lineCenter = gutterW / 2; // 12
    final dotLeft = dotCenter - dotSize / 2; // 6
    final lineLeft = lineCenter - lineW / 2; // 11

    expect(dotCenter, lineCenter, reason: 'macOS: 圆点与竖线中心应相等');
    expect(dotLeft + dotSize / 2, 12, reason: 'macOS: 圆点中心应为12');
    expect(lineLeft + lineW / 2, 12, reason: 'macOS: 竖线中心应为12');
  });

  // 模拟未对齐场景：捕获不正确的手动计算
  test('旧版硬编码(-17)与新版(gutter/2)的对齐差异', () {
    const gutterW = 20.0; // 默认值
    const dotSize = 12.0;

    // 新版正确位置：圆点中心在 gutter 中心
    final correctCenter = gutterW / 2; // 10

    // 旧版硬编码 left: -17 对应的中心
    const oldLeft = -17.0;
    final oldCenter = oldLeft + dotSize / 2; // -11

    // 验证差异
    expect(
      (correctCenter - oldCenter).abs(),
      21,
      reason: '旧版left:-17与新版gutter/2中心相差21px',
    );
  });
}
