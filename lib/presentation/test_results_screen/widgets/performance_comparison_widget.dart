import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PerformanceComparisonWidget extends StatelessWidget {
  final double currentScore;
  final double previousScore;
  final List<Map<String, dynamic>> recentAttempts;

  const PerformanceComparisonWidget({
    super.key,
    required this.currentScore,
    required this.previousScore,
    required this.recentAttempts,
  });

  @override
  Widget build(BuildContext context) {
    final double improvement = currentScore - previousScore;
    final bool hasImproved = improvement > 0;
    final bool hasDeclined = improvement < 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparaison des Performances',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 3.h),

          // Current vs Previous comparison
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: hasImproved
                  ? AppTheme.successLight.withValues(alpha: 0.1)
                  : hasDeclined
                      ? AppTheme.errorLight.withValues(alpha: 0.1)
                      : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasImproved
                    ? AppTheme.successLight.withValues(alpha: 0.3)
                    : hasDeclined
                        ? AppTheme.errorLight.withValues(alpha: 0.3)
                        : AppTheme.lightTheme.colorScheme.outline
                            .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: hasImproved
                      ? 'trending_up'
                      : hasDeclined
                          ? 'trending_down'
                          : 'trending_flat',
                  color: hasImproved
                      ? AppTheme.successLight
                      : hasDeclined
                          ? AppTheme.errorLight
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasImproved
                            ? 'Amélioration!'
                            : hasDeclined
                                ? 'En baisse'
                                : 'Stable',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: hasImproved
                                      ? AppTheme.successLight
                                      : hasDeclined
                                          ? AppTheme.errorLight
                                          : AppTheme.lightTheme.colorScheme
                                              .onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        improvement != 0
                            ? '${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}% par rapport à la dernière tentative'
                            : 'Même score que la dernière tentative',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${currentScore.toInt()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: hasImproved
                            ? AppTheme.successLight
                            : hasDeclined
                                ? AppTheme.errorLight
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Recent attempts trend
          if (recentAttempts.isNotEmpty) ...[
            Text(
              'Tentatives Récentes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 15.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recentAttempts.length,
                itemBuilder: (context, index) {
                  final attempt = recentAttempts[index];
                  final score = (attempt["score"] as double);
                  final date = attempt["date"] as String;
                  final isCurrentAttempt = index == 0;

                  return Container(
                    width: 20.w,
                    margin: EdgeInsets.only(right: 2.w),
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isCurrentAttempt
                          ? AppTheme.primaryLight.withValues(alpha: 0.1)
                          : AppTheme
                              .lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentAttempt
                          ? Border.all(
                              color:
                                  AppTheme.primaryLight.withValues(alpha: 0.3),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${score.toInt()}%',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: isCurrentAttempt
                                        ? AppTheme.primaryLight
                                        : AppTheme.lightTheme.colorScheme
                                            .onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          date,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        if (isCurrentAttempt) ...[
                          SizedBox(height: 0.5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Actuel',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
