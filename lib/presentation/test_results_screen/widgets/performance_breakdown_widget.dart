import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PerformanceBreakdownWidget extends StatelessWidget {
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedAnswers;
  final int totalQuestions;

  const PerformanceBreakdownWidget({
    super.key,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
            'Répartition des Réponses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownItem(
                  context,
                  'Correctes',
                  correctAnswers,
                  totalQuestions,
                  AppTheme.successLight,
                  'check_circle',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildBreakdownItem(
                  context,
                  'Incorrectes',
                  incorrectAnswers,
                  totalQuestions,
                  AppTheme.errorLight,
                  'cancel',
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildBreakdownItem(
                  context,
                  'Ignorées',
                  skippedAnswers,
                  totalQuestions,
                  AppTheme.warningLight,
                  'help_outline',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
    String iconName,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
