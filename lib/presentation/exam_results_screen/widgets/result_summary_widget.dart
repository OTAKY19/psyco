import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/exam_blanc_service.dart';

class ResultSummaryWidget extends StatelessWidget {
  final ExamBlancResult result;

  const ResultSummaryWidget({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getResultColor(),
            _getResultColor().withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Note principale
          Text(
            '${result.scorePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          // Grade de performance
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              result.performanceGrade,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Description de la performance
            Text(
              _getPerformanceDescription(),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          
          SizedBox(height: 20),
          
          // Statistiques rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat(
                'Correctes',
                '${result.correctAnswers}',
                Icons.check_circle,
              ),
              _buildQuickStat(
                'Incorrectes',
                '${result.incorrectAnswers}',
                Icons.cancel,
              ),
              _buildQuickStat(
                'Sautées',
                '${result.skippedQuestions}',
                Icons.skip_next,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Color _getResultColor() {
    if (result.scorePercentage >= 80) return Colors.green;
    if (result.scorePercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceDescription() {
    if (result.scorePercentage >= 90) {
      return 'Performance exceptionnelle ! Vous maîtrisez parfaitement le sujet.';
    } else if (result.scorePercentage >= 80) {
      return 'Très bon résultat ! Vous êtes bien préparé.';
    } else if (result.scorePercentage >= 70) {
      return 'Bon résultat ! Quelques révisions vous aideront.';
    } else if (result.scorePercentage >= 60) {
      return 'Résultat correct. Continuez à vous entraîner.';
    } else if (result.scorePercentage >= 50) {
      return 'Résultat moyen. Des révisions approfondies sont nécessaires.';
    } else {
      return 'Résultat insuffisant. Revoyez les bases du sujet.';
    }
  }
}
