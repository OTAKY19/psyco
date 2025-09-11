import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuestionGridBottomSheet extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestion;
  final List<int> answeredQuestions;
  final List<int> markedQuestions;
  final Function(int) onQuestionTap;

  const QuestionGridBottomSheet({
    super.key,
    required this.totalQuestions,
    required this.currentQuestion,
    required this.answeredQuestions,
    required this.markedQuestions,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Text(
                  'Aperçu des Questions',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 2.h),

                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      label: 'Actuelle',
                      icon: 'radio_button_checked',
                    ),
                    _buildLegendItem(
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      label: 'Répondue',
                      icon: 'check_circle',
                    ),
                    _buildLegendItem(
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                      label: 'Marquée',
                      icon: 'bookmark',
                    ),
                    _buildLegendItem(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      label: 'Non vue',
                      icon: 'circle',
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            thickness: 1,
          ),

          // Questions Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: GridView.builder(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.w,
                  childAspectRatio: 1,
                ),
                itemCount: totalQuestions,
                itemBuilder: (context, index) {
                  final questionNumber = index + 1;
                  final isCurrentQuestion = questionNumber == currentQuestion;
                  final isAnswered = answeredQuestions.contains(questionNumber);
                  final isMarked = markedQuestions.contains(questionNumber);

                  Color backgroundColor;
                  Color borderColor;
                  Color textColor;

                  if (isCurrentQuestion) {
                    backgroundColor = AppTheme.lightTheme.colorScheme.primary;
                    borderColor = AppTheme.lightTheme.colorScheme.primary;
                    textColor = Colors.white;
                  } else if (isAnswered) {
                    backgroundColor = AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.1);
                    borderColor = AppTheme.lightTheme.colorScheme.secondary;
                    textColor = AppTheme.lightTheme.colorScheme.secondary;
                  } else if (isMarked) {
                    backgroundColor = AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.1);
                    borderColor = AppTheme.lightTheme.colorScheme.tertiary;
                    textColor = AppTheme.lightTheme.colorScheme.tertiary;
                  } else {
                    backgroundColor = AppTheme.lightTheme.colorScheme.surface;
                    borderColor = AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.3);
                    textColor =
                        AppTheme.lightTheme.colorScheme.onSurfaceVariant;
                  }

                  return GestureDetector(
                    onTap: () => onQuestionTap(questionNumber),
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor,
                          width: isCurrentQuestion ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              questionNumber.toString(),
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: textColor,
                                fontWeight: isCurrentQuestion
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),

                          // Bookmark indicator
                          if (isMarked && !isCurrentQuestion)
                            Positioned(
                              top: 1,
                              right: 1,
                              child: CustomIconWidget(
                                iconName: 'bookmark',
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Statistics
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Répondues',
                    answeredQuestions.length.toString(),
                    AppTheme.lightTheme.colorScheme.secondary,
                  ),
                  _buildStatItem(
                    'Marquées',
                    markedQuestions.length.toString(),
                    AppTheme.lightTheme.colorScheme.tertiary,
                  ),
                  _buildStatItem(
                    'Restantes',
                    (totalQuestions - answeredQuestions.length).toString(),
                    AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String icon,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: color,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
