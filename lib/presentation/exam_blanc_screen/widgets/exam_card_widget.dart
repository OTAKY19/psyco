import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/exam_blanc_service.dart';

class ExamCardWidget extends StatelessWidget {
  final ExamBlanc exam;
  final ExamBlancResult? result;
  final VoidCallback onStart;

  const ExamCardWidget({
    super.key,
    required this.exam,
    this.result,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de l'examen
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          exam.description,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Informations de l'examen
              Row(
                children: [
                  _buildInfoChip(
                    Icons.quiz,
                    '${exam.totalQuestions} questions',
                    Colors.blue,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.timer,
                    '${exam.duration.inMinutes} min',
                    Colors.green,
                  ),
                  SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.schedule,
                    '${exam.questionDuration.inSeconds}s/question',
                    Colors.orange,
                  ),
                ],
              ),
              
              // Résultat si disponible
              if (result != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getResultColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getResultColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        color: _getResultColor(),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Résultat: ${result!.scorePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getResultColor(),
                              ),
                            ),
                            Text(
                              '${result!.correctAnswers}/${result!.totalQuestions} bonnes réponses',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        result!.performanceGrade,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _getResultColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: 16),
              
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: Icon(result != null ? Icons.refresh : Icons.play_arrow),
                  label: Text(
                    result != null ? 'Refaire l\'examen' : 'Commencer l\'examen',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (result != null) {
      return _getResultColor();
    }
    return Colors.blue;
  }

  Color _getResultColor() {
    if (result == null) return Colors.blue;
    
    if (result!.scorePercentage >= 80) return Colors.green;
    if (result!.scorePercentage >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (result != null) {
      if (result!.scorePercentage >= 80) return Icons.check_circle;
      if (result!.scorePercentage >= 60) return Icons.warning;
      return Icons.error;
    }
    return Icons.quiz;
  }
}
