import 'package:flutter/material.dart';
import 'package:gymsaas/core/theme.dart';

/// Predefined hourly crowd data — index 0 = midnight.
const List<double> kHourlyData = [
  0.05, 0.02, 0.01, 0.01, 0.02, 0.05,
  0.12, 0.28, 0.55, 0.72, 0.68, 0.60,
  0.45, 0.38, 0.42, 0.58, 0.78, 0.92,
  0.85, 0.70, 0.55, 0.38, 0.22, 0.10,
];

/// 24-bar horizontal crowd chart with current-hour gold highlight.
class HourlyChart extends StatelessWidget {
  const HourlyChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _HourlyPainter(
          data: kHourlyData,
          currentHour: DateTime.now().hour,
        ),
      ),
    );
  }
}

class _HourlyPainter extends CustomPainter {
  final List<double> data;
  final int currentHour;

  const _HourlyPainter({required this.data, required this.currentHour});

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 24;
    final gap = size.width * 0.008;
    final barW = (size.width - gap * (barCount - 1)) / barCount;
    final maxH = size.height * 0.85;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barW + gap);
      final barH = (data[i] * maxH).clamp(3.0, maxH);
      final y = size.height - barH;

      final isNow = i == currentHour;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, barH),
        const Radius.circular(3),
      );

      if (isNow) {
        // Gold gradient bar
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [goldLight, gold],
          ).createShader(Rect.fromLTWH(x, y, barW, barH))
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, paint);
        // Border
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      } else {
        final intensity = 0.3 + data[i] * 0.4;
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Color.lerp(
              const Color(0xFF1A1A1A),
              const Color(0xFF3A3A3A),
              intensity,
            )!
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyPainter old) =>
      old.currentHour != currentHour;
}
