import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SortBottomSheetWidget extends StatelessWidget {
  final String currentSortOption;
  final ValueChanged<String> onSortChanged;

  const SortBottomSheetWidget({
    super.key,
    required this.currentSortOption,
    required this.onSortChanged,
  });

  static void show(
    BuildContext context, {
    required String currentSortOption,
    required ValueChanged<String> onSortChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheetWidget(
        currentSortOption: currentSortOption,
        onSortChanged: onSortChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sortOptions = [
      {
        'key': 'alphabetical',
        'title': 'Alphabétique',
        'subtitle': 'Trier par nom (A-Z)',
        'icon': 'sort_by_alpha',
      },
      {
        'key': 'difficulty_asc',
        'title': 'Difficulté croissante',
        'subtitle': 'Du plus facile au plus difficile',
        'icon': 'trending_up',
      },
      {
        'key': 'difficulty_desc',
        'title': 'Difficulté décroissante',
        'subtitle': 'Du plus difficile au plus facile',
        'icon': 'trending_down',
      },
      {
        'key': 'duration_asc',
        'title': 'Durée croissante',
        'subtitle': 'Du plus court au plus long',
        'icon': 'schedule',
      },
      {
        'key': 'duration_desc',
        'title': 'Durée décroissante',
        'subtitle': 'Du plus long au plus court',
        'icon': 'schedule',
      },
      {
        'key': 'completion_status',
        'title': 'Statut de completion',
        'subtitle': 'Non commencés en premier',
        'icon': 'check_circle_outline',
      },
      {
        'key': 'best_score',
        'title': 'Meilleur score',
        'subtitle': 'Du meilleur au moins bon score',
        'icon': 'star',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
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
            child: Row(
              children: [
                Text(
                  'Trier par',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
              ],
            ),
          ),

          // Sort options
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: sortOptions.length,
              separatorBuilder: (context, index) => Divider(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final bool isSelected = currentSortOption == option['key'];

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 1.h),
                  leading: Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                              .withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: CustomIconWidget(
                      iconName: option['icon'],
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 6.w,
                    ),
                  ),
                  title: Text(
                    option['title'],
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    option['subtitle'],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 5.w,
                        )
                      : null,
                  onTap: () {
                    onSortChanged(option['key']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
