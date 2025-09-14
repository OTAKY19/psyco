import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  final List<String> _categories = [
    'Logique',
    'Mathématiques',
    'Français',
    'Culture générale',
    'Attention',
    'Mémoire',
  ];

  final List<String> _difficulties = ['Facile', 'Moyen', 'Difficile'];
  final List<String> _completionStatus = [
    'Non commencé',
    'En cours',
    'Terminé'
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Réinitialiser',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    title: 'Catégories',
                    items: _categories,
                    selectedItems:
                        (_filters['categories'] as List<String>?) ?? [],
                    onChanged: (selected) {
                      setState(() {
                        _filters['categories'] = selected;
                      });
                    },
                  ),
                  SizedBox(height: 3.h),
                  _buildFilterSection(
                    title: 'Difficulté',
                    items: _difficulties,
                    selectedItems:
                        (_filters['difficulties'] as List<String>?) ?? [],
                    onChanged: (selected) {
                      setState(() {
                        _filters['difficulties'] = selected;
                      });
                    },
                  ),
                  SizedBox(height: 3.h),
                  _buildFilterSection(
                    title: 'Statut de progression',
                    items: _completionStatus,
                    selectedItems:
                        (_filters['completionStatus'] as List<String>?) ?? [],
                    onChanged: (selected) {
                      setState(() {
                        _filters['completionStatus'] = selected;
                      });
                    },
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text('Annuler'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    ),
                    child: Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: items.map((item) {
            final isSelected = selectedItems.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (selected) {
                final newSelected = List<String>.from(selectedItems);
                if (selected) {
                  newSelected.add(item);
                } else {
                  newSelected.remove(item);
                }
                onChanged(newSelected);
              },
              selectedColor:
                  AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.lightTheme.colorScheme.primary,
              labelStyle: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.5),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'categories': <String>[],
        'difficulties': <String>[],
        'completionStatus': <String>[],
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.pop(context);
  }
}
