import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterChipsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeFilters;
  final ValueChanged<String> onRemoveFilter;

  const FilterChipsWidget({
    Key? key,
    required this.activeFilters,
    required this.onRemoveFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres actifs (${activeFilters.length})',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: activeFilters.map((filter) {
              return _buildFilterChip(filter);
            }).toList(),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildFilterChip(Map<String, dynamic> filter) {
    final String filterType = filter['type'] ?? '';
    final String filterValue = filter['value'] ?? '';
    final int count = filter['count'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 3.w, top: 1.h, bottom: 1.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getFilterDisplayText(filterType, filterValue),
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: 1.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => onRemoveFilter('$filterType:$filterValue'),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 4.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterDisplayText(String type, String value) {
    switch (type) {
      case 'difficulty':
        return 'Niveau $value';
      case 'duration':
        return 'Durée: $value min';
      case 'status':
        switch (value) {
          case 'completed':
            return 'Terminés';
          case 'not_started':
            return 'Non commencés';
          case 'in_progress':
            return 'En cours';
          default:
            return value;
        }
      case 'type':
        return 'Type: $value';
      default:
        return value;
    }
  }
}
