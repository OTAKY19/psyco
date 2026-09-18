import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design/app_colors.dart';
import '../../services/exam_blanc_service.dart';
import '../../widgets/unified_results_widget.dart';
import '../../router/app_routes.dart';

class ExamResultsScreen extends StatelessWidget {
  final ExamBlancResult result;

  const ExamResultsScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildDetailsTab(context),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final questionsData = result.detailedResults.entries.map((entry) {
      final questionData = entry.value as Map<String, dynamic>;
      final questionText = questionData['questionText'] as String;
      final options = questionData['options'] as List<String>;
      final userAnswerIndex = questionData['userAnswerIndex'] as int?;
      final correctAnswerIndex = questionData['correctAnswerIndex'] as int;
      final explanation = questionData['explanation'] as String? ??
          'Pas d\'explication disponible';

      return {
        'questionText': questionText,
        'options': options,
        'userAnswer': userAnswerIndex,
        'correctAnswer': correctAnswerIndex,
        'explanation': explanation,
      };
    }).toList();

    final testResults = {
      'scorePercentage': result.scorePercentage,
      'correctAnswers': result.correctAnswers,
      'totalQuestions': result.totalQuestions,
    };

    return UnifiedResultsWidget(
      testResults: testResults,
      questions: questionsData,
      isDemoMode: false,
      onBackToMenu: () => context.go(AppRoutes.examBlanc),
      onRetakeTest: () => context.go(AppRoutes.examBlanc),
    );
  }
}