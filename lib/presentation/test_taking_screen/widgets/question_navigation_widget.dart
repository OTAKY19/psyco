import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuestionNavigationWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool isMarkedForReview;
  final VoidCallback? onToggleReview;
  final bool canGoNext;
  final bool canGoPrevious;

  const QuestionNavigationWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    this.onPrevious,
    this.onNext,
    required this.isMarkedForReview,
    this.onToggleReview,
    required this.canGoNext,
    required this.canGoPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark for Review Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onToggleReview,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isMarkedForReview
                          ? AppTheme.lightTheme.colorScheme.tertiary
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isMarkedForReview
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: isMarkedForReview
                              ? 'bookmark'
                              : 'bookmark_border',
                          color: isMarkedForReview
                              ? AppTheme.lightTheme.colorScheme.tertiary
                              : AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          isMarkedForReview
                              ? 'Marqué pour révision'
                              : 'Marquer pour révision',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: isMarkedForReview
                                ? AppTheme.lightTheme.colorScheme.tertiary
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: isMarkedForReview
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Navigation Buttons
            Row(
              children: [
                // Previous Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: canGoPrevious ? onPrevious : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canGoPrevious
                          ? AppTheme.lightTheme.colorScheme.surface
                          : AppTheme.lightTheme.colorScheme.surface
                              .withValues(alpha: 0.5),
                      foregroundColor: canGoPrevious
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                      elevation: canGoPrevious ? 1 : 0,
                      side: BorderSide(
                        color: canGoPrevious
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'arrow_back_ios',
                          color: canGoPrevious
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Précédent',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 4.w),

                // Next Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: canGoNext ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canGoNext
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      elevation: canGoNext ? 2 : 0,
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentQuestion == totalQuestions
                              ? 'Terminer'
                              : 'Suivant',
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        CustomIconWidget(
                          iconName: currentQuestion == totalQuestions
                              ? 'check'
                              : 'arrow_forward_ios',
                          color: Colors.white,
                          size: 18,
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
