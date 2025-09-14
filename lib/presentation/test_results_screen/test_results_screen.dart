import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/question.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/animated_progress_ring_widget.dart';
import './widgets/category_performance_chart_widget.dart';
import './widgets/performance_breakdown_widget.dart';
import './widgets/performance_comparison_widget.dart';
import './widgets/question_review_item_widget.dart';
import './widgets/score_header_widget.dart';

class TestResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? testResults;

  const TestResultsScreen({super.key, this.testResults});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  // Real test results data from arguments
  late final Map<String, dynamic> testResults;
  late final List<Map<String, dynamic>> categoryPerformance;
  late final List<Map<String, dynamic>> questionReview;
  late final List<Map<String, dynamic>> recentAttempts;

  @override
  void initState() {
    super.initState();

    // Initialize with real data from arguments or fallback to mock data
    if (widget.testResults != null) {
      final args = widget.testResults!;

      testResults = {
        "testName": args["testName"] ?? "Test Psychotechnique",
        "totalQuestions": args["totalQuestions"] ?? 0,
        "correctAnswers": args["correctAnswers"] ?? 0,
        "incorrectAnswers": args["incorrectAnswers"] ?? 0,
        "skippedAnswers": args["skippedQuestions"] ?? 0,
        "scorePercentage": args["scorePercentage"] ?? 0.0,
        "previousScore": args["previousScore"] ?? 0.0,
        "timeTaken": _formatTime(args["timeSpent"] ?? 0),
        "completedAt": DateTime.now().toString(),
      };

      // Generate question review from real data
      questionReview = _generateQuestionReview(args);

      // Generate category performance (simplified for now)
      categoryPerformance = _generateCategoryPerformance(args);

      // Mock recent attempts (would come from database in real app)
      recentAttempts = [
        {"score": testResults["scorePercentage"], "date": "Aujourd'hui"},
        {"score": 65.0, "date": "Hier"},
        {"score": 58.0, "date": "Il y a 3j"},
        {"score": 62.0, "date": "Il y a 1sem"},
        {"score": 55.0, "date": "Il y a 2sem"},
      ];
    } else {
      // Fallback to mock data if no arguments provided
      testResults = {
        "testName": "Test Psychotechnique - Logique Numérique",
        "totalQuestions": 25,
        "correctAnswers": 18,
        "incorrectAnswers": 5,
        "skippedAnswers": 2,
        "scorePercentage": 72.0,
        "previousScore": 65.0,
        "timeTaken": "23 minutes",
        "completedAt": "04/09/2025 14:45",
      };

      categoryPerformance = [
        {"name": "Logique", "score": 85.0, "total": 8, "correct": 7},
        {"name": "Calcul", "score": 75.0, "total": 6, "correct": 5},
        {"name": "Spatial", "score": 60.0, "total": 5, "correct": 3},
        {"name": "Verbal", "score": 66.7, "total": 6, "correct": 4},
      ];

      questionReview = [
        {
          "id": 1,
          "questionText": "Quelle est la suite logique: 2, 4, 8, 16, ?",
          "userAnswer": "32",
          "correctAnswer": "32",
          "isCorrect": true,
          "explanation":
              "Il s'agit d'une progression géométrique où chaque terme est multiplié par 2.",
          "isBookmarked": false,
        },
        {
          "id": 2,
          "questionText": "Si 3x + 5 = 14, quelle est la valeur de x?",
          "userAnswer": "4",
          "correctAnswer": "3",
          "isCorrect": false,
          "explanation":
              "3x + 5 = 14, donc 3x = 9, donc x = 3. Il faut soustraire 5 des deux côtés avant de diviser par 3.",
          "isBookmarked": true,
        },
        {
          "id": 3,
          "questionText": "Combien y a-t-il de triangles dans cette figure?",
          "userAnswer": null,
          "correctAnswer": "12",
          "isCorrect": false,
          "explanation":
              "Il faut compter tous les triangles, y compris ceux formés par la combinaison de plusieurs triangles plus petits.",
          "isBookmarked": false,
        },
      ];

      recentAttempts = [
        {"score": 72.0, "date": "04/09"},
        {"score": 65.0, "date": "28/08"},
        {"score": 58.0, "date": "21/08"},
        {"score": 62.0, "date": "14/08"},
        {"score": 55.0, "date": "07/08"},
      ];
    }

    _initializeCelebrationAnimation();
    _triggerCelebrationIfHighScore();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes min $remainingSeconds sec';
  }

  List<Map<String, dynamic>> _generateQuestionReview(Map<String, dynamic> args) {
    final questions = args["testQuestions"] as List<Question>? ?? [];
    final userAnswers = args["selectedAnswers"] as Map<int, int>? ?? {};
    final List<Map<String, dynamic>> review = [];

    for (int i = 0; i < questions.length && i < 10; i++) { // Show max 10 questions
      final question = questions[i];
      final userAnswerIndex = userAnswers[i];
      final userAnswer = userAnswerIndex != null ? question.options[userAnswerIndex] : null;
      final isCorrect = userAnswer == question.reponse;

      review.add({
        "id": question.id,
        "questionText": question.question,
        "userAnswer": userAnswer,
        "correctAnswer": question.reponse,
        "isCorrect": isCorrect,
        "explanation": question.explication,
        "isBookmarked": false,
      });
    }

    return review;
  }

  List<Map<String, dynamic>> _generateCategoryPerformance(Map<String, dynamic> args) {
    // Simplified category performance - in a real app this would be calculated
    // based on the actual questions and answers
    return [
      {"name": "Questions répondues", "score": 85.0, "total": args["totalQuestions"] ?? 0, "correct": args["correctAnswers"] ?? 0},
    ];
  }



  void _initializeCelebrationAnimation() {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
  }

  void _triggerCelebrationIfHighScore() {
    final score = testResults["scorePercentage"] as double;
    if (score >= 80) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _celebrationController.forward();
        HapticFeedback.lightImpact();
      });
    }
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return "Excellent";
    if (percentage >= 80) return "Très Bien";
    if (percentage >= 70) return "Bien";
    if (percentage >= 60) return "Assez Bien";
    if (percentage >= 50) return "Passable";
    return "Insuffisant";
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return AppTheme.successLight;
    if (percentage >= 60) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }

  void _toggleBookmark(int questionId) {
    setState(() {
      final questionIndex =
          questionReview.indexWhere((q) => q["id"] == questionId);
      if (questionIndex != -1) {
        questionReview[questionIndex]["isBookmarked"] =
            !(questionReview[questionIndex]["isBookmarked"] as bool);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _retakeTest() {
    Navigator.pushReplacementNamed(context, '/test-taking-screen');
  }

  void _trySimilarTests() {
    Navigator.pushNamed(context, '/test-category-screen');
  }

  void _generateCertificate() {
    // Certificate generation logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Certificat généré avec succès!'),
        backgroundColor: AppTheme.successLight,
      ),
    );
  }

  void _navigateToProgressTracking() {
    Navigator.pushNamed(context, '/progress-tracking-screen');
  }

  @override
  Widget build(BuildContext context) {
    final scorePercentage = testResults["scorePercentage"] as double;
    final grade = _getGrade(scorePercentage);
    final gradeColor = _getGradeColor(scorePercentage);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Résultats du Test'),
        leading: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(
              context, '/test-library-dashboard'),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _navigateToProgressTracking,
            icon: CustomIconWidget(
              iconName: 'analytics',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Header
            ScoreHeaderWidget(
              scorePercentage: scorePercentage,
              grade: grade,
              gradeColor: gradeColor,
            ),

            SizedBox(height: 3.h),

            // Animated Progress Ring
            Center(
              child: AnimatedBuilder(
                animation: _celebrationAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_celebrationAnimation.value * 0.1),
                    child: AnimatedProgressRingWidget(
                      percentage: scorePercentage,
                      color: gradeColor,
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 4.h),

            // Performance Breakdown
            PerformanceBreakdownWidget(
              correctAnswers: testResults["correctAnswers"] as int,
              incorrectAnswers: testResults["incorrectAnswers"] as int,
              skippedAnswers: testResults["skippedAnswers"] as int,
              totalQuestions: testResults["totalQuestions"] as int,
            ),

            SizedBox(height: 3.h),

            // Category Performance Chart
            CategoryPerformanceChartWidget(
              categoryData: categoryPerformance,
            ),

            SizedBox(height: 3.h),

            // Performance Comparison
            PerformanceComparisonWidget(
              currentScore: scorePercentage,
              previousScore: testResults["previousScore"] as double,
              recentAttempts: recentAttempts,
            ),

            SizedBox(height: 4.h),

            // Question Review Section
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'quiz',
                        color: AppTheme.primaryLight,
                        size: 24,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Révision des Questions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questionReview.length,
                    itemBuilder: (context, index) {
                      final question = questionReview[index];
                      return QuestionReviewItemWidget(
                        question: question,
                        questionNumber: index + 1,
                        onBookmarkToggle: () =>
                            _toggleBookmark(question["id"] as int),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            // Action Buttons
            ActionButtonsWidget(
              scorePercentage: scorePercentage,
              testName: testResults["testName"] as String,
              onRetakeTest: _retakeTest,
              onTrySimilarTests: _trySimilarTests,
              onGenerateCertificate:
                  scorePercentage >= 70 ? _generateCertificate : null,
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
