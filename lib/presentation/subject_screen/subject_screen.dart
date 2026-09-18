import 'dart:async';
import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../models/question.dart';
import '../../services/database_service.dart';
import '../../utils/memory_question_utils.dart';
import '../test_taking_screen/widgets/question_content_widget.dart';

class SubjectScreen extends StatefulWidget {
  final Map<String, dynamic>? subjectData;

  const SubjectScreen({super.key, this.subjectData});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen>
    with TickerProviderStateMixin {
  // Services
  final DatabaseService _databaseService = DatabaseService();

  // Subject Data
  List<Question> subjectQuestions = [];
  bool _isLoading = true;
  String? _error;

  // Subject State
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  Timer? questionTimer;
  int remainingTimeInSeconds = 60; // 1 minute par question
  bool _showExplanation = false;
  bool _hasAnswered = false;
  PageController pageController = PageController();

  // Animation Controllers
  late AnimationController _explanationController;
  late Animation<double> _explanationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuestions();
  }

  void _setupAnimations() {
    _explanationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _explanationAnimation = CurvedAnimation(
      parent: _explanationController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final category = widget.subjectData?['category'] ?? 'logique';
      final allQuestions = await _databaseService.getQuestionsByCategory(category);
      final questions = allQuestions.take(15).toList(); // 15 questions par sujet

      if (questions.isEmpty) {
        throw Exception('Aucune question trouvée pour cette catégorie');
      }

      setState(() {
        subjectQuestions = questions;
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
        _skipQuestion();
      }
    });
  }

  void _selectAnswer(int answerIndex) {
    if (_hasAnswered) return;

    setState(() {
      selectedAnswers[currentQuestionIndex] = answerIndex;
      _hasAnswered = true;
    });

    // Arrêter le timer
    questionTimer?.cancel();

    // Afficher l'explication immédiatement
    _showExplanationWithAnimation();
  }

  void _showExplanationWithAnimation() {
    setState(() {
      _showExplanation = true;
    });
    _explanationController.forward();

    // Passer à la question suivante après 3 secondes
    Timer(const Duration(seconds: 3), () {
      _nextQuestion();
    });
  }

  void _skipQuestion() {
    // Marquer comme non répondu et passer à la suivante
    _nextQuestion();
  }

  void _nextQuestion() {
    if (currentQuestionIndex < subjectQuestions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        _showExplanation = false;
        _hasAnswered = false;
      });
      _explanationController.reset();
      _startQuestionTimer();

      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Fin du sujet
      _finishSubject();
    }
  }

  void _finishSubject() {
    questionTimer?.cancel();

    // Calculer le score
    int correctAnswers = 0;
    for (int i = 0; i < subjectQuestions.length; i++) {
      final selectedAnswer = selectedAnswers[i];
      if (selectedAnswer != null) {
        final question = subjectQuestions[i];
        final correctAnswerIndex = question.options.indexOf(question.reponse);
        if (selectedAnswer == correctAnswerIndex) {
          correctAnswers++;
        }
      }
    }

    // Retourner à l'écran précédent avec le score
    Navigator.pop(context, {
      'score': correctAnswers,
      'total': subjectQuestions.length,
      'answers': selectedAnswers,
    });
  }

  void _leaveFlow() {
    questionTimer?.cancel();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    _explanationController.dispose();
    pageController.dispose();
    super.dispose();
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

  bool _isMemoryQuestion(String questionText) =>
      MemoryQuestionUtils.isMemoryQuestion(questionText);

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
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                itemCount: subjectQuestions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionWithExplanation(
                    subjectQuestions[index],
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Header fixe : retour, titre + sous-titre, timer pill
  Widget _buildHeader() {
    final bool danger = remainingTimeInSeconds <= 10;
    final double progress =
        (currentQuestionIndex + 1) / subjectQuestions.length;

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
                        widget.subjectData?['name'] ?? 'Sujet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Entraînement chronométré',
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
                  'Question ${currentQuestionIndex + 1}/${subjectQuestions.length}',
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

  Widget _buildQuestionWithExplanation(Question question, int index) {
    final bool isMemory = _isMemoryQuestion(question.question);

    if (isMemory) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.md,
          AppSpacing.pageHorizontal,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionContentWidget(
              questionText: question.question,
              options: question.options,
              selectedOption: selectedAnswers[index],
              onOptionSelected: (optionIndex) {
                if (!_hasAnswered && currentQuestionIndex == index) {
                  _selectAnswer(optionIndex);
                }
              },
              questionImage: question.imagePath,
            ),
            if (_showExplanation && currentQuestionIndex == index)
              _buildExplanation(question),
          ],
        ),
      );
    }

    final int? selected = selectedAnswers[index];
    final int correctIndex = question.options.indexOf(question.reponse);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
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
                      Icons.assistant_direction_outlined,
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

          // Options
          Text(
            'Choisissez votre réponse :',
            style: AppTextStyles.titleSmall,
          ),

          const SizedBox(height: AppSpacing.md),

          ...question.options.asMap().entries.map((entry) {
            final int optionIndex = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildOptionRow(
                index: index,
                optionIndex: optionIndex,
                optionText: entry.value,
                selected: selected,
                correctIndex: correctIndex,
              ),
            );
          }),

          // Explication (avec animation) - seulement pour la question actuelle
          if (_showExplanation && currentQuestionIndex == index)
            AnimatedBuilder(
              animation: _explanationAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _explanationAnimation.value,
                  child: Opacity(
                    opacity: _explanationAnimation.value,
                    child: _buildExplanation(question),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOptionRow({
    required int index,
    required int optionIndex,
    required String optionText,
    required int? selected,
    required int correctIndex,
  }) {
    final bool isCurrent = currentQuestionIndex == index;
    final bool isSelected = selected == optionIndex;
    final bool showResult = _hasAnswered && isCurrent;
    final bool isCorrect = optionIndex == correctIndex;

    Color borderColor;
    Color bgColor;
    Color letterBg;
    Color letterFg;
    Color textColor;
    IconData icon;
    Color iconColor;

    if (showResult) {
      if (isCorrect) {
        borderColor = AppColors.primary;
        bgColor = AppColors.primaryContainer;
        letterBg = AppColors.primary;
        letterFg = AppColors.onPrimary;
        textColor = AppColors.primaryDark;
        icon = Icons.check_circle;
        iconColor = AppColors.primary;
      } else if (isSelected) {
        borderColor = AppColors.error;
        bgColor = AppColors.dangerContainer;
        letterBg = AppColors.error;
        letterFg = AppColors.onPrimary;
        textColor = AppColors.errorDark;
        icon = Icons.cancel;
        iconColor = AppColors.error;
      } else {
        borderColor = AppColors.borderLight;
        bgColor = AppColors.surface;
        letterBg = AppColors.surfaceContainer;
        letterFg = AppColors.primary;
        textColor = AppColors.textPrimary;
        icon = Icons.radio_button_unchecked;
        iconColor = AppColors.textMuted;
      }
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primaryContainer;
      letterBg = AppColors.primary;
      letterFg = AppColors.onPrimary;
      textColor = AppColors.primaryDark;
      icon = Icons.check_circle;
      iconColor = AppColors.primary;
    } else {
      borderColor = AppColors.borderLight;
      bgColor = AppColors.surface;
      letterBg = AppColors.surfaceContainer;
      letterFg = AppColors.primary;
      textColor = AppColors.textPrimary;
      icon = Icons.radio_button_unchecked;
      iconColor = AppColors.textMuted;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        onTap: () {
          if (!_hasAnswered && isCurrent) {
            _selectAnswer(optionIndex);
          }
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.cardSm),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: letterBg,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + optionIndex),
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: letterFg,
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
                    color: textColor,
                    fontWeight: isSelected || (showResult && isCorrect)
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }

  // Carte explication « Règle d'or »
  Widget _buildExplanation(Question question) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.badgeFreeBg,
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Règle d\'or',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.explication,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom nav 3 onglets (Accueil / Épreuves / Bilan)
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.sm),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Accueil',
              active: true,
              onTap: _leaveFlow,
            ),
            _buildNavItem(
              icon: Icons.timer_outlined,
              selectedIcon: Icons.timer,
              label: 'Épreuves',
              active: false,
              onTap: _leaveFlow,
            ),
            _buildNavItem(
              icon: Icons.analytics_outlined,
              selectedIcon: Icons.analytics,
              label: 'Bilan',
              active: false,
              onTap: _leaveFlow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color color = active ? AppColors.primary : AppColors.textMuted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? selectedIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}