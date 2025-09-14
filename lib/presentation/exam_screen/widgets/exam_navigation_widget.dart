import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExamNavigationWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;
  final bool canGoPrevious;

  const ExamNavigationWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
    required this.canGoPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final isLastQuestion = currentQuestion == totalQuestions;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canGoPrevious ? onPrevious : null,
              icon: Icon(
                Icons.arrow_back,
                size: 4.w,
              ),
              label: Text('Précédent'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: canGoPrevious
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
                foregroundColor: canGoPrevious
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),

          SizedBox(width: 4.w),

          // Progress Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currentQuestion/$totalQuestions',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(width: 4.w),

          // Next/Submit Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(
                isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                size: 4.w,
              ),
              label: Text(isLastQuestion ? 'Terminer' : 'Suivant'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: isLastQuestion
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
