import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TestCardWidget extends StatelessWidget {
  final Map<String, dynamic> testData;
  final VoidCallback onTap;
  final VoidCallback onStartTest;
  final VoidCallback onDownload;
  final VoidCallback onFavorite;
  final VoidCallback onRemove;
  final VoidCallback onDeleteProgress;

  const TestCardWidget({
    Key? key,
    required this.testData,
    required this.onTap,
    required this.onStartTest,
    required this.onDownload,
    required this.onFavorite,
    required this.onRemove,
    required this.onDeleteProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isPremium = testData['isPremium'] ?? false;
    final bool isDownloaded = testData['isDownloaded'] ?? false;
    final bool isCompleted = testData['isCompleted'] ?? false;
    final int difficulty = testData['difficulty'] ?? 1;
    final int attemptCount = testData['attemptCount'] ?? 0;
    final double bestScore = testData['bestScore'] ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(testData['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onStartTest(),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.play_arrow,
              label: 'Démarrer',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => isDownloaded ? onRemove() : onDownload(),
              backgroundColor: isDownloaded
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: isDownloaded ? Icons.delete : Icons.download,
              label: isDownloaded ? 'Supprimer' : 'Télécharger',
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: (_) => onFavorite(),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              icon: Icons.favorite,
              label: 'Favoris',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (isCompleted)
              SlidableAction(
                onPressed: (_) => onDeleteProgress(),
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                icon: Icons.refresh,
                label: 'Réinitialiser',
                borderRadius: BorderRadius.circular(12),
              ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Test thumbnail/icon
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: CustomIconWidget(
                            iconName: testData['iconName'] ?? 'quiz',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 8.w,
                          ),
                        ),
                        if (isPremium)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: CustomIconWidget(
                              iconName: 'lock',
                              color: Colors.amber,
                              size: 4.w,
                            ),
                          ),
                        if (isDownloaded)
                          Positioned(
                            bottom: 2,
                            left: 2,
                            child: CustomIconWidget(
                              iconName: 'download_done',
                              color: Colors.green,
                              size: 3.w,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // Test details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and completion status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                testData['title'] ?? 'Test sans titre',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCompleted)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Terminé',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 1.h),

                        // Difficulty stars
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return CustomIconWidget(
                                iconName:
                                    index < difficulty ? 'star' : 'star_border',
                                color: index < difficulty
                                    ? Colors.amber
                                    : AppTheme.lightTheme.colorScheme.outline,
                                size: 4.w,
                              );
                            }),
                            SizedBox(width: 2.w),
                            Text(
                              'Niveau $difficulty/5',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),

                        // Duration and stats
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'access_time',
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${testData['duration'] ?? 30} min',
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                            ),
                            SizedBox(width: 4.w),
                            if (attemptCount > 0) ...[
                              CustomIconWidget(
                                iconName: 'replay',
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                                size: 4.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '$attemptCount tentative${attemptCount > 1 ? 's' : ''}',
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                            ],
                            if (bestScore > 0) ...[
                              SizedBox(width: 4.w),
                              CustomIconWidget(
                                iconName: 'star',
                                color: Colors.amber,
                                size: 4.w,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${bestScore.toStringAsFixed(1)}%',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action indicator
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
