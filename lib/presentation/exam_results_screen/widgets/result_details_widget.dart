import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/exam_blanc_service.dart';

class ResultDetailsWidget extends StatefulWidget {
  final ExamBlancResult result;
  final bool isAdminMode;

  const ResultDetailsWidget({
    super.key,
    required this.result,
    this.isAdminMode = false,
  });

  @override
  State<ResultDetailsWidget> createState() => _ResultDetailsWidgetState();
}

class _ResultDetailsWidgetState extends State<ResultDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Corrections détaillées',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Liste des questions avec corrections
          ..._buildQuestionDetails(),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionDetails() {
    final List<Widget> widgets = [];
    int questionCount = 0;
    const int maxQuestionsForFree = 20;
    
    for (String key in widget.result.detailedResults.keys) {
      if (key.startsWith('question_')) {
        questionCount++;
        
        // Limiter à 20 questions pour les utilisateurs non-premium (sauf en mode admin)
        if (questionCount > maxQuestionsForFree && !widget.isAdminMode) {
          widgets.add(_buildLimitedAccessCard());
          break;
        }
        
        final questionData = widget.result.detailedResults[key] as Map<String, dynamic>;
        widgets.add(_buildQuestionCard(questionData));
        widgets.add(SizedBox(height: 12));
      }
    }
    
    return widgets;
  }

  Widget _buildLimitedAccessCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lock,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Accès limité',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vous avez atteint la limite de 20 questions gratuites.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Activez l\'application pour voir toutes les corrections et explications détaillées.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> questionData) {
    final isCorrect = questionData['isCorrect'] as bool;
    final questionText = questionData['questionText'] as String;
    final userAnswer = questionData['userAnswer'] as String?;
    final correctAnswer = questionData['correctAnswer'] as String;
    final explanation = questionData['explanation'] as String;
    final category = questionData['category'] as String;
    final difficulty = questionData['difficulty'] as String;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la question
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCategoryColor(category).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getCategoryColor(category),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getDifficultyLabel(difficulty),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: _getDifficultyColor(difficulty),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Texte de la question
            Text(
              questionText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Réponse de l'utilisateur
            if (userAnswer != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Votre réponse: $userAnswer',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            
            // Réponse correcte
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bonne réponse: $correctAnswer',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Explication
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'culture_generale':
        return Colors.blue;
      case 'francais':
        return Colors.green;
      case 'droit_douane':
        return Colors.orange;
      case 'mathematiques':
        return Colors.purple;
      case 'logique':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'culture_generale':
        return 'Culture Générale';
      case 'francais':
        return 'Français';
      case 'droit_douane':
        return 'Droit Douane';
      case 'mathematiques':
        return 'Mathématiques';
      case 'logique':
        return 'Logique';
      default:
        return category;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'facile':
        return 'Facile';
      case 'moyen':
        return 'Moyen';
      case 'difficile':
        return 'Difficile';
      default:
        return difficulty;
    }
  }
}
