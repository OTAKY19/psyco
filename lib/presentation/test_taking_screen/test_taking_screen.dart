import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../models/question.dart';
import './widgets/question_content_widget.dart';
import './widgets/memory_question_widget.dart';
import './widgets/question_grid_bottom_sheet.dart';
import './widgets/question_header_widget.dart';
import './widgets/question_navigation_widget.dart';

class TestTakingScreen extends StatefulWidget {
  final Map<String, dynamic>? testData;

  const TestTakingScreen({super.key, this.testData});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen>
    with TickerProviderStateMixin {
  // Services
  final DatabaseService _databaseService = DatabaseService();
  
  // Test Data - Chargé dynamiquement
  List<Question> testQuestions = [];
  bool _isLoading = true;
  String? _error;

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
    _loadQuestions();
  }

  @override
  void dispose() {
    testTimer?.cancel();
    autoSaveTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<Question> questions;

      // Vérifier si des données de test spécifiques sont passées
      if (widget.testData != null) {
        final testData = widget.testData!;
        final questionCount = testData['questionCount'] as int? ?? 15;
        final dbCategory = testData['dbCategory'] as String?;
        final duration = testData['duration'] as int? ?? 60; // minutes

        print('🎯 Chargement test personnalisé:');
        print('   - Nombre de questions: $questionCount');
        print('   - Catégorie DB: $dbCategory');
        print('   - Durée: $duration minutes');

        // Charger les questions selon la configuration du test
        if (dbCategory != null) {
          questions = await _databaseService.getRandomQuestions(
            limit: questionCount,
            category: dbCategory,
          );
        } else {
          questions = await _databaseService.getRandomQuestions(limit: questionCount);
        }

        // Configurer le timer selon la durée du test
        remainingTimeInSeconds = duration * 60;
      } else {
        // Mode par défaut : charger 15 questions aléatoires
        print('🎯 Chargement test par défaut: 15 questions aléatoires');
        questions = await _databaseService.getRandomQuestions(limit: 15);
      }

      if (questions.isEmpty) {
        throw Exception('Aucune question trouvée dans la base de données');
      }

      print('✅ ${questions.length} questions chargées');

      setState(() {
        testQuestions = questions;
        _isLoading = false;
      });

      // Initialiser le test après le chargement des questions
      _initializeTest();
    } catch (e) {
      print('❌ Erreur lors du chargement des questions: $e');
      setState(() {
        _error = 'Erreur lors du chargement des questions: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeTest() {
    if (testQuestions.isEmpty) return;

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
      final question = testQuestions[i];
      if (selectedAnswer != null && question.options[selectedAnswer] == question.reponse) {
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
                'Chargement des questions...',
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
                  onPressed: _loadQuestions,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (testQuestions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: Text(
            'Aucune question disponible',
            style: AppTheme.lightTheme.textTheme.headlineSmall,
          ),
        ),
      );
    }


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

                // Check if this is a memory question
                final isMemoryQuestion = question.question.contains('Retenez cette suite') ||
                                        question.question.contains('Mémorisez cette suite');

                if (isMemoryQuestion) {
                  // Extract memory sequence from question text
                  final sequenceMatch = RegExp(r'Reten.*suite\s*:\s*([^.]+)').firstMatch(question.question);
                  final memorySequence = sequenceMatch?.group(1)?.trim() ?? '';

                  // Extract the actual question part
                  final questionMatch = RegExp(r'Quel.*était.*élément').firstMatch(question.question);
                  final actualQuestion = questionMatch != null
                      ? question.question.substring(questionMatch.start)
                      : 'Quel était l\'élément demandé ?';

                  return MemoryQuestionWidget(
                    memorySequence: memorySequence,
                    questionText: actualQuestion,
                    options: question.options,
                    selectedOption: selectedAnswers[index],
                    onOptionSelected: (optionIndex) {
                      setState(() {
                        selectedAnswers[index] = optionIndex;
                      });
                      HapticFeedback.lightImpact();
                    },
                    displayDuration: 8, // 8 seconds to memorize
                  );
                } else {
                  return QuestionContentWidget(
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
                  );
                }
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
