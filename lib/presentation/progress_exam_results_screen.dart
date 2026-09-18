import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/app_colors.dart';
import '../design/app_radii.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';
import '../routes/app_routes.dart';
import '../services/user_state_service.dart';
import '../widgets/unified_activation_widget.dart';

class ProgressExamResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ProgressExamResultsScreen({super.key, this.arguments});

  @override
  State<ProgressExamResultsScreen> createState() => _ProgressExamResultsScreenState();
}

class _ProgressExamResultsScreenState extends State<ProgressExamResultsScreen> {
  late List<Map<String, dynamic>> results;
  late int totalQuestions;
  late int correctAnswers;
  late int timeSpent;

  bool _isActivated = false;
  int _visibleResultsCount = 10;
  bool _canRevealMore = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkDemoCompletion();
    _loadActivationState();
  }

  void _initializeData() {
    final args = widget.arguments ?? {};
    results = List<Map<String, dynamic>>.from(args['results'] ?? []);
    totalQuestions = args['totalQuestions'] ?? 40;
    correctAnswers = args['correctAnswers'] ?? 0;
    timeSpent = args['timeSpent'] ?? 0;
  }

  Future<void> _loadActivationState() async {
    final userStateService = UserStateService();
    final userState = await userStateService.getUserState();
    setState(() {
      _isActivated = userState.isActivated;
      _visibleResultsCount = userState.visibleResultsCount;
      _canRevealMore = userState.canRevealMore;
    });
    _startRevealTimer();
  }

  void _startRevealTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        final canReveal = await UserStateService().canRevealMoreResults();
        if (canReveal && !_canRevealMore) {
          setState(() => _canRevealMore = true);
        }
      }
    });
  }

  Future<void> _revealMoreResults() async {
    final userStateService = UserStateService();
    await userStateService.revealMoreResults();
    final newCount = await userStateService.getVisibleResultsCount();
    setState(() {
      _visibleResultsCount = newCount;
      _canRevealMore = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkDemoCompletion() async {
    await Future.delayed(const Duration(seconds: 8));
    if (mounted) {
      final userStateService = UserStateService();
      final userState = await userStateService.getUserState();
      if (userState.hasCompletedDemo && !userState.isActivated) {
        _showPaymentSuggestion();
      }
    }
  }

  void _showPaymentSuggestion() {
    UnifiedActivationWidget.show(
      context,
      contextMessage: 'Félicitations ! Découvrez toutes les fonctionnalités premium.',
    );
  }

  void _onActivatePressed() {
    context.push(AppRoutes.activation);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scorePercent = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;
    final isPassed = scorePercent >= 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  children: [
                    _buildScoreHero(screenWidth, scorePercent, isPassed),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildTimeInfo(screenWidth),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildQuestionBreakdown(screenWidth),
                    if (_canRevealMore && !_isActivated) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _buildRevealButton(),
                    ],
                    if (!_isActivated && _visibleResultsCount < totalQuestions) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildActivationBanner(screenWidth),
                    ],
                    const SizedBox(height: AppSpacing.massive),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Résultats de l\'Examen', style: AppTextStyles.titleMedium),
                Text('Analyse de performance', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.share, size: 18, color: AppColors.primary),
              onPressed: _showShareDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHero(double screenWidth, int scorePercent, bool isPassed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPassed
              ? [AppColors.success, AppColors.successDark]
              : [AppColors.error, AppColors.errorDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Pass/fail badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Text(
              isPassed ? 'ADMIS' : 'ÉCHOUÉ',
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Score
          Text(
            '$correctAnswers / $totalQuestions',
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              fontSize: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$scorePercent% de réussite',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(double screenWidth) {
    final totalMinutes = (timeSpent / 60).floor();
    final totalSeconds = timeSpent % 60;
    final timeStr = '${totalMinutes.toString().padLeft(2, '0')}:${totalSeconds.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.cardSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text('Temps écoulé : ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(
            timeStr,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBreakdown(double screenWidth) {
    final visibleResults = results.take(_visibleResultsCount).toList();
    final hiddenResults = results.skip(_visibleResultsCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View toggle
        Row(
          children: [
            _buildFilterChip('Toutes', true),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('Correctes', false),
            const SizedBox(width: AppSpacing.sm),
            _buildFilterChip('Incorrectes', false),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Visible results grid
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.cardSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.visibility, color: Colors.white, size: 14),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Questions 1–$_visibleResultsCount',
                      style: AppTextStyles.titleSmall,
                    ),
                  ),
                  Text(
                    '${visibleResults.where((r) => r['isCorrect'] == true).length}/${visibleResults.length}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Grid of question indicators
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: visibleResults.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final result = entry.value;
                  final questionNum = idx + 1;
                  final isCorrect = result['isCorrect'] == true;

                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: isCorrect ? AppColors.success : AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$questionNum',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isCorrect ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Hidden results (blurred)
        if (hiddenResults.isNotEmpty && !_isActivated) ...[
          const SizedBox(height: AppSpacing.md),
          _buildBlurredSection(hiddenResults),
        ],
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildBlurredSection(List<Map<String, dynamic>> hiddenResults) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.white, size: 14),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Questions ${_visibleResultsCount + 1}–$totalQuestions',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textMuted),
                ),
              ),
              Text(
                '${hiddenResults.length} masquées',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real content (will be blurred)
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: hiddenResults.take(10).map((result) {
                      final questionNum = results.indexOf(result) + 1;
                      final isCorrect = result['isCorrect'] == true;
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Center(
                          child: Text(
                            '$questionNum',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isCorrect ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Blur overlay
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _onActivatePressed,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: Container(
                          color: AppColors.surface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  // Lock icon centered
                  Center(
                    child: GestureDetector(
                      onTap: _onActivatePressed,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Activer pour voir',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _revealMoreResults,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: Text(
          'Révéler plus de résultats',
          style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildActivationBanner(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.ctaLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: AppColors.accent, size: 32),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voir tous les résultats',
                  style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                ),
                Text(
                  'Débloquez les corrections détaillées',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _onActivatePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              elevation: 0,
            ),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    final scorePercent = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager le résultat'),
        content: Text('Score: $correctAnswers/$totalQuestions ($scorePercent%)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
