import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CategoryPerformanceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categoryData;

  const CategoryPerformanceWidget({
    super.key,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
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
          Text(
            'Performance par catégorie',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            height: 30.h,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.2),
                    borderColor: AppTheme.lightTheme.colorScheme.primary,
                    entryRadius: 3,
                    dataEntries: categoryData.map((category) {
                      return RadarEntry(value: (category['score'] as double));
                    }).toList(),
                    borderWidth: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle:
                    AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                getTitle: (index, angle) {
                  if (index < categoryData.length) {
                    return RadarChartTitle(
                      text: categoryData[index]['category'] as String,
                      angle: angle,
                    );
                  }
                  return const RadarChartTitle(text: '');
                },
                tickCount: 5,
                ticksTextStyle:
                    AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                tickBorderData: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
                gridBorderData: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            children: categoryData.map((category) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${category['category']}: ${category['score'].toInt()}%',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color:
                            AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700, // Plus gras
                        fontSize: 12.sp, // Plus grand
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
