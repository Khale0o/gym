import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/widgets/apex_text.dart';

/// Circular occupancy gauge built from standard Flutter widgets.
class OccupancyRing extends StatelessWidget {
  final double current;
  final int capacity;
  final bool compact;

  const OccupancyRing({
    super.key,
    required this.current,
    required this.capacity,
    this.compact = false,
  });

  double get _safeCurrent => _safeDouble(current);
  int get _safeCapacity => capacity < 0 ? 0 : capacity;
  double get _progress => _safeProgress(_safeCurrent, _safeCapacity);
  double get _pct => _progress * 100;

  static double _safeDouble(double value) {
    if (!value.isFinite || value < 0) return 0;
    return value;
  }

  static double _safeProgress(double current, int capacity) {
    if (!current.isFinite || current < 0 || capacity <= 0) return 0;

    final progress = current / capacity;
    if (!progress.isFinite || progress < 0) return 0;

    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = compact ? 100.0 : 160.0;
    final strokeWidth = compact ? 8.0 : 12.0;
    final color = ocColor(_pct);
    final label = ocLabel(_pct);
    final displayCurrent = _safeCurrent.round();
    final displayCapacity = _safeCapacity;
    final displayPercent = _pct.round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: strokeWidth,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1A1A1A),
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  builder: (_, value, __) => CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: strokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ApexText(
                    '$displayCurrent',
                    fontSize: compact ? 20 : 30,
                    color: const Color(0xFFE8E8E8),
                    fontWeight: FontWeight.w700,
                  ),
                  ApexText(
                    '/ $displayCapacity',
                    fontSize: compact ? 9 : 11,
                    color: const Color(0xFF555555),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            ApexText(
              '$label - $displayPercent%',
              fontSize: compact ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ],
    );
  }
}
