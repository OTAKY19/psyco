import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ExamStatsWidget extends StatelessWidget {
  final int totalExams;
  final int completedExams;
  final double averageScore;

  const ExamStatsWidget({
    super.key,
    required this.totalExams,
    required this.completedExams,
    required this.averageScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos Statistiques',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Examens',
                  '$completedExams/$totalExams',
                  Icons.quiz,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Moyenne',
                  '${averageScore.toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          if (completedExams > 0) ...[
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: completedExams / totalExams,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Progression: ${((completedExams / totalExams) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
