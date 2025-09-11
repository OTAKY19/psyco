import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final String iconName;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.iconName = 'quiz',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.w),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.6),
                size: 20.w,
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Subtitle
            Text(
              subtitle,
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionText != null && onAction != null) ...[
              SizedBox(height: 4.h),

              // Action button
              ElevatedButton.icon(
                onPressed: onAction,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 5.w,
                ),
                label: Text(actionText!),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
