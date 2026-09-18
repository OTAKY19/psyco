import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_export.dart';
import 'unified_activation_widget.dart';

class UnifiedResultsWidget extends StatelessWidget {
  final Map<String, dynamic> testResults;
  final List<Map<String, dynamic>> questions;
  final bool isDemoMode;
  final VoidCallback? onBackToMenu;
  final VoidCallback? onRetakeTest;

  const UnifiedResultsWidget({
    super.key,
    required this.testResults,
    required this.questions,
    this.isDemoMode = false,
    this.onBackToMenu,
    this.onRetakeTest,
  });

  @override
  Widget build(BuildContext context) {
    final score = testResults["scorePercentage"] as double? ?? 0;
    final correctAnswers = testResults["correctAnswers"] as int? ?? 0;
    final totalQuestions = testResults["totalQuestions"] as int? ?? questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Card
            _buildScoreCard(context, score, correctAnswers, totalQuestions),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Questions Review
            Text(
              'Révision des Questions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Questions List
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              
              // En mode démo, flouter après 15 questions
              final shouldBlur = isDemoMode && index >= 15;
              
              return _buildQuestionReviewItem(
                context, 
                question, 
                index + 1, 
                shouldBlur,
              );
            }),
            
            const SizedBox(height: AppSpacing.massive),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, double score, int correct, int total) {
    Color scoreColor;
    String scoreText;
    IconData scoreIcon;
    List<Color> gradientColors;
    
    if (score >= 90) {
      scoreColor = Colors.green.shade600;
      scoreText = 'Exceptionnel ! 🏆';
      scoreIcon = Icons.emoji_events;
      gradientColors = [Colors.green.shade400, Colors.green.shade600];
    } else if (score >= 80) {
      scoreColor = Colors.green.shade500;
      scoreText = 'Excellent ! ⭐';
      scoreIcon = Icons.star;
      gradientColors = [Colors.green.shade300, Colors.green.shade500];
    } else if (score >= 70) {
      scoreColor = Colors.blue.shade500;
      scoreText = 'Très bien ! 👍';
      scoreIcon = Icons.thumb_up;
      gradientColors = [Colors.blue.shade300, Colors.blue.shade500];
    } else if (score >= 60) {
      scoreColor = Colors.orange.shade500;
      scoreText = 'Bien ! 📈';
      scoreIcon = Icons.trending_up;
      gradientColors = [Colors.orange.shade300, Colors.orange.shade500];
    } else if (score >= 50) {
      scoreColor = Colors.amber.shade600;
      scoreText = 'Passable 📊';
      scoreIcon = Icons.bar_chart;
      gradientColors = [Colors.amber.shade400, Colors.amber.shade600];
    } else {
      scoreColor = Colors.red.shade500;
      scoreText = 'À améliorer 💪';
      scoreIcon = Icons.fitness_center;
      gradientColors = [Colors.red.shade300, Colors.red.shade500];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withValues(alpha: 0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            scoreIcon,
            size: AppSpacing.massive,
            color: scoreColor,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Text(
            '${score.toStringAsFixed(1)}%',
            style: AppTheme.lightTheme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),
          
          Text(
            scoreText,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scoreColor,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildScoreStat(context, 'Correctes', '$correct', Colors.green),
              _buildScoreStat(context, 'Incorrectes', '${total - correct}', Colors.red),
              _buildScoreStat(context, 'Total', '$total', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreStat(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionReviewItem(
    BuildContext context, 
    Map<String, dynamic> question, 
    int questionNumber, 
    bool shouldBlur,
  ) {
    final userAnswer = question['userAnswer'] as int?;
    final correctAnswer = question['correctAnswer'] as int?;
    final isCorrect = userAnswer == correctAnswer;
    final explanation = question['explanation'] as String? ?? 'Pas d\'explication disponible';
    
    Widget content = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: AppSpacing.lg,
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              Expanded(
                child: Text(
                  'Question $questionNumber',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Question Text
          Text(
            question['questionText'] ?? 'Question non disponible',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Answers
          if (question['options'] != null) ...[
            ...((question['options'] as List).asMap().entries.map((entry) {
              final optionIndex = entry.key;
              final option = entry.value as String;
              final isUserAnswer = userAnswer == optionIndex;
              final isCorrectOption = correctAnswer == optionIndex;
              
              Color backgroundColor = Colors.transparent;
              Color borderColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
              
              if (isCorrectOption) {
                backgroundColor = Colors.green.withValues(alpha: 0.1);
                borderColor = Colors.green;
              } else if (isUserAnswer && !isCorrect) {
                backgroundColor = Colors.red.withValues(alpha: 0.1);
                borderColor = Colors.red;
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    if (isCorrectOption)
                      const Icon(Icons.check_circle, color: Colors.green, size: AppSpacing.xl)
                    else if (isUserAnswer && !isCorrect)
                      const Icon(Icons.cancel, color: Colors.red, size: AppSpacing.xl)
                    else
                      const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: AppSpacing.xl),
                    
                    const SizedBox(width: AppSpacing.md),
                    
                    Expanded(
                      child: Text(
                        option,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })),
          ],
          
          const SizedBox(height: AppSpacing.lg),
          
          // Explanation
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: AppSpacing.xl,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Explication',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  explanation,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Appliquer le flou si nécessaire
    if (shouldBlur) {
      return GestureDetector(
        onTap: () => _showActivationPopup(context),
        child: Stack(
          children: [
            // Contenu complètement masqué - invisible
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: content,
                ),
              ),
            ),
            // Icône de verrouillage centrée sans overlay noir
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        'Contenu Premium',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
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

    return content;
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Retake Test Button (if available)
        if (onRetakeTest != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetakeTest,
              icon: const Icon(Icons.refresh),
              label: const Text('Refaire le Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),
        
        if (onRetakeTest != null) const SizedBox(height: AppSpacing.lg),
        
        // Back to Menu Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBackToMenu ?? () => context.go(AppRoutes.home),
            icon: const Icon(Icons.home),
            label: const Text('Retour au Menu Principal'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _showActivationPopup(BuildContext context) {
    // Utiliser la popup UnifiedActivationWidget comme dans demo_exam_screen
    UnifiedActivationWidget.show(
      context,
      contextMessage: 'Débloquez l\'analyse complète',
      featureName: 'Résultats détaillés',
      description: 'Activez PsychoTest+ pour afficher toutes les bonnes réponses, les explications détaillées et vos statistiques complètes.',
      iconName: 'star',
    );
  }
}