import 'dart:async';
import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../models/simulation_model.dart';
import '../../services/simulation_service.dart';

class SimulationScreen extends StatefulWidget {
  final String userId;
  final SimulationModel? simulation;

  const SimulationScreen({
    super.key,
    required this.userId,
    this.simulation,
  });

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final SimulationService _simulationService = SimulationService();
  late SimulationSession _session;
  Timer? _timer;
  Timer? _questionTimer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSimulation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _session = await _simulationService.createSimulationSession(widget.userId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showStartDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors de l\'initialisation: $e';
        });
      }
    }
  }

  void _showStartDialog() {
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
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Simulation Test Douane Bénin',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogInfo('40 questions à répondre'),
                    _buildDialogInfo('Durée totale: 40 minutes'),
                    _buildDialogInfo('1 minute par question'),
                    _buildDialogInfo('Pas de retour en arrière possible'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Êtes-vous prêt à commencer ?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _abandonSimulation();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: Text(
                        'Abandonner',
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
                        Navigator.of(context).pop();
                        _startSimulation();
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
                        'Commencer',
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

  Widget _buildDialogInfo(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _startSimulation() {
    setState(() {
      _session = _simulationService.startSimulation(_session);
    });
    _startTimers();
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session.status != SimulationStatus.inProgress) {
        timer.cancel();
        return;
      }

      final remainingTime =
          _session.remainingTime - const Duration(seconds: 1);

      if (remainingTime.inSeconds <= 0) {
        _handleTimeUp();
        return;
      }

      setState(() {
        _session = _simulationService.updateRemainingTime(
          _session,
          remainingTime,
          _session.currentQuestionRemainingTime - const Duration(seconds: 1),
        );
      });
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session.status != SimulationStatus.inProgress) {
        timer.cancel();
        return;
      }

      final questionRemainingTime =
          _session.currentQuestionRemainingTime - const Duration(seconds: 1);

      if (questionRemainingTime.inSeconds <= 0) {
        _handleQuestionTimeUp();
        return;
      }

      setState(() {
        _session = _simulationService.updateRemainingTime(
          _session,
          _session.remainingTime,
          questionRemainingTime,
        );
      });
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    _questionTimer?.cancel();

    setState(() {
      _session = _simulationService.completeSimulationByTimeUp(_session);
    });

    _showTimeUpDialog();
  }

  void _handleQuestionTimeUp() {
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_session.currentQuestionIndex >= _session.questions.length - 1) {
      _completeSimulation();
      return;
    }

    setState(() {
      _session = _simulationService.nextQuestion(_session);
    });
  }

  void _answerQuestion(String selectedOption) {
    final currentQuestion = _simulationService.getCurrentQuestion(_session);
    if (currentQuestion == null) return;

    final timeSpent = _session.questionDuration -
        _session.currentQuestionRemainingTime;

    setState(() {
      _session = _simulationService.recordAnswer(
        _session,
        currentQuestion.id.toString(),
        selectedOption,
        timeSpent,
      );
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _completeSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();

    setState(() {
      _session = _simulationService.completeSimulation(_session);
    });

    _showResults();
  }

  void _abandonSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();

    setState(() {
      _session = _session.copyWith(
        status: SimulationStatus.abandoned,
        endTime: DateTime.now(),
      );
    });

    Navigator.of(context).pop();
  }

  void _showTimeUpDialog() {
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
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Temps écoulé !',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Le temps de 40 minutes est écoulé. Votre simulation est terminée.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showResults();
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
                    'Voir les résultats',
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

  void _showResults() {
    final result = _simulationService.calculateSimulationResult(_session);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => _SimulationResultsScreen(
          result: result,
          session: _session,
        ),
      ),
    );
  }

  void _pauseSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();

    setState(() {
      _session = _simulationService.pauseSimulation(_session);
    });

    _showPauseDialog();
  }

  void _resumeSimulation() {
    setState(() {
      _session = _simulationService.resumeSimulation(_session);
    });
    _startTimers();
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
                'Simulation en pause',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Voulez-vous reprendre la simulation ?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _abandonSimulation();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: Text(
                        'Abandonner',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resumeSimulation();
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
                        'Reprendre',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
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
                'Chargement de la simulation...',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
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
                  'Erreur',
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
                  onPressed: _initializeSimulation,
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
        ),
      );
    }

    if (_session.status != SimulationStatus.inProgress) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Session terminée',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final currentQuestion = _simulationService.getCurrentQuestion(_session);
    if (currentQuestion == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Aucune question disponible',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _session.status == SimulationStatus.inProgress) {
          _pauseSimulation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTimerHeader(),
              _buildProgressBar(),
              Expanded(
                child: _buildQuestionArea(currentQuestion),
              ),
              _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerHeader() {
    final timeProgress = _simulationService.getTimeProgress(_session);
    final isUrgent = _session.remainingTime.inSeconds <= 300;

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
                onTap: _pauseSimulation,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDim,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: const Icon(
                    Icons.pause,
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
                      'Simulation Test Douane',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Question ${_session.currentQuestionIndex + 1}/${_session.questions.length}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.errorContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  _simulationService.formatTime(_session.remainingTime),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isUrgent ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: LinearProgressIndicator(
              value: timeProgress,
              backgroundColor: AppColors.surfaceDim,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUrgent ? AppColors.error : AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final questionProgress = _simulationService.getProgress(_session);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'Question ${_session.currentQuestionIndex + 1}/${_session.questions.length}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '${(questionProgress * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(SimulationQuestion currentQuestion) {
    final questionTimeProgress =
        _simulationService.getQuestionTimeProgress(_session);
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
          // Question timer bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${_session.currentQuestionRemainingTime.inSeconds}s',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    child: LinearProgressIndicator(
                      value: questionTimeProgress,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        questionTimeProgress > 0.5
                            ? AppColors.primary
                            : questionTimeProgress > 0.25
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.card,
            ),
            child: Text(
              currentQuestion.question,
              style: AppTextStyles.quizQuestion.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Options
          ...List.generate(currentQuestion.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () => _answerQuestion(currentQuestion.options[index]),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: optionColors[index],
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Center(
                          child: Text(
                            optionLabels[index],
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          currentQuestion.options[index],
                          style: AppTextStyles.quizOption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
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

  Widget _buildNavigation() {
    final hasNext = _session.currentQuestionIndex < _session.questions.length - 1;

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
          if (!hasNext)
            Expanded(
              child: ElevatedButton(
                onPressed: _completeSimulation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Terminer',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: AppColors.onPrimary,
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
}

class _SimulationResultsScreen extends StatelessWidget {
  final SimulationResult result;
  final SimulationSession session;

  const _SimulationResultsScreen({
    required this.result,
    required this.session,
  });

  bool get _passed => result.score >= 0.6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildResultHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildTimeAndLevel(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _passed
              ? [AppColors.success, AppColors.successDark]
              : [AppColors.error, AppColors.errorDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            color: AppColors.onPrimary,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Score final',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.formattedScore,
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _passed ? 'ADMIS' : 'ÉCHOUÉ',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.8),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Correctes',
          '${result.correctAnswers}',
          AppColors.success,
          Icons.check_circle,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildStatCard(
          'Incorrectes',
          '${result.incorrectAnswers}',
          AppColors.error,
          Icons.cancel,
        ),
        const SizedBox(width: AppSpacing.md),
        _buildStatCard(
          'Non répondues',
          '${result.unansweredQuestions}',
          AppColors.warning,
          Icons.help_outline,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAndLevel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _buildResultRow(
            'Temps total',
            result.formattedTime,
            Icons.timer_outlined,
            AppColors.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.borderLight),
          ),
          _buildResultRow(
            'Niveau',
            result.level.toUpperCase(),
            Icons.assessment,
            _passed ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
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
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Retour'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
