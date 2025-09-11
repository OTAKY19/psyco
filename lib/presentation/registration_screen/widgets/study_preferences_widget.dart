import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class StudyPreferencesWidget extends StatelessWidget {
  final List<String> selectedCategories;
  final String selectedDifficulty;
  final ValueChanged<List<String>> onCategoriesChanged;
  final ValueChanged<String> onDifficultyChanged;

  const StudyPreferencesWidget({
    super.key,
    required this.selectedCategories,
    required this.selectedDifficulty,
    required this.onCategoriesChanged,
    required this.onDifficultyChanged,
  });

  static const List<Map<String, dynamic>> _testCategories = [
    {'id': 'douane', 'name': 'Douanes', 'icon': Icons.business_center},
    {'id': 'fiscal', 'name': 'Fiscalité', 'icon': Icons.account_balance},
    {'id': 'commerce', 'name': 'Commerce International', 'icon': Icons.public},
    {'id': 'transport', 'name': 'Transport', 'icon': Icons.local_shipping},
    {'id': 'juridique', 'name': 'Juridique', 'icon': Icons.gavel},
    {'id': 'comptabilite', 'name': 'Comptabilité', 'icon': Icons.calculate},
  ];

  static const List<Map<String, dynamic>> _difficultyLevels = [
    {
      'id': 'beginner',
      'name': 'Débutant',
      'description': 'Concepts de base et questions simples',
      'color': Colors.green,
    },
    {
      'id': 'intermediate',
      'name': 'Intermédiaire',
      'description': 'Connaissances moyennes et applications pratiques',
      'color': Colors.orange,
    },
    {
      'id': 'advanced',
      'name': 'Avancé',
      'description': 'Questions complexes et cas d\'étude approfondis',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Préférences d\'étude',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 2.h),
        Text(
          'Catégories d\'intérêt',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 1.h),
        Text(
          'Sélectionnez les domaines qui vous intéressent le plus',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _testCategories.map((category) {
            final isSelected = selectedCategories.contains(category['id']);
            return FilterChip(
              selected: isSelected,
              label: Text(category['name']),
              avatar: Icon(
                category['icon'],
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onSelected: (selected) {
                List<String> newSelection = List.from(selectedCategories);
                if (selected) {
                  newSelection.add(category['id']);
                } else {
                  newSelection.remove(category['id']);
                }
                onCategoriesChanged(newSelection);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 3.h),
        Text(
          'Niveau de difficulté',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 1.h),
        Text(
          'Choisissez le niveau qui correspond à vos connaissances',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: 2.h),
        Column(
          children: _difficultyLevels.map((level) {
            final isSelected = selectedDifficulty == level['id'];
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              elevation: isSelected ? 4 : 1,
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: RadioListTile<String>(
                value: level['id'],
                groupValue: selectedDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    onDifficultyChanged(value);
                  }
                },
                title: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: level['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      level['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : null,
                          ),
                    ),
                  ],
                ),
                subtitle: Text(
                  level['description'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
