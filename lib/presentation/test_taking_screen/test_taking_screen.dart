import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/question_content_widget.dart';
import './widgets/question_grid_bottom_sheet.dart';
import './widgets/question_header_widget.dart';
import './widgets/question_navigation_widget.dart';

class TestTakingScreen extends StatefulWidget {
  const TestTakingScreen({super.key});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen>
    with TickerProviderStateMixin {
  // Test Data
  final List<Map<String, dynamic>> testQuestions = [
    {
      "id": 1,
      "question": "Quelle est la capitale du Bénin ?",
      "options": ["Cotonou", "Porto-Novo", "Parakou", "Abomey"],
      "correctAnswer": 1,
      "category": "Géographie",
      "difficulty": "Facile",
      "image": null,
    },
    {
      "id": 2,
      "question":
          "Si un train parcourt 120 km en 2 heures, quelle est sa vitesse moyenne ?",
      "options": ["50 km/h", "60 km/h", "70 km/h", "80 km/h"],
      "correctAnswer": 1,
      "category": "Mathématiques",
      "difficulty": "Moyen",
      "image": null,
    },
    {
      "id": 3,
      "question": "Quel est le synonyme du mot 'perspicace' ?",
      "options": ["Confus", "Clairvoyant", "Négligent", "Indifférent"],
      "correctAnswer": 1,
      "category": "Français",
      "difficulty": "Moyen",
      "image": null,
    },
    {
      "id": 4,
      "question":
          "Dans une série logique : 2, 4, 8, 16, ?, quel est le nombre suivant ?",
      "options": ["24", "32", "28", "20"],
      "correctAnswer": 1,
      "category": "Logique",
      "difficulty": "Facile",
      "image": null,
    },
    {
      "id": 5,
      "question": "Quelle est la fonction principale des douanes ?",
      "options": [
        "Contrôler la circulation routière",
        "Percevoir les droits et taxes sur les marchandises",
        "Gérer les hôpitaux publics",
        "Organiser les élections"
      ],
      "correctAnswer": 1,
      "category": "Douanes",
      "difficulty": "Facile",
      "image": null,
    },
    {
      "id": 6,
      "question": "Si A = 1, B = 2, C = 3, quelle est la valeur de 'DOUANE' ?",
      "options": ["54", "58", "62", "66"],
      "correctAnswer": 0,
      "category": "Logique",
      "difficulty": "Difficile",
      "image": null,
    },
    {
      "id": 7,
      "question": "Quel pourcentage représente 15 sur 60 ?",
      "options": ["20%", "25%", "30%", "35%"],
      "correctAnswer": 1,
      "category": "Mathématiques",
      "difficulty": "Moyen",
      "image": null,
    },
    {
      "id": 8,
      "question":
          "Complétez la phrase : 'Il faut battre le fer pendant qu'il est...'",
      "options": ["froid", "chaud", "rouge", "dur"],
      "correctAnswer": 1,
      "category": "Français",
      "difficulty": "Facile",
      "image": null,
    },
    {
      "id": 9,
      "question": "Quelle est la monnaie officielle du Bénin ?",
      "options": ["Euro", "Dollar", "Franc CFA", "Naira"],
      "correctAnswer": 2,
      "category": "Géographie",
      "difficulty": "Facile",
      "image": null,
    },
    {
      "id": 10,
      "question":
          "Dans une progression arithmétique : 5, 8, 11, 14, ?, quel est le terme suivant ?",
      "options": ["16", "17", "18", "19"],
      "correctAnswer": 1,
      "category": "Mathématiques",
      "difficulty": "Moyen",
      "image": null,
    },
  ];

  // Test State
  int currentQuestionIndex = 0;
  Map<int, int> selectedAnswers = {};
  Set<int> markedQuestions = {};
  Timer? testTimer;
  Timer? autoSaveTimer;
  int remainingTimeInSeconds = 3600; // 60 minutes
  bool isPaused = false;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  @override
  void dispose() {
    testTimer?.cancel();
    autoSaveTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  void _initializeTest() {
    // Start test timer
    testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused && remainingTimeInSeconds > 0) {
        setState(() {
          remainingTimeInSeconds--;
        });

        // Auto-submit when time is up
        if (remainingTimeInSeconds == 0) {
          _submitTest();
        }
      }
    });

    // Start auto-save timer
    autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _autoSaveProgress();
    });

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Prevent screenshots (Android only)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _autoSaveProgress() {
    // Auto-save logic would go here
    // For now, just a debug print
    debugPrint('Auto-saving progress...');
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (remainingTimeInSeconds > 300) {
      // > 5 minutes
      return AppTheme.lightTheme.colorScheme.secondary;
    } else if (remainingTimeInSeconds > 60) {
      // > 1 minute
      return const Color(0xFFE67E22); // Warning orange
    } else {
      return AppTheme.lightTheme.colorScheme.error;
    }
  }

  void _selectAnswer(int optionIndex) {
    HapticFeedback.lightImpact();
    setState(() {
      selectedAnswers[currentQuestionIndex] = optionIndex;
    });
  }

  void _toggleMarkForReview() {
    HapticFeedback.lightImpact();
    setState(() {
      if (markedQuestions.contains(currentQuestionIndex)) {
        markedQuestions.remove(currentQuestionIndex);
      } else {
        markedQuestions.add(currentQuestionIndex);
      }
    });
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
    if (currentQuestionIndex < testQuestions.length - 1) {
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
    if (index >= 0 && index < testQuestions.length) {
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
      builder: (context) => QuestionGridBottomSheet(
        totalQuestions: testQuestions.length,
        currentQuestion: currentQuestionIndex + 1,
        answeredQuestions:
            selectedAnswers.keys.map((index) => index + 1).toList(),
        markedQuestions: markedQuestions.map((index) => index + 1).toList(),
        onQuestionTap: _goToQuestion,
      ),
    );
  }

  void _pauseTest() {
    HapticFeedback.mediumImpact();
    setState(() {
      isPaused = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Test en Pause',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Le test est actuellement en pause. Votre progression a été sauvegardée.',
          style: AppTheme.lightTheme.textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(
                  context, '/test-library-dashboard');
            },
            child: const Text('Quitter le Test'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isPaused = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation() {
    HapticFeedback.mediumImpact();
    final answeredCount = selectedAnswers.length;
    final totalCount = testQuestions.length;
    final unansweredCount = totalCount - answeredCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Terminer le Test',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir terminer le test ?',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
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
            child: const Text('Continuer le Test'),
          ),
          ElevatedButton(
            onPressed: _submitTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            child: const Text('Terminer le Test'),
          ),
        ],
      ),
    );
  }

  void _submitTest() {
    testTimer?.cancel();
    autoSaveTimer?.cancel();

    // Calculate results
    int correctAnswers = 0;
    for (int i = 0; i < testQuestions.length; i++) {
      final selectedAnswer = selectedAnswers[i];
      final correctAnswer = testQuestions[i]['correctAnswer'] as int;
      if (selectedAnswer == correctAnswer) {
        correctAnswers++;
      }
    }

    // Navigate to results screen
    Navigator.pushReplacementNamed(
      context,
      '/test-results-screen',
      arguments: {
        'correctAnswers': correctAnswers,
        'totalQuestions': testQuestions.length,
        'timeSpent': 3600 - remainingTimeInSeconds,
        'selectedAnswers': selectedAnswers,
        'testQuestions': testQuestions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = testQuestions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header with timer and question counter
          QuestionHeaderWidget(
            currentQuestion: currentQuestionIndex + 1,
            totalQuestions: testQuestions.length,
            timeRemaining: _formatTime(remainingTimeInSeconds),
            timerColor: _getTimerColor(),
            onPause: _pauseTest,
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
              itemCount: testQuestions.length,
              itemBuilder: (context, index) {
                final question = testQuestions[index];
                return QuestionContentWidget(
                  questionText: question['question'] as String,
                  options: (question['options'] as List).cast<String>(),
                  selectedOption: selectedAnswers[index],
                  onOptionSelected: (optionIndex) {
                    setState(() {
                      selectedAnswers[index] = optionIndex;
                    });
                    HapticFeedback.lightImpact();
                  },
                  questionImage: question['image'] as String?,
                );
              },
            ),
          ),

          // Navigation Controls
          QuestionNavigationWidget(
            currentQuestion: currentQuestionIndex + 1,
            totalQuestions: testQuestions.length,
            onPrevious: _goToPreviousQuestion,
            onNext: _goToNextQuestion,
            isMarkedForReview: markedQuestions.contains(currentQuestionIndex),
            onToggleReview: _toggleMarkForReview,
            canGoNext: true,
            canGoPrevious: currentQuestionIndex > 0,
          ),
        ],
      ),
    );
  }
}
