import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class IntegrationPreferencesSetupWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final String illustration;
  final Function(Map<String, dynamic>) onPreferencesChanged;

  const IntegrationPreferencesSetupWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    required this.onPreferencesChanged,
  });

  @override
  State<IntegrationPreferencesSetupWidget> createState() =>
      _IntegrationPreferencesSetupWidgetState();
}

class _IntegrationPreferencesSetupWidgetState
    extends State<IntegrationPreferencesSetupWidget> {
  List<String> _selectedCategories = [];
  String _selectedDifficulty = 'Intermédiaire';

  final List<Map<String, dynamic>> _testCategories = [
    {
      'id': 'droit_douanier',
      'name': 'Droit Douanier',
      'icon': Icons.gavel,
      'color': const Color(0xFF1B365D),
      'description': 'Réglementation et procédures douanières',
    },
    {
      'id': 'fiscalite',
      'name': 'Fiscalité',
      'icon': Icons.account_balance,
      'color': const Color(0xFF4A90A4),
      'description': 'Taxes et impôts douaniers',
    },
    {
      'id': 'commerce_international',
      'name': 'Commerce International',
      'icon': Icons.public,
      'color': const Color(0xFF2D5A27),
      'description': 'Échanges commerciaux mondiaux',
    },
    {
      'id': 'surveillance',
      'name': 'Surveillance',
      'icon': Icons.security,
      'color': const Color(0xFF8B5A00),
      'description': 'Contrôles et vérifications',
    },
    {
      'id': 'contentieux',
      'name': 'Contentieux',
      'icon': Icons.balance,
      'color': const Color(0xFF8B2635),
      'description': 'Litiges et sanctions',
    },
    {
      'id': 'union_europeenne',
      'name': 'Union Européenne',
      'icon': Icons.flag,
      'color': const Color(0xFFE67E22),
      'description': 'Réglementations européennes',
    },
  ];

  final List<String> _difficultyLevels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert'
  ];

  @override
  void initState() {
    super.initState();
    // Start with some default selections
    _selectedCategories = ['droit_douanier', 'fiscalite'];
    _notifyPreferencesChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          // Header with illustration
          SizedBox(height: 2.h),

          Container(
            width: 50.w,
            height: 20.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.w),
              child: CustomImageWidget(
                imageUrl: widget.illustration,
                width: 50.w,
                height: 20.h,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Title and subtitle
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          SizedBox(height: 1.h),

          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
          ),

          SizedBox(height: 3.h),

          // Content area with categories and difficulty
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories selection
                  _buildCategoriesSection(context),

                  SizedBox(height: 4.h),

                  // Difficulty selection
                  _buildDifficultySection(context),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matières d\'intérêt',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Sélectionnez les domaines que vous souhaitez approfondir (minimum 2)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        SizedBox(height: 2.h),

        // Categories grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: _testCategories.length,
          itemBuilder: (context, index) {
            final category = _testCategories[index];
            final isSelected = _selectedCategories.contains(category['id']);

            return GestureDetector(
              onTap: () => _toggleCategory(category['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? category['color'].withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: isSelected
                        ? category['color']
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: category['color'].withValues(alpha: 0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Selection indicator
                    if (isSelected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          Icons.check_circle,
                          color: category['color'],
                          size: 20,
                        ),
                      ),

                    // Icon
                    Icon(
                      category['icon'],
                      size: 32,
                      color: isSelected
                          ? category['color']
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),

                    SizedBox(height: 1.h),

                    // Name
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? category['color']
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),

                    SizedBox(height: 0.5.h),

                    // Description
                    Text(
                      category['description'],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDifficultySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveau de difficulté',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),

        SizedBox(height: 1.h),

        Text(
          'Choisissez le niveau qui correspond à vos connaissances actuelles',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),

        SizedBox(height: 2.h),

        // Difficulty chips
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _difficultyLevels.map((difficulty) {
            final isSelected = _selectedDifficulty == difficulty;

            return GestureDetector(
              onTap: () => _selectDifficulty(difficulty),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6.w),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  difficulty,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        if (_selectedCategories.length > 1) {
          // Keep at least one selected
          _selectedCategories.remove(categoryId);
        }
      } else {
        _selectedCategories.add(categoryId);
      }
    });

    _notifyPreferencesChanged();
  }

  void _selectDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
    });

    _notifyPreferencesChanged();
  }

  void _notifyPreferencesChanged() {
    final preferences = {
      'categories': _selectedCategories,
      'difficulty': _selectedDifficulty,
      'categoryNames': _selectedCategories.map((id) {
        return _testCategories.firstWhere((cat) => cat['id'] == id)['name'];
      }).toList(),
    };

    widget.onPreferencesChanged(preferences);
  }
}