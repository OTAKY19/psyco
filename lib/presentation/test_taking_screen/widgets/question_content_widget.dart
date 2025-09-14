import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuestionContentWidget extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final int? selectedOption;
  final Function(int) onOptionSelected;
  final String? questionImage;

  const QuestionContentWidget({
    super.key,
    required this.questionText,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
    this.questionImage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 1.h),

                Text(
                  questionText,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // Question Image (if available)
                if (questionImage != null) ...[
                  SizedBox(height: 2.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: questionImage!,
                      width: double.infinity,
                      height: 25.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Options Label
          Text(
            'Choisissez votre réponse :',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 2.h),

          // Answer Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedOption == index;

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: GestureDetector(
                onTap: () => onOptionSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 4.w),

                      // Option Text
                      Expanded(
                        child: Text(
                          option,
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Selection Indicator
                      if (isSelected)
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 4.h), // Extra space for navigation buttons
        ],
      ),
    );
  }
}
