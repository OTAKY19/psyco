import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/simulation_model.dart';
import '../../../services/simulation_service.dart';

class SimulationTimerWidget extends StatelessWidget {
  final SimulationSession session;
  final VoidCallback? onTimeUp;

  const SimulationTimerWidget({
    Key? key,
    required this.session,
    this.onTimeUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final simulationService = SimulationService();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Timer principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temps restant',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  simulationService.formatTime(session.remainingTime),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _getTimeColor(session.remainingTime),
                  ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: simulationService.getTimeProgress(session),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTimeColor(session.remainingTime),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 16),
          
          // Timer de la question actuelle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Question actuelle',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  simulationService.formatTime(session.currentQuestionRemainingTime),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _getQuestionTimeColor(session.currentQuestionRemainingTime),
                  ),
                ),
                SizedBox(height: 4),
                LinearProgressIndicator(
                  value: simulationService.getQuestionTimeProgress(session),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getQuestionTimeColor(session.currentQuestionRemainingTime),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeColor(Duration remainingTime) {
    final minutes = remainingTime.inMinutes;
    if (minutes <= 5) {
      return Colors.red;
    } else if (minutes <= 10) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color _getQuestionTimeColor(Duration remainingTime) {
    final seconds = remainingTime.inSeconds;
    if (seconds <= 10) {
      return Colors.red;
    } else if (seconds <= 30) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}
