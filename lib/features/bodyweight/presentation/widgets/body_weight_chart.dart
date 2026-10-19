import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/settings/app_settings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/units/weight_format.dart';
import '../../domain/entities/body_weight_entry.dart';

/// Line chart of body weight over time, rendered in the user's unit.
class BodyWeightChart extends StatelessWidget {
  const BodyWeightChart({
    super.key,
    required this.points,
    required this.unit,
    this.height = 180,
  });

  /// Oldest first (see `bodyWeightChartPoints`).
  final List<BodyWeightEntry> points;
  final WeightUnit unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Запиши вес хотя бы два раза — появится график.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final values = points.map((p) => unit.fromKg(p.kg)).toList();
    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final pad = ((maxY - minY) * 0.3).clamp(1.0, 10.0);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceHigh,
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    '${formatWeight(points[t.spotIndex].kg, unit)}\n'
                    '${_date(points[t.spotIndex].measuredAt)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ],
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(unit == WeightUnit.lb ? 0 : 1),
                  style:
                      const TextStyle(color: Color(0xFF6C6C7A), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) => _bottomLabel(value.toInt()),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: AppColors.accent,
              barWidth: 3,
              dotData: FlDotData(
                show: points.length <= 30,
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
                    AppColors.accent.withValues(alpha: 0.25),
                    AppColors.accent.withValues(alpha: 0.0),
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
    final step = (points.length / 4).ceil().clamp(1, points.length);
    if (index < 0 || index >= points.length || index % step != 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        _date(points[index].measuredAt),
        style: const TextStyle(color: Color(0xFF6C6C7A), fontSize: 10),
      ),
    );
  }

  static String _date(DateTime d) => '${d.day}.${d.month}';
}
