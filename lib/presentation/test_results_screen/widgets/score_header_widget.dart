import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ScoreHeaderWidget extends StatelessWidget {
  final double scorePercentage;
  final String grade;
  final Color gradeColor;

  const ScoreHeaderWidget({
    Key? key,
    required this.scorePercentage,
    required this.grade,
    required this.gradeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradeColor.withValues(alpha: 0.1),
            gradeColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Résultat du Test',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${scorePercentage.toInt()}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: gradeColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: gradeColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              grade,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
