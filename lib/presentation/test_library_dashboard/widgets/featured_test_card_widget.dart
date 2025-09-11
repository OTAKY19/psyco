import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FeaturedTestCardWidget extends StatelessWidget {
  final Map<String, dynamic> test;
  final VoidCallback onTap;

  const FeaturedTestCardWidget({
    Key? key,
    required this.test,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final difficulty = test['difficulty'] as String;
    final duration = test['duration'] as int;
    final questionCount = test['questionCount'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70.w,
        margin: EdgeInsets.only(right: 3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightTheme.primaryColor,
              AppTheme.lightTheme.colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recommandé',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'star',
                      color: Colors.white,
                      size: 4.w,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                test['title'] as String,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text(
                test['description'] as String,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  _buildInfoChip(
                    icon: 'quiz',
                    text: '$questionCount Q',
                  ),
                  SizedBox(width: 2.w),
                  _buildInfoChip(
                    icon: 'schedule',
                    text: '${duration}min',
                  ),
                  SizedBox(width: 2.w),
                  _buildInfoChip(
                    icon: _getDifficultyIcon(difficulty),
                    text: difficulty,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required String icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: Colors.white,
            size: 3.w,
          ),
          SizedBox(width: 1.w),
          Text(
            text,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return 'trending_down';
      case 'moyen':
        return 'trending_flat';
      case 'difficile':
        return 'trending_up';
      default:
        return 'help';
    }
  }
}
