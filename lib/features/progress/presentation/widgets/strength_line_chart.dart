import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/progress_series.dart';

/// Line chart of estimated 1RM over time for one exercise.
class StrengthLineChart extends StatelessWidget {
  const StrengthLineChart({super.key, required this.points});

  final List<StrengthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const _NotEnough(text: 'Нужно минимум 2 тренировки для графика силы.');
    }

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].e1rm),
    ];
    final maxY = points.map((p) => p.e1rm).reduce((a, b) => a > b ? a : b);
    final minY = points.map((p) => p.e1rm).reduce((a, b) => a < b ? a : b);
    final pad = ((maxY - minY) * 0.2).clamp(2.0, 20.0);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0.0, double.infinity),
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withOpacity(0.06), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Color(0xFF6C6C7A), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) =>
                    _bottomLabel(value.toInt()),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: AppColors.primaryBright,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.accent,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.30),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomLabel(int index) {
    // Show a handful of evenly spaced date labels only.
    final step = (points.length / 4).ceil().clamp(1, points.length);
    if (index < 0 || index >= points.length || index % step != 0) {
      return const SizedBox.shrink();
    }
    final d = points[index].date;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '${d.day}.${d.month}',
        style: const TextStyle(color: Color(0xFF6C6C7A), fontSize: 10),
      ),
    );
  }
}

class _NotEnough extends StatelessWidget {
  const _NotEnough({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
