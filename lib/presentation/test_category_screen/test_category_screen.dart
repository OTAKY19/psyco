import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';
import 'package:provider/provider.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../services/test_service.dart';
import '../../models/question.dart';

class TestCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? categoryData;

  const TestCategoryScreen({super.key, this.categoryData});

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  String _searchQuery = '';
  String _selectedDifficulty = 'Tous';
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final testService = Provider.of<TestService>(context, listen: false);
    final sampleQuestions = [
      Question(
        id: 1,
        categorie: 'raisonnement_logique',
        question: 'Quelle est la capitale de la France ?',
        options: ['Paris', 'Londres', 'Berlin', 'Madrid'],
        reponse: 'Paris',
        explication: 'Paris est la capitale de la France',
        niveau: 'facile',
        probaSimple: 0.8,
      ),
      Question(
        id: 2,
        categorie: 'aptitude_numerique',
        question: '2 + 2 = ?',
        options: ['3', '4', '5', '6'],
        reponse: '4',
        explication: '2 + 2 égale 4',
        niveau: 'facile',
        probaSimple: 0.9,
      ),
    ];
    testService.loadQuestions(sampleQuestions);
  }

  List<Question> _filterQuestions(List<Question> questions) {
    var filtered = questions.where((q) {
      final matchesSearch = _searchQuery.isEmpty ||
          q.question.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDifficulty =
          _selectedDifficulty == 'Tous' || q.niveau == _selectedDifficulty;
      return matchesSearch && matchesDifficulty;
    }).toList();

    if (_sortBy == 'difficulty') {
      final order = {'facile': 0, 'moyen': 1, 'difficile': 2};
      filtered.sort(
          (a, b) => (order[a.niveau] ?? 0).compareTo(order[b.niveau] ?? 0));
    } else if (_sortBy == 'alpha') {
      filtered.sort((a, b) => a.question.compareTo(b.question));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.categoryData?['name'] ?? 'Catégorie';
    final categoryIcon = widget.categoryData?['icon'] as IconData? ??
        Icons.category;
    final categoryColor =
        widget.categoryData?['color'] as Color? ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, size: 22),
            color: AppColors.textSecondary,
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryHeader(categoryName, categoryIcon, categoryColor),
          _buildSearchField(),
          _buildFilterChips(),
          Expanded(
            child: Consumer<TestService>(
              builder: (context, testService, child) {
                if (testService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final filtered = _filterQuestions(testService.questions);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildTestList(filtered);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(
      String name, IconData icon, Color color) {
    return Container(
      margin: AppSpacing.pagePadding,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: Icon(icon, color: AppColors.textOnPrimary, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Testez vos compétences',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Rechercher un test...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final difficulties = ['Tous', 'facile', 'moyen', 'difficile'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: difficulties.map((d) {
          final isSelected = _selectedDifficulty == d;
          final color = d == 'facile'
              ? AppColors.success
              : d == 'moyen'
                  ? AppColors.quizB
                  : d == 'difficile'
                      ? AppColors.error
                      : AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  d[0].toUpperCase() + d.substring(1),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestList(List<Question> questions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        return _buildTestItem(q);
      },
    );
  }

  Widget _buildTestItem(Question question) {
    final difficultyColor = question.niveau == 'facile'
        ? AppColors.success
        : question.niveau == 'moyen'
            ? AppColors.quizB
            : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: () {
            context.push(
              AppRoutes.testTaking,
              extra: QuizRouteExtra(
                categoryData: {'id': question.id},
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadii.iconContainer),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${question.options.length} options',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    question.niveau[0].toUpperCase() +
                        question.niveau.substring(1),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: difficultyColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Aucun test trouvé',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Essayez avec d\'autres filtres',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortSheet(
        currentSort: _sortBy,
        onSort: (sort) {
          setState(() => _sortBy = sort);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSort;

  const _SortSheet({required this.currentSort, required this.onSort});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('newest', 'Plus récent'),
      ('difficulty', 'Difficulté'),
      ('alpha', 'Alphabétique'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.modalTop),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Trier par', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ...options.map((o) {
            final isSelected = currentSort == o.$1;
            return ListTile(
              title: Text(
                o.$2,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => onSort(o.$1),
            );
          }),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
