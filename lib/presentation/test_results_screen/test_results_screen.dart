import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import 'widgets/performance_breakdown_widget.dart';
import 'widgets/category_performance_chart_widget.dart';

class TestResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? testResults;

  const TestResultsScreen({super.key, this.testResults});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0, end: _score).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _score =>
      (widget.testResults?['percentage'] ?? 0).toDouble();

  bool get _isHighScore => _score >= 75;

  @override
  Widget build(BuildContext context) {
    final raw = widget.testResults;
    final correct = raw?['correct'] ?? 0;
    final incorrect = raw?['incorrect'] ?? 0;
    final skipped = raw?['skipped'] ?? 0;
    final total = correct + incorrect + skipped;

    if (raw == null || total == 0) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inbox_rounded,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Résultats indisponibles',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Terminez un test pour voir votre score ici.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreHeader(),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _buildScoreDisplay(),
                  const SizedBox(height: AppSpacing.xxl),
                  PerformanceBreakdownWidget(
                    correctAnswers: correct,
                    incorrectAnswers: incorrect,
                    skippedAnswers: skipped,
                    totalQuestions: total,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildCategoryChart(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildActionButtons(),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        MediaQuery.of(context).padding.top + AppSpacing.xxl,
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          if (_isHighScore) ...[
            const Icon(Icons.celebration, color: AppColors.accent, size: 40),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            _isHighScore ? 'Félicitations !' : 'Test terminé !',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textOnPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Voici vos résultats',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: _scoreAnimation.value / 100,
                        strokeWidth: 10,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _score >= 75
                              ? AppColors.success
                              : _score >= 50
                                  ? AppColors.quizB
                                  : AppColors.error,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_scoreAnimation.value.toInt()}%',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: _score >= 75
                                ? AppColors.success
                                : _score >= 50
                                    ? AppColors.quizB
                                    : AppColors.error,
                          ),
                        ),
                        Text(
                          'Score',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _score >= 75
                    ? 'Excellent travail !'
                    : _score >= 50
                        ? 'Bon effort !'
                        : 'Continuez à vous entraîner !',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChart() {
    final categoryData = [
      {'name': 'Logique', 'score': 85.0},
      {'name': 'Numérique', 'score': 72.0},
      {'name': 'Verbale', 'score': 60.0},
      {'name': 'Spatial', 'score': 90.0},
    ];
    return CategoryPerformanceChartWidget(categoryData: categoryData);
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              context.go(AppRoutes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
            ),
            child: Text(
              'Retour aux tests',
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
