import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../models/question.dart';

class SimulationDemoWidget extends StatefulWidget {
  final VoidCallback onDemoCompleted;
  final VoidCallback onUpgradeNow;

  const SimulationDemoWidget({
    super.key,
    required this.onDemoCompleted,
    required this.onUpgradeNow,
  });

  @override
  State<SimulationDemoWidget> createState() => _SimulationDemoWidgetState();

  static Future<void> show(
    BuildContext context,
    VoidCallback onDemoCompleted,
    VoidCallback onUpgradeNow,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SimulationDemoWidget(
        onDemoCompleted: onDemoCompleted,
        onUpgradeNow: onUpgradeNow,
      ),
    );
  }
}

class _SimulationDemoWidgetState extends State<SimulationDemoWidget> {
  int _currentStep = 0;
  int _demoScore = 0;
  bool _isAnswering = false;

  final List<DemoQuestion> _demoQuestions = [
    DemoQuestion(
      question: 'Quelle est la suite logique : 2, 4, 8, 16, ?',
      options: ['24', '32', '28', '30'],
      correctAnswer: 1, // Index de la bonne réponse
      explanation: 'Suite géométrique : multiplication par 2',
      category: 'Logique',
    ),
    DemoQuestion(
      question: 'Un article coûte 5000 FCFA. Il est soldé à -20%. Quel est le prix final ?',
      options: ['4000', '4500', '3800', '4200'],
      correctAnswer: 0,
      explanation: '5000 × 0.8 = 4000 FCFA',
      category: 'Calcul',
    ),
    DemoQuestion(
      question: 'Quel mot est différent : Maison, Appartement, Immeuble, Voiture ?',
      options: ['Maison', 'Appartement', 'Immeuble', 'Voiture'],
      correctAnswer: 3,
      explanation: 'Voiture n\'est pas un type d\'habitation',
      category: 'Verbal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 90.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec style drawer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Icône avec style drawer
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock,
                      color: Colors.white,
                      size: 10.w,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Titre avec style drawer
                  Text(
                    'Limite Tests Gratuits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Sous-titre
                  Text(
                    'Simulation démo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Score actuel (style drawer)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.indigo.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Score: $_demoScore/${_demoQuestions.length}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.indigo.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Contenu selon l'étape
                      if (_currentStep < _demoQuestions.length) ...[
                        _buildQuestionStep(),
                      ] else ...[
                        _buildResultsStep(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStep() {
    final question = _demoQuestions[_currentStep];

    return Column(
      children: [
        // Catégorie
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            question.category,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Question
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            question.question,
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: 3.h),

        // Options
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: ElevatedButton(
              onPressed: _isAnswering ? null : () => _answerQuestion(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
                padding: EdgeInsets.all(4.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                elevation: 0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      option,
                      style: AppTheme.lightTheme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        SizedBox(height: 2.h),

        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _demoQuestions.length,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: 3.w,
              height: 3.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _currentStep
                    ? Colors.green
                    : index == _currentStep
                        ? Colors.indigo
                        : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsStep() {
    final percentage = (_demoScore / _demoQuestions.length * 100).round();

    return Column(
      children: [
        // Résultat
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: percentage >= 70 ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: percentage >= 70 ? Colors.green.shade200 : Colors.orange.shade200,
            ),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: percentage >= 70 ? 'celebration' : 'trending_up',
                color: percentage >= 70 ? Colors.green.shade600 : Colors.orange.shade600,
                size: 15.w,
              ),
              SizedBox(height: 2.h),
              Text(
                percentage >= 70 ? 'Excellent !' : 'Bon résultat !',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: percentage >= 70 ? Colors.green.shade600 : Colors.orange.shade600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Score: $percentage%',
                style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Vous avez répondu correctement à $_demoScore question(s) sur ${_demoQuestions.length}',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Statistiques détaillées
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Vos Statistiques :',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2.h),
              ..._demoQuestions.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                final isCorrect = index < _currentStep; // Pour cette démo simplifiée

                return Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: isCorrect ? 'check_circle' : 'cancel',
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          question.category,
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        isCorrect ? 'Correct' : 'À améliorer',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Message de motivation
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: Colors.blue.shade600,
                size: 8.w,
              ),
              SizedBox(height: 1.h),
              Text(
                '💡 Pour voir vos réponses détaillées et accéder à des milliers de questions supplémentaires...',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.blue.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 4.h),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDemoCompleted();
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Terminer la démo',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onUpgradeNow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Voir le Prix Complet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _answerQuestion(int selectedIndex) async {
    setState(() {
      _isAnswering = true;
    });

    final question = _demoQuestions[_currentStep];
    final isCorrect = selectedIndex == question.correctAnswer;

    if (isCorrect) {
      _demoScore++;
    }

    // Animation de feedback
    await Future.delayed(Duration(seconds: 1));

    // Passer à la question suivante ou aux résultats
    if (_currentStep < _demoQuestions.length - 1) {
      setState(() {
        _currentStep++;
        _isAnswering = false;
      });
    } else {
      setState(() {
        _currentStep = _demoQuestions.length;
        _isAnswering = false;
      });
    }
  }
}

class DemoQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String category;

  const DemoQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.category,
  });
}
