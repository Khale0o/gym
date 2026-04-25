import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';

/// Mini 6-week weight sparkline. Turns red if last 3 values are equal (stalled).
class SparklineWidget extends StatelessWidget {
  final List<double> values;

  const SparklineWidget({super.key, required this.values});

  bool get _isStalled =>
      values.length >= 3 &&
      values[values.length - 1] == values[values.length - 2] &&
      values[values.length - 2] == values[values.length - 3];

  @override
  Widget build(BuildContext context) {
    final color = _isStalled ? redAlert : gold;
    return SizedBox(
      height: 36,
      child: CustomPaint(
        size: const Size(double.infinity, 36),
        painter: _SparkPainter(values: values, color: color),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs();

    List<Offset> pts = [];
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = range == 0
          ? size.height / 2
          : size.height - (values[i] - minV) / range * (size.height - 6) - 3;
      pts.add(Offset(x, y));
    }

    // Gradient fill
    final path = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(pts.last.dx, size.height);
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color;
}
