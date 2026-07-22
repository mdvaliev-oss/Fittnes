import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/progress_series.dart';

/// Bar chart of per-session tonnage (last N sessions).
class TonnageBarChart extends StatelessWidget {
  const TonnageBarChart({super.key, required this.points, this.maxBars = 10});

  final List<TonnagePoint> points;
  final int maxBars;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Нет данных о тоннаже.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final shown = points.length > maxBars
        ? points.sublist(points.length - maxBars)
        : points;
    final maxY = shown.map((p) => p.tonnage).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value >= 1000
                      ? '${(value / 1000).toStringAsFixed(1)}т'
                      : value.toStringAsFixed(0),
                  style:
                      const TextStyle(color: Color(0xFF6C6C7A), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= shown.length) {
                    return const SizedBox.shrink();
                  }
                  final d = shown[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}.${d.month}',
                      style: const TextStyle(
                        color: Color(0xFF6C6C7A),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < shown.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: shown[i].tonnage,
                    width: 14,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.primary, AppColors.primaryBright],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
