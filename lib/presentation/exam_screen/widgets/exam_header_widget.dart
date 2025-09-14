import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExamHeaderWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String timeRemaining;
  final Color timerColor;
  final String examType;
  final VoidCallback onShowQuestionGrid;

  const ExamHeaderWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.timeRemaining,
    required this.timerColor,
    required this.examType,
    required this.onShowQuestionGrid,
  });

  String _getExamTitle(String examType) {
    switch (examType) {
      case 'concours_douane':
        return 'Concours de la Douane';
      case 'concours_police':
        return 'Concours de Police';
      case 'concours_gendarmerie':
        return 'Concours de Gendarmerie';
      default:
        return 'Examen Officiel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = currentQuestion / totalQuestions;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exam title and timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getExamTitle(examType),
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Question $currentQuestion sur $totalQuestions',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: timerColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: timerColor,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      timeRemaining,
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: timerColor,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Progress bar
          Container(
            height: 1.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),

          SizedBox(height: 1.h),

          // Question grid button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShowQuestionGrid,
              icon: Icon(
                Icons.grid_view,
                size: 4.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              label: Text(
                'Voir toutes les questions',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
