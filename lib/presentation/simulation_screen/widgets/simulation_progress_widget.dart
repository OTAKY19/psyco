import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/simulation_model.dart';
import '../../../services/simulation_service.dart';

class SimulationProgressWidget extends StatelessWidget {
  final SimulationSession session;

  const SimulationProgressWidget({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final simulationService = SimulationService();
    final stats = simulationService.getSimulationStats(session);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Progression des questions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progression',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${stats['currentQuestion']}/${stats['totalQuestions']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: stats['progress'] as double,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16),
          
          // Statistiques
          Column(
            children: [
              _buildStatItem(
                context,
                'Correctes',
                stats['correctAnswers'].toString(),
                Colors.green,
              ),
              SizedBox(height: 4),
              _buildStatItem(
                context,
                'Répondues',
                stats['totalAnswered'].toString(),
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
