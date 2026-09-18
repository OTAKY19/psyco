import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class PerformanceChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> chartData;
  final String title;

  const PerformanceChartWidget({
    super.key,
    required this.chartData,
    required this.title,
  });

  @override
  State<PerformanceChartWidget> createState() => _PerformanceChartWidgetState();
}

class _PerformanceChartWidgetState extends State<PerformanceChartWidget> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Protection contre les listes vides
    final maxX = widget.chartData.isNotEmpty
        ? (widget.chartData.length - 1).toDouble()
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Icon(Icons.more_vert, color: AppTheme.lightTheme.colorScheme.onSurfaceVariant, size: AppSpacing.xl),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        // Vérification sécurisée des indices
                        if (idx >= 0 && idx < widget.chartData.length) {
                          final label =
                              (widget.chartData[idx]['label'] ?? '').toString();
                          return SideTitleWidget(
                            axisSide: meta
                                .axisSide, // Compatible avec fl_chart 0.69.0
                            child: Text(
                              label,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox
                            .shrink(); // Plus propre que Text('')
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 42,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide:
                              meta.axisSide, // Compatible avec fl_chart 0.69.0
                          child: Text(
                            '${value.toInt()}%',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                minX: 0,
                maxX: maxX,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.chartData.asMap().entries.map((entry) {
                      final x = entry.key.toDouble();
                      // Conversion sécurisée avec fallback
                      final y =
                          (entry.value['score'] as num?)?.toDouble() ?? 0.0;
                      return FlSpot(x, y);
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.secondary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (FlSpot spot, double percent,
                          LineChartBarData bar, int index) {
                        final isTouched = index == touchedIndex;
                        return FlDotCirclePainter(
                          radius: isTouched ? 6 : 4,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: AppTheme.lightTheme.colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.3),
                          AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback:
                      (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    setState(() {
                      if (touchResponse != null &&
                          touchResponse.lineBarSpots != null &&
                          touchResponse.lineBarSpots!.isNotEmpty) {
                        touchedIndex =
                            touchResponse.lineBarSpots!.first.spotIndex;
                      } else {
                        touchedIndex = -1;
                      }
                    });
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toInt()}%',
                          AppTheme.lightTheme.textTheme.bodyMedium!.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
