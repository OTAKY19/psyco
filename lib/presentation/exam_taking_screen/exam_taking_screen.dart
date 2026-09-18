import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../services/exam_blanc_service.dart';
import '../../services/subscription_service.dart';
import '../../services/test_service.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';

class ExamTakingScreen extends StatefulWidget {
  final ExamBlancSession session;

  const ExamTakingScreen({
    super.key,
    required this.session,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen>
    with SingleTickerProviderStateMixin {
  late ExamBlancSession _session;
  late Timer _examTimer;
  final SubscriptionService _subscriptionService = SubscriptionService();

  int _remainingTimeInSeconds = 0;
  int _questionRemainingTime = 0;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool _showQuestionGrid = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _remainingTimeInSeconds = _session.exam.duration.inSeconds;
    _questionRemainingTime = _session.exam.questionDuration.inSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startExam();
  }

  @override
  void dispose() {
    _examTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startExam() {
    _session.start();
    _startTimers();
  }

  void _startTimers() {
    // Un seul ticker 1s pour les deux compteurs (E6) : un seul rebuild/s.
    _examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused || _isCompleted) return;
      setState(() {
        _remainingTimeInSeconds--;
        _questionRemainingTime--;
      });

      if (_remainingTimeInSeconds <= 0) {
        _completeExam();
      } else if (_questionRemainingTime <= 0) {
        _autoNextQuestion();
      }
    });
  }

  void _answerQuestion(int optionIndex) {
    setState(() {
      _session.answerQuestion(optionIndex);
    });
    HapticFeedback.lightImpact();
    _saveProgress();
  }

  void _nextQuestion() {
    if (_session.hasNext) {
      setState(() {
        _session.nextQuestion();
        _questionRemainingTime = _session.exam.questionDuration.inSeconds;
      });
    } else {
      _completeExam();
    }
  }

  void _previousQuestion() {
    if (_session.hasPrevious) {
      setState(() {
        _session.previousQuestion();
        _questionRemainingTime = _session.exam.questionDuration.inSeconds;
      });
    }
  }

  void _autoNextQuestion() {
    if (_session.hasNext) {
      _nextQuestion();
    } else {
      _completeExam();
    }
  }

  void _pauseExam() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _showPauseDialog();
    }
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.warningContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle,
                  color: AppColors.warning,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Examen en pause',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPauseStat(
                'Temps restant',
                _formatTime(_remainingTimeInSeconds),
                Icons.timer_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPauseStat(
                'Question',
                '${_session.currentQuestionIndex + 1}/${_session.exam.totalQuestions}',
                Icons.help_outline,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pauseExam();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: Text(
                        'Reprendre',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _completeExam();
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
                        'Terminer',
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

  Widget _buildPauseStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _completeExam() {
    _isCompleted = true;
    _examTimer.cancel();

    _session.complete();

    final result = ExamBlancService().calculateResult(_session);

    _checkSubscriptionAndShowResults(result);
  }

  Future<void> _checkSubscriptionAndShowResults(ExamBlancResult result) async {
    final isPremium = await _subscriptionService.isPremiumUser();

    if (!isPremium) {
      await _subscriptionService.markFreeTestUsed();
    }

    // Historique réel pour l'accueil filières.
    unawaited(TestService().recordCompletedTest(
      testId: result.examId,
      category: 'examen_blanc',
      correctAnswers: result.correctAnswers,
      totalQuestions: result.totalQuestions,
      durationSeconds: result.timeSpent.inSeconds,
    ));

    if (mounted) {
      context.pushReplacement(
        AppRoutes.examResults,
        extra: ExamResultRouteExtra(result: result),
      );
    }
  }

  void _saveProgress() {}

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingTimeInSeconds <= 300) return AppColors.error;
    if (_remainingTimeInSeconds <= 600) return AppColors.warning;
    return AppColors.success;
  }

  Color _getQuestionTimerColor() {
    if (_questionRemainingTime <= 10) return AppColors.error;
    if (_questionRemainingTime <= 30) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildExamHeader(size),
              Expanded(
                child: _showQuestionGrid
                    ? _buildQuestionGrid(size)
                    : _buildQuestionArea(size),
              ),
              if (!_showQuestionGrid) _buildNavigationBar(size),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamHeader(Size size) {
    final timerProgress = _remainingTimeInSeconds /
        _session.exam.duration.inSeconds;
    final questionProgress =
        _questionRemainingTime / _session.exam.questionDuration.inSeconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showExitDialog,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _session.exam.title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Question ${_session.currentQuestionIndex + 1}/${_session.exam.totalQuestions}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              _buildCountdownTimer(),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _pauseExam,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isPaused
                        ? AppColors.warningContainer
                        : AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: _isPaused ? AppColors.warning : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Examen',
                          style: AppTextStyles.labelSmall,
                        ),
                        Text(
                          _formatTime(_remainingTimeInSeconds),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getTimerColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      child: LinearProgressIndicator(
                        value: timerProgress,
                        backgroundColor: AppColors.surfaceDim,
                        valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question',
                          style: AppTextStyles.labelSmall,
                        ),
                        Text(
                          _formatTime(_questionRemainingTime),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _getQuestionTimerColor(),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      child: LinearProgressIndicator(
                        value: questionProgress,
                        backgroundColor: AppColors.surfaceDim,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            _getQuestionTimerColor()),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final isUrgent = _remainingTimeInSeconds <= 300;

    return _ExamAnimatedBuilder(
      listenable: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isUrgent
                ? AppColors.error.withValues(alpha: 0.1 + (_pulseController.value * 0.1))
                : AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: isUrgent
                ? Border.all(
                    color: AppColors.error.withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                    width: 1.5,
                  )
                : null,
          ),
          child: Text(
            _formatTime(_remainingTimeInSeconds),
            style: AppTextStyles.titleMedium.copyWith(
              color: isUrgent ? AppColors.error : AppColors.primary,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionArea(Size size) {
    final question = _session.currentQuestion;
    final selectedAnswer = _session.userAnswers[_session.currentQuestionIndex];
    final optionLabels = ['A', 'B', 'C', 'D'];
    final optionColors = [
      AppColors.quizA,
      AppColors.quizB,
      AppColors.quizC,
      AppColors.quizD,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.card,
            ),
            child: Text(
              question.question,
              style: AppTextStyles.quizQuestion.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(question.options.length, (index) {
            final isSelected = selectedAnswer == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () => _answerQuestion(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? optionColors[index].withValues(alpha: 0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: isSelected
                          ? optionColors[index]
                          : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? AppShadows.cardSm : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? optionColors[index]
                              : AppColors.surfaceDim,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Center(
                          child: Text(
                            optionLabels[index],
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: AppTextStyles.quizOption.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: optionColors[index],
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(Size size) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _session.hasPrevious ? _previousQuestion : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _session.hasPrevious
                    ? AppColors.surfaceDim
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: _session.hasPrevious
                    ? AppColors.textPrimary
                    : AppColors.disabled,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showQuestionGrid = true),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.grid_view,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${_session.answeredCount}/${_session.exam.totalQuestions}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _session.hasNext ? _nextQuestion : _completeExam,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _session.hasNext ? AppColors.primary : AppColors.success,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                _session.hasNext ? Icons.arrow_forward_ios : Icons.check,
                color: AppColors.onPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionGrid(Size size) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.grid_view,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Questions de l\'examen',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showQuestionGrid = false),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _session.exam.totalQuestions,
              itemBuilder: (context, index) {
                final isAnswered = _session.userAnswers.containsKey(index);
                final isCurrent = _session.currentQuestionIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _session.currentQuestionIndex = index;
                      _questionRemainingTime =
                          _session.exam.questionDuration.inSeconds;
                      _showQuestionGrid = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary
                          : isAnswered
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : isAnswered
                                ? AppColors.success
                                : AppColors.border,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isCurrent
                              ? AppColors.onPrimary
                              : isAnswered
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showQuestionGrid = false),
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
                'Retour aux questions',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
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
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quitter l\'examen',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Êtes-vous sûr de vouloir quitter l\'examen ? Votre progrès sera perdu.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
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
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Quitter',
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
}

class _ExamAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const _ExamAnimatedBuilder({
    required super.listenable,
    required this.builder,
  });

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
