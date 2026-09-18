import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../router/app_routes.dart';
import '../../router/route_extras.dart';
import '../../services/test_service.dart';
import '../../services/user_state_service.dart';
import '../../services/subscription_service.dart';
import '../../models/question.dart';

class TestTakingScreen extends StatefulWidget {
  final Map<String, dynamic>? testData;

  const TestTakingScreen({super.key, this.testData});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int _currentIndex = 0;
  int _selectedOption = -1;
  String? _selectedAnswer;
  List<String?> _answers = [];
  final List<int> _markedQuestions = [];
  Timer? _timer;
  int _timeRemaining = 0;
  final DateTime _startTime = DateTime.now();

  static const String _partialKey = 'training_partial';

  String get _testId =>
      widget.testData?['id']?.toString() ?? 'default_test';

  @override
  void initState() {
    super.initState();
    final testService = Provider.of<TestService>(context, listen: false);
    if (widget.testData != null) {
      // Identité invité persistée (T3) : aucun compte requis.
      unawaited(UserStateService.ensureGuestUserId().then((guestId) {
        testService.startTest(
          widget.testData!['id'] ?? 'default_test',
          guestId,
        );
      }));
    }
    _timeRemaining = 30 * 60;
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeResume());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _finishTest();
      }
    });
  }

  String get _formattedTime {
    final m = _timeRemaining ~/ 60;
    final s = _timeRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_timeRemaining > 600) return AppColors.success;
    if (_timeRemaining > 120) return AppColors.quizB;
    return AppColors.error;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectOption(int index, String answer) {
    setState(() {
      _selectedOption = index;
      _selectedAnswer = answer;
    });
    _persistPartial();
  }

  /// Sauvegarde partielle (T11) : reprise après sortie accidentelle.
  void _persistPartial() {
    unawaited(SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
        _partialKey,
        jsonEncode({
          'testId': _testId,
          'index': _currentIndex,
          'answers': _answers,
          'remaining': _timeRemaining,
          'at': DateTime.now().toIso8601String(),
        }),
      );
    }));
  }

  /// Propose la reprise si une session partielle existe pour ce test.
  void _maybeResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_partialKey);
      if (raw == null || !mounted) return;
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (map['testId'] != _testId) return;
      final index = (map['index'] as num?)?.toInt() ?? 0;
      if (index <= 0) return;
      final resume = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reprendre le test ?'),
          content: Text('Vous étiez à la question ${index + 1}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Recommencer'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reprendre'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (resume == true) {
        setState(() {
          _currentIndex = index;
          _answers = (map['answers'] as List? ?? [])
              .map((e) => e as String?)
              .toList();
          _timeRemaining =
              (map['remaining'] as num?)?.toInt() ?? _timeRemaining;
          _selectedOption = -1;
          _selectedAnswer = null;
        });
      } else {
        await prefs.remove(_partialKey);
      }
    } catch (_) {
      // Une sauvegarde illisible ne doit jamais bloquer le test.
    }
  }

  /// Sortie protégée (T11) : quitter sauvegarde, abandonner efface.
  void _confirmExit() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitter le test ?'),
        content: const Text(
          'Votre progression est sauvegardée. Vous pourrez reprendre plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Rester'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(_partialKey);
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    final testService = Provider.of<TestService>(context, listen: false);
    final total = testService.questions.length;
    if (_currentIndex < total - 1) {
      if (_selectedAnswer != null) {
        testService.submitAnswer(_selectedAnswer!);
        if (_answers.length <= _currentIndex) {
          _answers.add(_selectedAnswer);
        } else {
          _answers[_currentIndex] = _selectedAnswer;
        }
      }
      setState(() {
        _currentIndex++;
        _selectedOption = -1;
        _selectedAnswer = null;
      });
      _persistPartial();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        final prevAnswer = _answers.length > _currentIndex
            ? _answers[_currentIndex]
            : null;
        _selectedOption = prevAnswer != null ? -1 : -1;
        _selectedAnswer = prevAnswer;
      });
    }
  }

  void _jumpToQuestion(int index) {
    final testService = Provider.of<TestService>(context, listen: false);
    if (index >= 0 && index < testService.questions.length) {
      setState(() {
        _currentIndex = index;
        _selectedOption = -1;
        _selectedAnswer = null;
      });
      Navigator.pop(context);
    }
  }

  void _toggleMark() {
    setState(() {
      if (_markedQuestions.contains(_currentIndex)) {
        _markedQuestions.remove(_currentIndex);
      } else {
        _markedQuestions.add(_currentIndex);
      }
    });
  }

  void _finishTest() {
    final testService = Provider.of<TestService>(context, listen: false);
    testService.completeTest();
    unawaited(SubscriptionService().markFreeTestUsed());
    unawaited(SharedPreferences.getInstance()
        .then((prefs) => prefs.remove(_partialKey)));
    final questions = testService.questions;
    int correct = 0, incorrect = 0, skipped = 0;
    for (int i = 0; i < questions.length; i++) {
      final answer = i < _answers.length ? _answers[i] : null;
      if (answer == null) {
        skipped++;
      } else if (answer == questions[i].reponse) {
        correct++;
      } else {
        incorrect++;
      }
    }
    final percentage =
        questions.isNotEmpty ? correct / questions.length * 100 : 0.0;
    // Historique réel pour l'accueil filières (remplace la simulation).
    unawaited(testService.recordCompletedTest(
      testId: _testId,
      category: widget.testData?['category']?.toString() ??
          widget.testData?['name']?.toString() ??
          'entrainement',
      correctAnswers: correct,
      totalQuestions: questions.length,
      durationSeconds: DateTime.now().difference(_startTime).inSeconds,
    ));
    context.pushReplacement(
      AppRoutes.testResults,
      extra: TestResultRouteExtra(testResults: {
        'percentage': percentage,
        'correct': correct,
        'incorrect': incorrect,
        'skipped': skipped,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TestService>(
        builder: (context, testService, child) {
          if (testService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (testService.questions.isEmpty) {
            return Center(
              child: Text('Aucune question disponible',
                  style: AppTextStyles.bodyLarge),
            );
          }
          final question = testService.questions[_currentIndex];
          final total = testService.questions.length;

          return Column(
            children: [
              _buildProgressBar(total),
              _buildQuestionHeader(total, question),
              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      _buildQuestionText(question),
                      if (question.hasImage) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildQuestionImage(question),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _buildOptions(question),
                    ],
                  ),
                ),
              ),
              _buildNavigation(total),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildProgressBar(int total) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ).copyWith(top: MediaQuery.of(context).padding.top + AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (_currentIndex + 1) / total,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(int total, Question question) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardSm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  'Question ${_currentIndex + 1} sur $total',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: _timerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: _timerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: _timerColor, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _formattedTime,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _timerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _toggleMark,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _markedQuestions.contains(_currentIndex)
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: _markedQuestions.contains(_currentIndex)
                      ? AppColors.accent
                      : AppColors.border,
                ),
              ),
              child: Icon(
                _markedQuestions.contains(_currentIndex)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: _markedQuestions.contains(_currentIndex)
                    ? AppColors.accent
                    : AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: _showQuestionGrid,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.grid_view,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText(Question question) {
    return Text(
      question.question,
      style: AppTextStyles.quizQuestion.copyWith(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildQuestionImage(Question question) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Image.asset(
        question.imagePath!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(Question question) {
    final colors = [
      AppColors.quizA,
      AppColors.quizB,
      AppColors.quizC,
      AppColors.quizD,
    ];
    final labels = ['A', 'B', 'C', 'D'];

    return Column(
      children: List.generate(question.options.length, (index) {
        final isSelected = _selectedOption == index;
        final color = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Semantics(
            button: true,
            selected: isSelected,
            label:
                'Option ${labels[index]} : ${question.options[index]}',
            child: GestureDetector(
              onTap: () => _selectOption(index, question.options[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppShadows.cardSm : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : color.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppRadii.iconContainer),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: AppTextStyles.titleMedium.copyWith(
                          color:
                              isSelected ? AppColors.textOnPrimary : color,
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
                        color: AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: color, size: 22),
                ],
              ),
            ),
          ),
        ),
        );
      }),
    );
  }

  Widget _buildNavigation(int total) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.md,
        AppSpacing.pageHorizontal,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _currentIndex > 0 ? _previousQuestion : null,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _currentIndex > 0
                      ? AppColors.surface
                      : AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(AppRadii.button),
                  border: Border.all(
                    color: _currentIndex > 0
                        ? AppColors.border
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Précédent',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: _currentIndex > 0
                          ? AppColors.textPrimary
                          : AppColors.disabledText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: _currentIndex < total - 1
                  ? _nextQuestion
                  : _finishTest,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.button),
                  boxShadow: AppShadows.button,
                ),
                child: Center(
                  child: Text(
                    _currentIndex < total - 1 ? 'Suivant' : 'Terminer',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuestionGrid() {
    final testService = Provider.of<TestService>(context, listen: false);
    final total = testService.questions.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QuestionGridSheet(
        totalQuestions: total,
        currentQuestion: _currentIndex + 1,
        answeredQuestions: List.generate(
          _answers.where((a) => a != null).length,
          (i) => i + 1,
        ),
        markedQuestions: _markedQuestions.map((i) => i + 1).toList(),
        onQuestionTap: _jumpToQuestion,
      ),
    );
  }
}

class _QuestionGridSheet extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestion;
  final List<int> answeredQuestions;
  final List<int> markedQuestions;
  final Function(int) onQuestionTap;

  const _QuestionGridSheet({
    required this.totalQuestions,
    required this.currentQuestion,
    required this.answeredQuestions,
    required this.markedQuestions,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.modalTop),
        ),
      ),
      child: Column(
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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text('Aperçu des Questions',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendItem(AppColors.primary, 'Actuelle'),
                    _legendItem(AppColors.success, 'Répondue'),
                    _legendItem(AppColors.accent, 'Marquée'),
                    _legendItem(AppColors.textMuted, 'Non vue'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: totalQuestions,
                itemBuilder: (context, index) {
                  final num = index + 1;
                  final isCurrent = num == currentQuestion;
                  final isAnswered = answeredQuestions.contains(num);
                  final isMarked = markedQuestions.contains(num);

                  Color bg;
                  Color border;
                  Color text;

                  if (isCurrent) {
                    bg = AppColors.primary;
                    border = AppColors.primary;
                    text = AppColors.textOnPrimary;
                  } else if (isAnswered) {
                    bg = AppColors.success.withValues(alpha: 0.1);
                    border = AppColors.success;
                    text = AppColors.success;
                  } else if (isMarked) {
                    bg = AppColors.accent.withValues(alpha: 0.1);
                    border = AppColors.accent;
                    text = AppColors.accent;
                  } else {
                    bg = AppColors.surface;
                    border = AppColors.border;
                    text = AppColors.textSecondary;
                  }

                  return GestureDetector(
                    onTap: () => onQuestionTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius:
                            BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          num.toString(),
                          style: AppTextStyles.titleSmall.copyWith(
                            color: text,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  'Répondues',
                  answeredQuestions.length.toString(),
                  AppColors.success,
                ),
                _statItem(
                  'Marquées',
                  markedQuestions.length.toString(),
                  AppColors.accent,
                ),
                _statItem(
                  'Restantes',
                  (totalQuestions - answeredQuestions.length).toString(),
                  AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
