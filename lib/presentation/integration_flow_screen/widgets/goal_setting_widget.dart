import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class IntegrationGoalSettingWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final String illustration;
  final Function(int) onGoalSet;

  const IntegrationGoalSettingWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    required this.onGoalSet,
  });

  @override
  State<IntegrationGoalSettingWidget> createState() =>
      _IntegrationGoalSettingWidgetState();
}

class _IntegrationGoalSettingWidgetState
    extends State<IntegrationGoalSettingWidget> {
  int _weeklyGoal = 5; // Default goal

  final List<Map<String, dynamic>> _goalPresets = [
    {
      'tests': 3,
      'label': 'Débutant',
      'description': '3 tests par semaine\nIdéal pour commencer',
      'color': const Color(0xFF2D5A27),
    },
    {
      'tests': 5,
      'label': 'Régulier',
      'description': '5 tests par semaine\nRythme soutenu',
      'color': const Color(0xFF4A90A4),
    },
    {
      'tests': 10,
      'label': 'Intensif',
      'description': '10 tests par semaine\nPréparation approfondie',
      'color': const Color(0xFF1B365D),
    },
    {
      'tests': 15,
      'label': 'Expert',
      'description': '15 tests par semaine\nMaximum de performance',
      'color': const Color(0xFFE67E22),
    },
  ];

  @override
  void initState() {
    super.initState();
    _notifyGoalChanged();
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

          // Content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Goal presets
                  _buildGoalPresets(context),

                  SizedBox(height: 4.h),

                  // Custom goal slider
                  _buildCustomGoalSlider(context),

                  SizedBox(height: 4.h),

                  // Achievement preview
                  _buildAchievementPreview(context),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPresets(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectifs Recommandés',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: _goalPresets.length,
          itemBuilder: (context, index) {
            final preset = _goalPresets[index];
            final isSelected = _weeklyGoal == preset['tests'];

            return GestureDetector(
              onTap: () => _selectGoal(preset['tests']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? preset['color'].withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(3.w),
                  border: Border.all(
                    color: isSelected
                        ? preset['color']
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: preset['color'].withValues(alpha: 0.2),
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
                          color: preset['color'],
                          size: 20,
                        ),
                      ),

                    // Number
                    Text(
                      '${preset['tests']}',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? preset['color']
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                    ),

                    SizedBox(height: 1.h),

                    // Label
                    Text(
                      preset['label'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? preset['color']
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),

                    SizedBox(height: 0.5.h),

                    // Description
                    Text(
                      preset['description'],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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

  Widget _buildCustomGoalSlider(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Objectif Personnalisé',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              // Current goal display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_weeklyGoal',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'tests/semaine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Slider
              Slider(
                value: _weeklyGoal.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                onChanged: (value) {
                  _selectGoal(value.round());
                },
              ),

              // Min/Max labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 test',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '20 tests',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementPreview(BuildContext context) {
    final estimatedTime = _calculateEstimatedTime();
    final difficultyLevel = _getDifficultyLevel();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Theme.of(context).colorScheme.tertiary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Aperçu des Récompenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildAchievementItem(
                  context,
                  Icons.schedule,
                  'Temps estimé',
                  estimatedTime,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildAchievementItem(
                  context,
                  Icons.trending_up,
                  'Niveau',
                  difficultyLevel,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Vous débloquerez des badges spéciaux en atteignant vos objectifs !',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 20,
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
      ],
    );
  }

  String _calculateEstimatedTime() {
    final totalMinutes = _weeklyGoal * 12; // Assuming 12 minutes per test
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min/semaine';
    } else {
      return '${minutes}min/semaine';
    }
  }

  String _getDifficultyLevel() {
    if (_weeklyGoal <= 3) return 'Débutant';
    if (_weeklyGoal <= 7) return 'Intermédiaire';
    if (_weeklyGoal <= 12) return 'Avancé';
    return 'Expert';
  }

  void _selectGoal(int goal) {
    setState(() {
      _weeklyGoal = goal;
    });
    _notifyGoalChanged();
  }

  void _notifyGoalChanged() {
    widget.onGoalSet(_weeklyGoal);
  }
}