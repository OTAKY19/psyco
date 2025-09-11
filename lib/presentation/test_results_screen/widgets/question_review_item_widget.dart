import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuestionReviewItemWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final int questionNumber;
  final VoidCallback? onBookmarkToggle;

  const QuestionReviewItemWidget({
    Key? key,
    required this.question,
    required this.questionNumber,
    this.onBookmarkToggle,
  }) : super(key: key);

  @override
  State<QuestionReviewItemWidget> createState() =>
      _QuestionReviewItemWidgetState();
}

class _QuestionReviewItemWidgetState extends State<QuestionReviewItemWidget> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = widget.question["isCorrect"] as bool;
    final bool isSkipped = widget.question["userAnswer"] == null;
    final bool isBookmarked = widget.question["isBookmarked"] as bool? ?? false;

    Color statusColor = AppTheme.warningLight;
    String statusIcon = 'help_outline';

    if (!isSkipped) {
      if (isCorrect) {
        statusColor = AppTheme.successLight;
        statusIcon = 'check_circle';
      } else {
        statusColor = AppTheme.errorLight;
        statusIcon = 'cancel';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: statusIcon,
                  color: statusColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Question ${widget.questionNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: widget.onBookmarkToggle,
                icon: CustomIconWidget(
                  iconName: isBookmarked ? 'bookmark' : 'bookmark_border',
                  color: isBookmarked
                      ? AppTheme.accentLight
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.question["questionText"] as String,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 2.h),
          if (!isSkipped) ...[
            _buildAnswerRow(
              context,
              'Votre réponse:',
              widget.question["userAnswer"] as String,
              isCorrect ? AppTheme.successLight : AppTheme.errorLight,
            ),
            SizedBox(height: 1.h),
          ],
          _buildAnswerRow(
            context,
            'Réponse correcte:',
            widget.question["correctAnswer"] as String,
            AppTheme.successLight,
          ),
          SizedBox(height: 2.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _showExplanation = !_showExplanation;
              });
            },
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _showExplanation ? 'expand_less' : 'expand_more',
                  color: AppTheme.primaryLight,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  _showExplanation
                      ? 'Masquer l\'explication'
                      : 'Voir l\'explication',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          if (_showExplanation) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                widget.question["explanation"] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerRow(
      BuildContext context, String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
