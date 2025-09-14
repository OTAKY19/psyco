import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ContextMenuWidget extends StatelessWidget {
  final Map<String, dynamic> testData;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onViewSolutions;
  final VoidCallback onClose;

  const ContextMenuWidget({
    super.key,
    required this.testData,
    required this.onShare,
    required this.onReport,
    required this.onViewSolutions,
    required this.onClose,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> testData,
    required VoidCallback onShare,
    required VoidCallback onReport,
    required VoidCallback onViewSolutions,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContextMenuWidget(
        testData: testData,
        onShare: onShare,
        onReport: onReport,
        onViewSolutions: onViewSolutions,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': 'share',
        'title': 'Partager le test',
        'subtitle': 'Partager avec d\'autres utilisateurs',
        'onTap': () {
          onClose();
          onShare();
        },
      },
      {
        'icon': 'lightbulb_outline',
        'title': 'Voir les solutions',
        'subtitle': 'Consulter les réponses détaillées',
        'onTap': () {
          onClose();
          onViewSolutions();
        },
      },
      {
        'icon': 'report_problem',
        'title': 'Signaler un problème',
        'subtitle': 'Signaler une erreur ou un bug',
        'onTap': () {
          onClose();
          onReport();
        },
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

          // Test info header
          Container(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: testData['iconName'] ?? 'quiz',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testData['title'] ?? 'Test sans titre',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Niveau ${testData['difficulty'] ?? 1}/5 • ${testData['duration'] ?? 30} min',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),

          // Menu items
          ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            itemCount: menuItems.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final item = menuItems[index];

              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 1.h),
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: CustomIconWidget(
                    iconName: item['icon'],
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
                title: Text(
                  item['title'],
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  item['subtitle'],
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
                onTap: item['onTap'],
              );
            },
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
