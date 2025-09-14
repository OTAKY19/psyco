import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ExamHeaderWidget extends StatelessWidget {
  final int currentQuestion;
  final int totalQuestions;
  final String examTimeRemaining;
  final String questionTimeRemaining;
  final Color examTimerColor;
  final Color questionTimerColor;
  final bool isPaused;
  final VoidCallback onPause;

  const ExamHeaderWidget({
    super.key,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.examTimeRemaining,
    required this.questionTimeRemaining,
    required this.examTimerColor,
    required this.questionTimerColor,
    required this.isPaused,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barre de progression
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: currentQuestion / totalQuestions,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              SizedBox(width: 16),
              Text(
                '$currentQuestion/$totalQuestions',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Timers et contrôles
          Row(
            children: [
              // Timer de l'examen
              Expanded(
                child: _buildTimerCard(
                  'Temps total',
                  examTimeRemaining,
                  examTimerColor,
                  Icons.timer,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Timer de la question
              Expanded(
                child: _buildTimerCard(
                  'Question',
                  questionTimeRemaining,
                  questionTimerColor,
                  Icons.schedule,
                ),
              ),
              
              SizedBox(width: 12),
              
              // Bouton pause
              Container(
                decoration: BoxDecoration(
                  color: isPaused ? Colors.orange : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: onPause,
                  icon: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(String label, String time, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
