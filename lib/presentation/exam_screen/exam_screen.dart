import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../services/user_state_service.dart';
import '../../models/question.dart';
import './widgets/exam_question_widget.dart';
import './widgets/exam_header_widget.dart';
import './widgets/exam_navigation_widget.dart';

class ExamScreen extends StatefulWidget {
  final Map<String, dynamic>? examConfig;

  const ExamScreen({super.key, this.examConfig});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
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
  int remainingTimeInSeconds = 5400; // 90 minutes for exam
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
    timeLimit = widget.examConfig?['timeLimit'] ?? 3600; // 60 minutes pour 40 questions

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
      // Mix of different question types to simulate real exam
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
        final generalQuestions = await _databaseService.getRandomQuestions(limit: remaining);
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

  Color _getTimerColor() {
    if (remainingTimeInSeconds > 1800) {
      // > 30 minutes
      return AppTheme.lightTheme.colorScheme.secondary;
    } else if (remainingTimeInSeconds > 600) {
      // > 10 minutes
      return const Color(0xFFE67E22); // Warning orange
    } else {
      return AppTheme.lightTheme.colorScheme.error;
    }
  }

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
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Questions de l\'examen',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(4.w),
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

                  return GestureDetector(
                    onTap: () => _goToQuestion(questionNumber),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.lightTheme.colorScheme.primary
                            : isAnswered
                                ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2)
                                : AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(
                          color: isCurrent
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                          width: isCurrent ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          questionNumber.toString(),
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: isCurrent
                                ? Colors.white
                                : isAnswered
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
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

  void _showSubmitConfirmation() {
    HapticFeedback.mediumImpact();
    final answeredCount = selectedAnswers.length;
    final totalCount = examQuestions.length;
    final unansweredCount = totalCount - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Terminer l\'examen',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir terminer l\'examen ? Cette action est irréversible.',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Questions répondues:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium),
                      Text('$answeredCount/$totalCount',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (unansweredCount > 0) ...[
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Questions non répondues:',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error,
                            )),
                        Text('$unansweredCount',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.lightTheme.colorScheme.error,
                            )),
                      ],
                    ),
                  ],
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Temps restant:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium),
                      Text(_formatTime(remainingTimeInSeconds),
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTimerColor(),
                          )),
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
            child: const Text('Continuer l\'examen'),
          ),
          ElevatedButton(
            onPressed: _submitExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            child: const Text('Terminer l\'examen'),
          ),
        ],
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
      final isCorrect = selectedAnswer != null && question.options[selectedAnswer] == question.reponse;

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
    await userStateService.setDemoScore(correctAnswers);
    await userStateService.markDemoCompleted();

    // Navigate to results screen with progress system
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.progressExamResults,
      arguments: {
        'results': results,
        'totalQuestions': examQuestions.length,
        'correctAnswers': correctAnswers,
        'timeSpent': timeLimit - remainingTimeInSeconds,
        'examType': examType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gestion des états de chargement et d'erreur
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Préparation de l\'examen...',
                style: AppTheme.lightTheme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 15.w,
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Erreur de chargement',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  _error!,
                  style: AppTheme.lightTheme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                ElevatedButton(
                  onPressed: _loadExamQuestions,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (examQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Aucune question disponible pour l\'examen',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Exam Header with timer and progress
          ExamHeaderWidget(
            currentQuestion: currentQuestionIndex + 1,
            totalQuestions: examQuestions.length,
            timeRemaining: _formatTime(remainingTimeInSeconds),
            timerColor: _getTimerColor(),
            examType: examType,
            onShowQuestionGrid: _showQuestionGrid,
          ),

          // Question Content
          Expanded(
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
                return ExamQuestionWidget(
                  questionText: question.question,
                  options: question.options,
                  selectedOption: selectedAnswers[index],
                  onOptionSelected: (optionIndex) {
                    setState(() {
                      selectedAnswers[index] = optionIndex;
                    });
                    HapticFeedback.lightImpact();
                  },
                  questionImage: question.imagePath,
                  questionNumber: index + 1,
                  category: question.categorie,
                );
              },
            ),
          ),

          // Navigation Controls
          ExamNavigationWidget(
            currentQuestion: currentQuestionIndex + 1,
            totalQuestions: examQuestions.length,
            onPrevious: _goToPreviousQuestion,
            onNext: _goToNextQuestion,
            canGoNext: true,
            canGoPrevious: currentQuestionIndex > 0,
          ),
        ],
      ),
    );
  }
}
