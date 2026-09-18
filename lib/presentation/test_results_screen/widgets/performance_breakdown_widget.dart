import 'package:flutter/material.dart';

import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../design/app_text_styles.dart';

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
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des Réponses',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownItem(
                  'Correctes',
                  correctAnswers,
                  totalQuestions,
                  AppColors.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildBreakdownItem(
                  'Incorrectes',
                  incorrectAnswers,
                  totalQuestions,
                  AppColors.error,
                  Icons.cancel,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildBreakdownItem(
                  'Ignorées',
                  skippedAnswers,
                  totalQuestions,
                  AppColors.warning,
                  Icons.help_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            count.toString(),
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
            ),
          ),
          Text(
            '${percentage.toInt()}%',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
