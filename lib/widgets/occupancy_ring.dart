import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/widgets/apex_text.dart';

/// Animated circular occupancy gauge with ripple effect when >= 80%.
class OccupancyRing extends StatefulWidget {
  final double current;
  final int capacity;
  final bool compact;

  const OccupancyRing({
    super.key,
    required this.current,
    required this.capacity,
    this.compact = false,
  });

  @override
  State<OccupancyRing> createState() => _OccupancyRingState();
}

class _OccupancyRingState extends State<OccupancyRing>
    with TickerProviderStateMixin {
  late AnimationController _arcCtrl;
  late Animation<double> _arcAnim;
  late AnimationController _rippleCtrl;

  double get _pct =>
      widget.capacity > 0 ? (widget.current / widget.capacity * 100) : 0;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _arcAnim = Tween<double>(begin: 0, end: _pct / 100).animate(
      CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut),
    );
    _arcCtrl.forward();

    _rippleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant OccupancyRing old) {
    super.didUpdateWidget(old);
    _arcAnim = Tween<double>(begin: _arcAnim.value, end: _pct / 100).animate(
      CurvedAnimation(parent: _arcCtrl, curve: Curves.easeOut),
    );
    _arcCtrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  Color get _color => ocColor(_pct);
  String get _label => ocLabel(_pct);

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 100.0 : 160.0;
    final strokeW = widget.compact ? 8.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_arcAnim, _rippleCtrl]),
            builder: (_, __) => CustomPaint(
              painter: _RingPainter(
                progress: _arcAnim.value,
                color: _color,
                strokeWidth: strokeW,
                ripple: _pct >= 80 ? _rippleCtrl.value : null,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ApexText(
                      '${widget.current.round()}',
                      fontSize: widget.compact ? 20 : 30,
                      color: const Color(0xFFE8E8E8),
                      fontWeight: FontWeight.w700,
                    ),
                    ApexText(
                      '/ ${widget.capacity}',
                      fontSize: widget.compact ? 9 : 11,
                      color: const Color(0xFF555555),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: _color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            ApexText(
              '$_label · ${_pct.round()}%',
              fontSize: widget.compact ? 10 : 12,
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double? ripple;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.ripple,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Ripple effect
    if (ripple != null) {
      final ripplePaint = Paint()
        ..color = color.withOpacity((1 - ripple!) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * (1 + ripple! * 1.5);
      canvas.drawCircle(center, radius, ripplePaint);
    }

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Gradient arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2 * progress,
        colors: [color.withOpacity(0.7), color],
        tileMode: TileMode.clamp,
      ).createShader(
          Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.ripple != ripple;
}
