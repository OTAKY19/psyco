import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'custom_icon_widget.dart';
import 'modern_card_widget.dart';
import 'modern_button_widget.dart';

/// Widget de statistiques rapides amélioré
class EnhancedQuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const EnhancedQuickStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ModernStatsCardWidget(
                  title: 'Tests complétés',
                  value: '${stats['testsCompleted'] ?? 0}',
                  subtitle: 'Cette semaine',
                  iconName: 'assignment_turned_in',
                  iconColor: Colors.green,
                  showTrend: true,
                  trendValue: 12.5,
                  isPositiveTrend: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ModernStatsCardWidget(
                  title: 'Score moyen',
                  value: '${(stats['averageScore'] ?? 0.0).toStringAsFixed(1)}%',
                  subtitle: 'Tous les tests',
                  iconName: 'analytics',
                  iconColor: Colors.blue,
                  showTrend: true,
                  trendValue: 5.2,
                  isPositiveTrend: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ModernStatsCardWidget(
            title: 'Série d\'étude',
            value: '${stats['studyStreak'] ?? 0} jours',
            subtitle: 'Continuez comme ça ! 🔥',
            iconName: 'local_fire_department',
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

/// Widget de carte de test en vedette amélioré
class EnhancedFeaturedTestCardWidget extends StatefulWidget {
  final Map<String, dynamic> test;
  final VoidCallback? onTap;

  const EnhancedFeaturedTestCardWidget({
    super.key,
    required this.test,
    this.onTap,
  });

  @override
  State<EnhancedFeaturedTestCardWidget> createState() => _EnhancedFeaturedTestCardWidgetState();
}

class _EnhancedFeaturedTestCardWidgetState extends State<EnhancedFeaturedTestCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficulty = widget.test['difficulty'] as String? ?? 'Moyen';
    final difficultyColor = _getDifficultyColor(difficulty);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - _slideAnimation.value), 0),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              width: 70.w,
              margin: EdgeInsets.only(right: 4.w),
              child: ModernCardWidget(
                onTap: widget.onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                          decoration: BoxDecoration(
                            color: difficultyColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            difficulty,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: difficultyColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomIconWidget(
                            iconName: 'quiz',
                            color: Theme.of(context).colorScheme.primary,
                            size: 5.w,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.test['title'] as String? ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      widget.test['description'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          'schedule',
                          '${widget.test['duration'] ?? 0} min',
                        ),
                        SizedBox(width: 2.w),
                        _buildInfoChip(
                          context,
                          'help_outline',
                          '${widget.test['questionCount'] ?? 0} questions',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String iconName, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 3.w,
          ),
          SizedBox(width: 1.w),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de carte de catégorie de test amélioré
class EnhancedTestCategoryCardWidget extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedTestCategoryCardWidget({
    super.key,
    required this.category,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<EnhancedTestCategoryCardWidget> createState() => _EnhancedTestCategoryCardWidgetState();
}

class _EnhancedTestCategoryCardWidgetState extends State<EnhancedTestCategoryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: (widget.category['completionPercentage'] as int? ?? 0) / 100.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Démarrer l'animation après un petit délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'raisonnement_logique':
        return Colors.purple;
      case 'aptitude_numerique':
        return Colors.blue;
      case 'aptitude_verbale':
        return Colors.green;
      case 'culture_generale':
        return Colors.orange;
      case 'memoire_attention':
        return Colors.red;
      case 'raisonnement_spatial':
        return Colors.teal;
      case 'rapidite_personnalite':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.category['isPremium'] as bool? ?? false;
    final isUnlocked = widget.category['isUnlocked'] as bool? ?? true;
    final testCount = widget.category['testCount'] as int? ?? 0;
    final completionPercentage = widget.category['completionPercentage'] as int? ?? 0;
    final categoryColor = _getCategoryColor(widget.category['category'] as String? ?? '');

    return ModernCardWidget(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomIconWidget(
                  iconName: widget.category['iconName'] as String? ?? 'help_outline',
                  color: categoryColor,
                  size: 7.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.category['name'] as String? ?? '',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium && !isUnlocked) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.w),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'lock',
                                  color: Colors.amber,
                                  size: 3.w,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  'Premium',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '$testCount tests disponibles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            widget.category['description'] as String? ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression: $completionPercentage%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.category['difficulty'] as String? ?? 'Moyen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: categoryColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  minHeight: 0.8.h,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget de barre de recherche moderne
class ModernSearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final bool showFilter;

  const ModernSearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Rechercher...',
    this.onFilterTap,
    this.onChanged,
    this.showFilter = true,
  });

  @override
  State<ModernSearchBarWidget> createState() => _ModernSearchBarWidgetState();
}

class _ModernSearchBarWidgetState extends State<ModernSearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Theme.of(context).colorScheme.surface,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isFocused
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                        width: _isFocused ? 2 : 1,
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                        ),
                        suffixIcon: widget.controller.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  widget.controller.clear();
                                  widget.onChanged?.call('');
                                },
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 5.w,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 3.w,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _isFocused = true;
                        });
                        _animationController.forward();
                      },
                      onTapOutside: (_) {
                        setState(() {
                          _isFocused = false;
                        });
                        _animationController.reverse();
                      },
                    ),
                  ),
                ),
                if (widget.showFilter) ...[
                  SizedBox(width: 3.w),
                  ModernButtonWidget(
                    text: '',
                    iconName: 'tune',
                    onPressed: widget.onFilterTap,
                    style: ModernButtonStyle.primary,
                    size: ModernButtonSize.medium,
                    width: 12.w,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
