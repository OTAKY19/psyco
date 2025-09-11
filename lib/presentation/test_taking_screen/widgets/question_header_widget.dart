import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuestionHeaderWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String timeRemaining;
  final Color timerColor;
  final VoidCallback? onPause;
  final VoidCallback? onShowQuestionGrid;

  const QuestionHeaderWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.timeRemaining,
    required this.timerColor,
    this.onPause,
    this.onShowQuestionGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Pause Button
            IconButton(
              onPressed: onPause,
              icon: CustomIconWidget(
                iconName: 'pause',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              padding: EdgeInsets.all(2.w),
              constraints: BoxConstraints(
                minWidth: 10.w,
                minHeight: 5.h,
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  // Question Counter
                  Text(
                    'Question $currentQuestion sur $totalQuestions',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 0.5.h),

                  // Progress Bar
                  Container(
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: currentQuestion / totalQuestions,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Timer and Questions Button
            Column(
              children: [
                // Timer
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: timerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: timerColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'timer',
                        color: timerColor,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        timeRemaining,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: timerColor,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),

                // Questions Grid Button
                GestureDetector(
                  onTap: onShowQuestionGrid,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'grid_view',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Questions',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
