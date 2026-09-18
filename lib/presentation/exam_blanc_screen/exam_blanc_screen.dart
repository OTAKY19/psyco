import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../services/exam_blanc_service.dart';
import '../../services/subscription_service.dart';
import '../../services/user_state_service.dart';

class ExamBlancScreen extends StatefulWidget {
  const ExamBlancScreen({super.key});

  @override
  State<ExamBlancScreen> createState() => _ExamBlancScreenState();
}

class _ExamBlancScreenState extends State<ExamBlancScreen> {
  final ExamBlancService _examService = ExamBlancService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<ExamBlanc> _exams = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, ExamBlancResult> _userResults = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final exams = await _examService.loadAllExams();

      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startExam(ExamBlanc exam) async {
    try {
      final canTakeTest = await _subscriptionService.canTakeTest();

      if (!canTakeTest) {
        _showActivationPrompt(exam);
        return;
      }

      final session = await _examService.createExamSession(
        exam.id,
        await UserStateService.ensureGuestUserId(),
      );

      if (mounted) {
        final result = await context.push<ExamBlancResult>(
          AppRoutes.examTaking,
          extra: ExamSessionExtra(session: session),
        );
        if (!mounted) return;
        if (result != null) {
          setState(() {
            _userResults[exam.id] = result;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Erreur lors du démarrage de l\'examen: $e');
    }
  }

  Future<void> _showActivationPrompt(ExamBlanc exam) async {
    final size = MediaQuery.of(context).size;
    final used = await _subscriptionService.getUsedFreeTests();
    const total = SubscriptionService.maxFreeTests;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.accentContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock, color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Activation requise',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Vous avez utilisé $used/$total tests gratuits.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Activation unique : 3 000 FCFA via Mobile Money.',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pour continuer à utiliser l\'application, veuillez l\'activer.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avantages de l\'activation',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildBenefitItem('Accès illimité à tous les examens blancs'),
                    _buildBenefitItem('Corrections détaillées avec explications'),
                    _buildBenefitItem('Statistiques de progression avancées'),
                    _buildBenefitItem('Mode hors ligne'),
                    _buildBenefitItem('Support prioritaire'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: Text(
                        'Annuler',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(AppRoutes.activation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Activer l\'app',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Erreur',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'OK',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: const Icon(
              Icons.quiz,
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
                  'Examens Blancs',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Entraînez-vous pour le concours',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadExams,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(AppRadii.iconContainer),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Chargement des examens...',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Erreur de chargement',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: _loadExams,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Aucun examen disponible',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Les examens seront bientôt disponibles.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildStatsOverview(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Examens Disponibles',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverList.builder(
              itemCount: _exams.length,
              itemBuilder: (context, index) {
                final exam = _exams[index];
                final result = _userResults[exam.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _buildExamCard(exam, result),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    final completedExams = _userResults.length;
    final avgScore = _calculateAverageScore();
    final passRate = _calculatePassRate();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          _buildStatItem(
            Icons.assignment_turned_in,
            '$completedExams',
            'Examens',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.onPrimary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            Icons.score,
            '${avgScore.toStringAsFixed(0)}%',
            'Moyenne',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.onPrimary.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            Icons.emoji_events,
            '${passRate.toStringAsFixed(0)}%',
            'Réussite',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.onPrimary.withValues(alpha: 0.8), size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamBlanc exam, ExamBlancResult? result) {
    final hasResult = result != null;
    final passed = hasResult && result.scorePercentage >= 60;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
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
                            exam.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            exam.description,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.timer_outlined,
                      '${exam.duration.inMinutes} min',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildInfoChip(
                      Icons.help_outline,
                      '${exam.totalQuestions} questions',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildDifficultyBadge(exam.id),
                  ],
                ),
                if (hasResult) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: passed
                          ? AppColors.successContainer
                          : AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          passed ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: passed ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Meilleur score: ${result.scorePercentage.toStringAsFixed(1)}%',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: passed ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _startExam(exam),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadii.card),
                      bottomRight: Radius.circular(AppRadii.card),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      hasResult ? 'Repasser l\'examen' : 'Commencer',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String examId) {
    String difficulty = 'Facile';
    Color bgColor = AppColors.successContainer;
    Color fgColor = AppColors.success;

    if (examId.contains('6') || examId.contains('series')) {
      difficulty = 'Moyen';
      bgColor = AppColors.warningContainer;
      fgColor = AppColors.warning;
    } else if (examId.contains('10') || examId.contains('hard')) {
      difficulty = 'Difficile';
      bgColor = AppColors.errorContainer;
      fgColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.badge),
      ),
      child: Text(
        difficulty,
        style: AppTextStyles.labelSmall.copyWith(
          color: fgColor,
        ),
      ),
    );
  }

  double _calculateAverageScore() {
    if (_userResults.isEmpty) return 0.0;

    final totalScore = _userResults.values
        .map((result) => result.scorePercentage)
        .reduce((a, b) => a + b);

    return totalScore / _userResults.length;
  }

  double _calculatePassRate() {
    if (_userResults.isEmpty) return 0.0;

    final passedCount =
        _userResults.values.where((r) => r.scorePercentage >= 60).length;

    return (passedCount / _userResults.length) * 100;
  }
}
