import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../models/question.dart';
import '../../services/database_service.dart';
import '../../widgets/unified_activation_widget.dart';
import '../../widgets/unified_results_widget.dart';

class DemoExamScreen extends StatefulWidget {
  final VoidCallback onDemoCompleted;
  final VoidCallback onUpgradeNow;

  const DemoExamScreen({
    super.key,
    required this.onDemoCompleted,
    required this.onUpgradeNow,
  });

  @override
  State<DemoExamScreen> createState() => _DemoExamScreenState();
}

class _DemoExamScreenState extends State<DemoExamScreen> {
  // Services
  final DatabaseService _databaseService = DatabaseService();

  // Demo Data
  List<Question> demoQuestions = [];
  bool _isLoading = true;
  String? _error;

  // Demo State
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  Timer? questionTimer;
  Timer? activationTimer;
  int remainingTimeInSeconds = 60; // 1 minute par question
  bool _showResults = false;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadDemoQuestions();

    // Protection contre les captures d'écran en mode démo
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Bloquer l'orientation en portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _loadDemoQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Mode démo : 15 questions aléatoires de toutes les catégories
      final questions = await _databaseService.getRandomQuestions(limit: 15);

      if (questions.isEmpty) {
        throw Exception('Aucune question trouvée pour la démo');
      }

      setState(() {
        demoQuestions = questions;
        _isLoading = false;
      });

      _startQuestionTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startQuestionTimer() {
    questionTimer?.cancel();
    remainingTimeInSeconds = 60; // Reset à 1 minute

    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeInSeconds > 0) {
        setState(() {
          remainingTimeInSeconds--;
        });
      } else {
        // Temps écoulé, passer à la question suivante
        _nextQuestion();
      }
    });
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;
    });

    // Passer à la question suivante après une courte pause
    Timer(const Duration(milliseconds: 500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < demoQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _startQuestionTimer();

      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Fin de la démo
      _finishDemo();
    }
  }

  void _finishDemo() {
    questionTimer?.cancel();

    setState(() {
      _showResults = true;
    });

    // Démarrer le timer pour la popup d'activation (60 secondes)
    activationTimer = Timer(const Duration(seconds: 60), () {
      _showActivationPopup();
    });
  }

  void _showActivationPopup() {
    UnifiedActivationWidget.show(
      context,
      contextMessage: 'Votre score démo: ${_calculateScore()}%',
      featureName: 'Analyse complète des résultats',
      description: 'Activez PsychoTest+ pour accéder à toutes les fonctionnalités et voir les explications détaillées de toutes vos réponses.',
    ).then((_) {
      // Après fermeture de la popup, retourner à l'écran principal
      widget.onDemoCompleted();
    });
  }

  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < demoQuestions.length; i++) {
      final selectedAnswer = selectedAnswers[i];
      if (selectedAnswer != null) {
        final question = demoQuestions[i];
        final correctAnswerIndex = question.options.indexOf(question.reponse);
        if (selectedAnswer == correctAnswerIndex) {
          correctAnswers++;
        }
      }
    }
    return ((correctAnswers / demoQuestions.length) * 100).round();
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    activationTimer?.cancel();
    pageController.dispose();

    // Restaurer les paramètres système après la démo
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppColors.background,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erreur: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showResults) {
      return _buildUnifiedResults();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: demoQuestions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(demoQuestions[index], index);
                },
              ),
            ),

            _buildDemoBanner(),
          ],
        ),
      ),
    );
  }

  // Header fixe : retour, titre + sous-titre, timer pill (rouge < 10s)
  Widget _buildHeader() {
    final bool danger = remainingTimeInSeconds <= 10;
    final double progress =
        (currentQuestionIndex + 1) / demoQuestions.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: AppShadows.header,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                _buildBackButton(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examen de Démonstration',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mode découverte chronométré',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.danger,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildTimerPill(danger),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.sm,
              AppSpacing.pageHorizontal,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1}/${demoQuestions.length}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
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

  Widget _buildBackButton() {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.iconContainer),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.iconContainer),
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTimerPill(bool danger) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: danger ? AppColors.error : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: danger ? AppColors.onPrimary : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            '${remainingTimeInSeconds}s',
            style: AppTextStyles.buttonSmall.copyWith(
              color: danger ? AppColors.onPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Corps de question : carte question + options A-D (sélection, pas de correction)
  Widget _buildQuestionPage(Question question, int index) {
    final int? selected = selectedAnswers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.cardSm),
              border: Border.all(color: AppColors.borderLight, width: 1),
              boxShadow: AppShadows.cardSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _categoryLabel(question.categorie),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  question.question,
                  style: AppTextStyles.quizQuestion.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Options A-D
          Text(
            'Choisissez votre réponse :',
            style: AppTextStyles.titleSmall,
          ),

          const SizedBox(height: AppSpacing.md),

          ...question.options.asMap().entries.map((entry) {
            final int optionIndex = entry.key;
            final bool isSelected = selected == optionIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildOptionRow(
                index: index,
                optionIndex: optionIndex,
                optionText: entry.value,
                isSelected: isSelected,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required int index,
    required int optionIndex,
    required String optionText,
    required bool isSelected,
  }) {
    final bool isCurrent = currentQuestionIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        onTap: () {
          if (isCurrent) {
            _selectAnswer(optionIndex);
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.cardSm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + optionIndex),
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  optionText,
                  style: AppTextStyles.quizOption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bandeau « Mode démonstration »
  Widget _buildDemoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        0,
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.dangerContainer,
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 20,
            color: AppColors.danger,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode démonstration',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '15 questions gratuites. Activez PsychoTest+ pour les 30 questions et les explications détaillées.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'raisonnement_logique':
        return 'Logique';
      case 'aptitude_numerique':
        return 'Mathématiques';
      case 'aptitude_verbale':
        return 'Français';
      case 'culture_generale':
        return 'Culture Générale';
      case 'memoire_attention':
        return 'Mémoire';
      case 'raisonnement_spatial':
        return 'Spatial';
      case 'rapidite_personnalite':
        return 'Rapidité';
      default:
        return category;
    }
  }

  Widget _buildUnifiedResults() {
    final score = _calculateScore();
    final correctAnswers = selectedAnswers.entries.where((entry) {
      final question = demoQuestions[entry.key];
      final correctAnswerIndex = question.options.indexOf(question.reponse);
      return entry.value == correctAnswerIndex;
    }).length;

    // Préparer les données pour le widget unifié
    final testResults = {
      'scorePercentage': score.toDouble(),
      'correctAnswers': correctAnswers,
      'totalQuestions': demoQuestions.length,
    };

    final questionsData = demoQuestions.asMap().entries.map((entry) {
      final index = entry.key;
      final question = entry.value;
      final userAnswer = selectedAnswers[index];
      final correctAnswerIndex = question.options.indexOf(question.reponse);

      return {
        'questionText': question.question,
        'options': question.options,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswerIndex,
        'explanation': question.explication,
      };
    }).toList();

    return UnifiedResultsWidget(
      testResults: testResults,
      questions: questionsData,
      isDemoMode: true, // Mode démo activé pour le flou
      onBackToMenu: widget.onDemoCompleted,
      onRetakeTest: () {
        // Réinitialiser et recommencer la démo
        setState(() {
          currentQuestionIndex = 0;
          selectedAnswers.clear();
          _showResults = false;
          remainingTimeInSeconds = 60;
        });
        pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startQuestionTimer();
      },
    );
  }
}