import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gymsaas/core/theme.dart';

class LineChartSeries {
  final String label;
  final Color color;
  final List<double> values;

  const LineChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });
}

class LineChartWidget extends StatelessWidget {
  final List<String> xLabels;
  final List<LineChartSeries> series;

  const LineChartWidget({
    super.key,
    required this.xLabels,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFF1A1A1A),
              strokeWidth: 0.8,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= xLabels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      xLabels[idx],
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontSize: 9,
                        fontFamily: 'DM Sans',
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 20,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 9,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: series.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            return LineChartBarData(
              spots: s.values.asMap().entries.map((spot) {
                return FlSpot(spot.key.toDouble(), spot.value);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              color: s.color,
              barWidth: 2.2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: s.color,
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: s.color.withValues(alpha: 0.12),
              ),
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((spot) {
                final s = series[spot.barIndex];
                return LineTooltipItem(
                  '${s.label}: ${spot.y.toStringAsFixed(1)}',
                  TextStyle(
                    color: s.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}