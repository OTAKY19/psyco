import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../models/question.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';
import '../../services/database_service.dart';
import '../../services/user_state_service.dart';
import '../../utils/memory_question_utils.dart';
import '../test_taking_screen/widgets/question_content_widget.dart';

class PremiumExamScreen extends StatefulWidget {
  final Map<String, dynamic>? examConfig;

  const PremiumExamScreen({super.key, this.examConfig});

  @override
  State<PremiumExamScreen> createState() => _PremiumExamScreenState();
}

class _PremiumExamScreenState extends State<PremiumExamScreen>
    with TickerProviderStateMixin {
  // Services
  final DatabaseService _databaseService = DatabaseService();

  // Exam Data
  List<Question> examQuestions = [];
  bool _isLoading = true;
  String? _error;

  // Exam State
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  Timer? examTimer;
  int remainingTimeInSeconds = 2400; // 40 minutes for demo
  PageController pageController = PageController();

  // Exam Configuration
  late final String examType;
  late final int totalQuestions;
  late final int timeLimit;

  @override
  void initState() {
    super.initState();

    // Default exam configuration - 40 questions pour le système de démo
    examType = widget.examConfig?['type'] ?? 'concours_douane';
    totalQuestions = widget.examConfig?['questionCount'] ?? 40;
    timeLimit = widget.examConfig?['timeLimit'] ?? 2400;

    remainingTimeInSeconds = timeLimit;
    _loadExamQuestions();
  }

  @override
  void dispose() {
    examTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExamQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load questions from all categories for a complete exam
      List<Question> allQuestions = [];

      // Load questions from each category proportionally
      final categories = [
        'raisonnement_logique',
        'aptitude_numerique',
        'aptitude_verbale',
        'culture_generale',
        'memoire_attention',
        'raisonnement_spatial',
        'rapidite_personnalite'
      ];

      final questionsPerCategory = (totalQuestions / categories.length).round();

      for (final category in categories) {
        try {
          final categoryQuestions = await _databaseService.getRandomQuestions(
            limit: questionsPerCategory,
            category: category,
          );
          allQuestions.addAll(categoryQuestions);
        } catch (e) {
          debugPrint('Error loading questions for category $category: $e');
        }
      }

      // If we don't have enough questions, fill with general questions
      if (allQuestions.length < totalQuestions) {
        final remaining = totalQuestions - allQuestions.length;
        final generalQuestions =
            await _databaseService.getRandomQuestions(limit: remaining);
        allQuestions.addAll(generalQuestions);
      }

      // Shuffle and limit to exact number
      allQuestions.shuffle();
      examQuestions = allQuestions.take(totalQuestions).toList();

      if (examQuestions.isEmpty) {
        throw Exception('Aucune question disponible pour l\'examen');
      }

      setState(() {
        _isLoading = false;
      });

      // Start exam
      _startExam();
    } catch (e) {
      debugPrint('Error loading exam questions: $e');
      setState(() {
        _error = 'Erreur lors du chargement de l\'examen: $e';
        _isLoading = false;
      });
    }
  }

  void _startExam() {
    if (examQuestions.isEmpty) return;

    // Start exam timer
    examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTimeInSeconds > 0) {
        setState(() {
          remainingTimeInSeconds--;
        });

        // Auto-submit when time is up
        if (remainingTimeInSeconds == 0) {
          _submitExam();
        }
      }
    });

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Prevent screenshots (Android only)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Seuils Stitch : normal > 20min, warning entre 10 et 20min, danger < 10min
  bool get _timerIsDanger => remainingTimeInSeconds <= 600;
  bool get _timerIsWarn =>
      remainingTimeInSeconds > 600 && remainingTimeInSeconds <= 1200;

  void _goToPreviousQuestion() {
    if (currentQuestionIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        currentQuestionIndex--;
      });
      pageController.animateToPage(
        currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextQuestion() {
    if (currentQuestionIndex < examQuestions.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        currentQuestionIndex++;
      });
      pageController.animateToPage(
        currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showSubmitConfirmation();
    }
  }

  void _goToQuestion(int questionNumber) {
    final index = questionNumber - 1;
    if (index >= 0 && index < examQuestions.length) {
      HapticFeedback.selectionClick();
      setState(() {
        currentQuestionIndex = index;
      });
      pageController.animateToPage(
        currentQuestionIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Navigator.pop(context); // Close bottom sheet
    }
  }

  void _showQuestionGrid() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.modalTop)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.iconContainer),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Questions de l\'examen',
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
            ),

            // Légende
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildLegendItem(AppColors.primary, 'Actuelle'),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.primaryContainer, 'Répondue'),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.surfaceContainer, 'Vierge'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: examQuestions.length,
                itemBuilder: (context, index) {
                  final questionNumber = index + 1;
                  final isAnswered = selectedAnswers.containsKey(index);
                  final isCurrent = currentQuestionIndex == index;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _goToQuestion(questionNumber),
                      borderRadius: BorderRadius.circular(AppRadii.cardSm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : isAnswered
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainer,
                          border: isCurrent
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(AppRadii.cardSm),
                        ),
                        child: Center(
                          child: Text(
                            questionNumber.toString(),
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: isCurrent
                                  ? AppColors.onPrimary
                                  : isAnswered
                                      ? AppColors.primaryDark
                                      : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadii.xs),
            border: color == AppColors.surfaceContainer
                ? Border.all(color: AppColors.border)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showSubmitConfirmation() {
    HapticFeedback.mediumImpact();
    final answeredCount = selectedAnswers.length;
    final totalCount = examQuestions.length;
    final unansweredCount = totalCount - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(AppRadii.iconContainer),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Terminer l\'examen',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir terminer l\'examen ? Cette action est irréversible.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.cardSm),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions répondues :',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$answeredCount/$totalCount',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (unansweredCount > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Questions non répondues :',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$unansweredCount',
                          style: AppTextStyles.buttonSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Temps restant :',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatTime(remainingTimeInSeconds),
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _timerIsDanger
                              ? AppColors.error
                              : _timerIsWarn
                                  ? AppColors.warning
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Continuer l\'examen'),
          ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _submitExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: const Text(
                'Terminer l\'examen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      ),
    );
  }

  void _submitExam() async {
    examTimer?.cancel();

    // Calculate results
    int correctAnswers = 0;
    final List<Map<String, dynamic>> results = [];

    for (int i = 0; i < examQuestions.length; i++) {
      final selectedAnswer = selectedAnswers[i];
      final question = examQuestions[i];
      final isCorrect = selectedAnswer != null &&
          question.options[selectedAnswer] == question.reponse;

      if (isCorrect) {
        correctAnswers++;
      }

      results.add({
        'questionIndex': i,
        'question': question.question,
        'selectedAnswer': selectedAnswer,
        'correctAnswer': question.options.indexOf(question.reponse),
        'isCorrect': isCorrect,
        'category': question.categorie,
      });
    }

    // Sauvegarder l'état de la démo
    final userStateService = UserStateService();
    final router = GoRouter.of(context);
    await userStateService.setDemoScore(correctAnswers);
    await userStateService.markDemoCompleted();

    // Navigate to results screen with progress system
    router.pushReplacement(
      AppRoutes.progressExamResults,
      extra: ExamResultRouteExtra(arguments: {
        'results': results,
        'totalQuestions': examQuestions.length,
        'correctAnswers': correctAnswers,
        'timeSpent': timeLimit - remainingTimeInSeconds,
        'examType': examType,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gestion des états de chargement et d'erreur
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Préparation de l\'examen...',
                style: AppTextStyles.titleMedium,
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.errorContainer,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 32,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Erreur de chargement',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loadExamQuestions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.button),
                      ),
                    ),
                    child: const Text(
                      'Réessayer',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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

    if (examQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warningContainer,
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    size: 32,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucune question disponible',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nous n\'avons pas pu charger les questions pour cet examen. Veuillez réessayer plus tard.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.button),
                      ),
                    ),
                    child: const Text(
                      'Retour',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête avec timer et type d'examen
            _buildHeader(),

            // Barre de progression fine
            _buildProgressBar(),

            // Bouton voir toutes les questions
            _buildViewAllQuestions(),

            // Contenu scrollable
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.cardSm),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                  boxShadow: AppShadows.cardSm,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.cardSm),
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentQuestionIndex = index;
                      });
                    },
                    itemCount: examQuestions.length,
                    itemBuilder: (context, index) {
                      final question = examQuestions[index];
                      return _buildQuestionPage(question, index);
                    },
                  ),
                ),
              ),
            ),

            // Navigation Précédent / Suivant
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  // Header fixe : retour, titre + sous-titre, timer pill
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: AppShadows.header,
      ),
      child: Padding(
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
                    'Concours de la Douane',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Examen Premium — $totalQuestions questions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildTimerPill(),
          ],
        ),
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
          onTap: _showExitConfirmation,
          child: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadii.iconContainer),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quitter l\'examen',
                style: AppTextStyles.titleMedium,
              ),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir quitter ? Votre progression sera perdue.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Annuler'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                examTimer?.cancel();
                Navigator.pop(context);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: const Text(
                'Quitter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      ),
    );
  }

  Widget _buildTimerPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _timerIsDanger
            ? AppColors.error
            : _timerIsWarn
                ? AppColors.warning
                : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: _timerIsDanger || _timerIsWarn
                ? AppColors.onPrimary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            _formatTime(remainingTimeInSeconds),
            style: AppTextStyles.buttonSmall.copyWith(
              color: _timerIsDanger || _timerIsWarn
                  ? AppColors.onPrimary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Barre de progression fine
  Widget _buildProgressBar() {
    final double progress = examQuestions.isEmpty
        ? 0
        : (currentQuestionIndex + 1) / examQuestions.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sm,
        AppSpacing.pageHorizontal,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: AppColors.surfaceDim,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  // Bouton Voir toutes les questions
  Widget _buildViewAllQuestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showQuestionGrid,
          borderRadius: BorderRadius.circular(AppRadii.cardSm),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadii.cardSm),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Voir toutes les questions',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.badge),
                  ),
                  child: Text(
                    '${selectedAnswers.length}/${examQuestions.length}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Page question : carte + options (avec gestion mémoire)
  Widget _buildQuestionPage(Question question, int index) {
    final bool isMemory = MemoryQuestionUtils.isMemoryQuestion(question.question);

    if (isMemory) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionCard(question, index),
            const SizedBox(height: 16),
            QuestionContentWidget(
              questionText: question.question,
              options: question.options,
              selectedOption: selectedAnswers[index],
              onOptionSelected: (optionIndex) {
                if (currentQuestionIndex == index) {
                  setState(() {
                    selectedAnswers[index] = optionIndex;
                  });
                  HapticFeedback.lightImpact();
                }
              },
              questionImage: question.imagePath,
            ),
          ],
        ),
      );
    }

    final int? selected = selectedAnswers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCard(question, index),
          const SizedBox(height: 16),
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

  // Carte question : numéro + catégorie + texte
  Widget _buildQuestionCard(Question question, int index) {
    return Container(
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
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: AppTextStyles.titleSmall,
                    ),
                    Text(
                      _categoryLabel(question.categorie),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.badge),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Text(
                  _categoryLabel(question.categorie),
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(
            height: 1,
            color: AppColors.surfaceDim,
          ),
          const SizedBox(height: 16),
          Text(
            'Question',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.question,
            style: AppTextStyles.quizQuestion.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        onTap: () {
          if (currentQuestionIndex == index) {
            setState(() {
              selectedAnswers[index] = optionIndex;
            });
            HapticFeedback.lightImpact();
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
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
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

  // Navigation Précédent / Suivant avec position
  Widget _buildNavigationBar() {
    final bool hasAnswer =
        selectedAnswers.containsKey(currentQuestionIndex);
    final bool isLast = currentQuestionIndex == examQuestions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '${currentQuestionIndex + 1} / ${examQuestions.length}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (currentQuestionIndex > 0) ...[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _goToPreviousQuestion,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.buttonPill),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_ios, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Précédent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: currentQuestionIndex > 0 ? 1 : 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: hasAnswer || isLast ? _goToNextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.surfaceDim,
                        foregroundColor: AppColors.onPrimary,
                        disabledForegroundColor: AppColors.textMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.buttonPill),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Terminer' : 'Suivant',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (!isLast) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(String raw) {
    switch (raw) {
      case 'raisonnement_logique':
        return 'Logique & Raisonnement';
      case 'aptitude_numerique':
      case 'mathematiques':
        return 'Calcul & Aptitude Numérique';
      case 'aptitude_verbale':
        return 'Aptitude Verbale';
      case 'raisonnement_spatial':
        return 'Raisonnement Spatial';
      case 'memoire_attention':
        return 'Mémoire & Attention';
      case 'rapidite_personnalite':
        return 'Rapidité & Personnalité';
      case 'culture_generale':
        return 'Culture Générale';
      case 'francais':
        return 'Français';
      case 'droit_douane':
        return 'Droit de la Douane';
      case 'logique':
        return 'Séries & Logique';
      default:
        return raw.isEmpty ? 'Sujet' : raw;
    }
  }
}