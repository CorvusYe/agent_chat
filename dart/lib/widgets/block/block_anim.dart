import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/chat_block.dart';
import '../../theme/chat_theme.dart';

/// 旋转环圆点 — 用于 running 状态的 block 和 thinking 占位符。
///
/// 绘制一个 2.5px 宽的渐变圆弧，围绕圆心旋转。
class RunningDotPainter extends CustomPainter {
  final Color color;
  final double rotation;

  RunningDotPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 基础圆环（微光）— 提示圆的位置
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius, bgPaint);

    // 用画布旋转代替改角度，避免 SweepGradient 在 0° wrap 跳变
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * pi);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // 无缝全圆渐变：左侧带头不透明 → 顺时针渐隐到右侧透明 → 左侧不透明收尾
    paint.shader = SweepGradient(
      startAngle: -pi,
      endAngle: pi,
      colors: [
        color.withValues(alpha: 1.0),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 1.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(RunningDotPainter old) => old.rotation != rotation;
}

/// Animation values exposed by [BlockAnimController] during a block's running state.
class AnimValues {
  final bool isActive;
  final double breathingValue;
  final double rotationValue;

  const AnimValues({
    this.isActive = false,
    this.breathingValue = 0.0,
    this.rotationValue = 0.0,
  });

  Color applyBreathing(Color base) =>
      isActive ? base.withValues(alpha: 0.5 + 0.5 * breathingValue) : base;
}

/// Hosts breathing + rotation animations for a running block.
///
/// Calls [builder] on every animation tick so the parent can render
/// animated colors/shapes. The animation repeats until the block
/// transitions out of running/pending status.
class BlockAnimController extends StatefulWidget {
  final ChatBlock block;
  final Widget Function(BuildContext context, AnimValues anim) builder;

  const BlockAnimController({
    super.key,
    required this.block,
    required this.builder,
  });

  @override
  State<BlockAnimController> createState() => _BlockAnimControllerState();
}

class _BlockAnimControllerState extends State<BlockAnimController>
    with TickerProviderStateMixin {
  AnimationController? _breathingCtrl;
  AnimationController? _rotationCtrl;

  bool get _isRunning =>
      widget.block.status == BlockStatus.running ||
      widget.block.status == BlockStatus.pending;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAnimations();
  }

  @override
  void didUpdateWidget(BlockAnimController old) {
    super.didUpdateWidget(old);
    if (widget.block.status != old.block.status) {
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _breathingCtrl?.dispose();
    _rotationCtrl?.dispose();
    super.dispose();
  }

  void _initAnimations() {
    if (_isRunning && _breathingCtrl == null) {
      final theme = ChatTheme.of(context);
      _breathingCtrl = AnimationController(
        vsync: this,
        duration: theme.breathingDuration,
      );
      _breathingCtrl!.addListener(() {
        if (mounted) setState(() {});
      });
      _breathingCtrl!.repeat(reverse: true);

      _rotationCtrl = AnimationController(
        vsync: this,
        duration: theme.rotationDuration,
      );
      _rotationCtrl!.addListener(() {
        if (mounted) setState(() {});
      });
      _rotationCtrl!.repeat();
    } else if (!_isRunning && _breathingCtrl != null) {
      _breathingCtrl?.dispose();
      _breathingCtrl = null;
      _rotationCtrl?.dispose();
      _rotationCtrl = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      AnimValues(
        isActive: _isRunning && _breathingCtrl != null,
        breathingValue: _breathingCtrl?.value ?? 0.0,
        rotationValue: _rotationCtrl?.value ?? 0.0,
      ),
    );
  }
}
