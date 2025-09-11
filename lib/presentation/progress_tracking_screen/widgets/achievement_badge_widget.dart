import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;

  const AchievementBadgeWidget({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = achievement['title'] as String;
    final description = achievement['description'] as String;
    final iconName = achievement['icon'] as String;
    final progress = achievement['progress'] as double;

    return Container(
      width: 35.w,
      margin: EdgeInsets.only(right: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppTheme.lightTheme.colorScheme.primaryContainer
            : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.2)
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: isUnlocked
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 7.w,
                ),
              ),
              if (!isUnlocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 5.w,
                    height: 5.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: 'lock',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 3.w,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                  : AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: isUnlocked
                  ? AppTheme.lightTheme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.8)
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isUnlocked) ...[
            SizedBox(height: 2.h),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '${progress.toInt()}%',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
