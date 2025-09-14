import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExamQuestionWidget extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final int? selectedOption;
  final Function(int) onOptionSelected;
  final String? questionImage;
  final int questionNumber;
  final String category;

  const ExamQuestionWidget({
    super.key,
    required this.questionText,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
    this.questionImage,
    required this.questionNumber,
    required this.category,
  });

  String _getCategoryName(String category) {
    switch (category) {
      case 'raisonnement_logique':
        return 'Logique';
      case 'aptitude_numerique':
        return 'Mathématiques';
      case 'aptitude_verbale':
        return 'Français';
      case 'culture_generale':
        return 'Culture Générale';
      case 'memoire_attention':
        return 'Mémoire';
      case 'raisonnement_spatial':
        return 'Spatial';
      case 'rapidite_personnalite':
        return 'Rapidité';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'raisonnement_logique':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'aptitude_numerique':
        return AppTheme.lightTheme.colorScheme.secondary;
      case 'aptitude_verbale':
        return AppTheme.accentLight;
      case 'culture_generale':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'memoire_attention':
        return const Color(0xFF9C27B0); // Purple
      case 'raisonnement_spatial':
        return const Color(0xFF607D8B); // Blue Grey
      case 'rapidite_personnalite':
        return const Color(0xFF795548); // Brown
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with number and category
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _getCategoryColor(category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getCategoryColor(category).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      questionNumber.toString(),
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question $questionNumber',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(category),
                        ),
                      ),
                      Text(
                        _getCategoryName(category),
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: _getCategoryColor(category).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryName(category),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Question Text
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
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
            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: InkWell(
                onTap: () => onOptionSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Option Letter Circle
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            optionLetter,
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
                          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Selection Indicator
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 4.w,
                          ),
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
