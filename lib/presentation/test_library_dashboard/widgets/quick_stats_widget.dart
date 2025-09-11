import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStatsWidget({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final testsCompleted = stats['testsCompleted'] as int;
    final averageScore = (stats['averageScore'] as num).toDouble();
    final studyStreak = stats['studyStreak'] as int;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos statistiques',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: 'check_circle',
                  value: testsCompleted.toString(),
                  label: 'Tests\nterminés',
                  color: AppTheme.successLight,
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: 'trending_up',
                  value: '${averageScore.toInt()}%',
                  label: 'Score\nmoyen',
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: 'local_fire_department',
                  value: studyStreak.toString(),
                  label: 'Jours\nconsécutifs',
                  color: AppTheme.warningLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomIconWidget(
            iconName: icon,
            color: color,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
