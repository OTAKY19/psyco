import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../widgets/neural_header_simple.dart';
import '../../widgets/psycho_glass_card.dart';

class TestLibraryDashboard extends StatelessWidget {
  const TestLibraryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeuralHeaderSimple(
              height: size.height * 0.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Bibliothèque',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Découvrez votre potentiel',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _buildSearchBar(context),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildStatsRow(context),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Catégories',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildCategoryGrid(context),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardSm,
      ),
      child: TextField(
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie...',
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
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            value: '120+',
            label: 'Total tests',
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            value: '85%',
            label: 'Complétés',
            color: AppColors.success,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline,
            value: '4.2/5',
            label: 'Note moy.',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      const _CategoryData(
        title: 'Raisonnement Logique',
        description: 'Capacités de raisonnement',
        icon: Icons.lightbulb_outline,
        color: AppColors.primary,
        count: 25,
      ),
      const _CategoryData(
        title: 'Aptitude Numérique',
        description: 'Calcul et mathématiques',
        icon: Icons.calculate_outlined,
        color: AppColors.quizB,
        count: 30,
      ),
      const _CategoryData(
        title: 'Aptitude Verbale',
        description: 'Langage et communication',
        icon: Icons.text_fields,
        color: AppColors.quizC,
        count: 20,
      ),
      const _CategoryData(
        title: 'Raisonnement Spatial',
        description: 'Pensée spatiale',
        icon: Icons.grid_on,
        color: AppColors.quizD,
        count: 18,
      ),
      const _CategoryData(
        title: 'Mémoire & Attention',
        description: 'Mémoire et concentration',
        icon: Icons.memory,
        color: AppColors.success,
        count: 15,
      ),
      const _CategoryData(
        title: 'Rapidité & Personnalité',
        description: 'Vitesse mentale',
        icon: Icons.speed,
        color: AppColors.accent,
        count: 12,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _CategoryCard(
          data: categories[index],
          onTap: () {
            context.push(
              AppRoutes.testCategory,
              extra: QuizRouteExtra(
                categoryData: {'name': categories[index].title},
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PsychoGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int count;

  const _CategoryData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.count,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryData data;
  final VoidCallback onTap;

  const _CategoryCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.cardSm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppRadii.iconContainer),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      '${data.count}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: data.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                data.title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.description,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
