import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/simulation_model.dart';
import '../../../services/simulation_service.dart';

class SimulationNavigationWidget extends StatelessWidget {
  final SimulationSession session;
  final VoidCallback? onNext;

  const SimulationNavigationWidget({
    Key? key,
    required this.session,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final simulationService = SimulationService();
    final stats = simulationService.getSimulationStats(session);
    final isLastQuestion = session.currentQuestionIndex >= session.questions.length - 1;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Informations de navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${session.currentQuestionIndex + 1} sur ${session.questions.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${stats['remainingQuestions']} questions restantes',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Barre de progression visuelle
          Row(
            children: List.generate(session.questions.length, (index) {
              final isAnswered = index < session.currentQuestionIndex;
              final isCurrent = index == session.currentQuestionIndex;
              final isCorrect = isAnswered && session.answers.length > index 
                  ? session.answers[index].isCorrect 
                  : false;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _getQuestionColor(isAnswered, isCurrent, isCorrect),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: 16),
          
          // Légende
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                context,
                'Répondues',
                Colors.green,
              ),
              _buildLegendItem(
                context,
                'En cours',
                Colors.blue,
              ),
              _buildLegendItem(
                context,
                'Restantes',
                Colors.grey,
              ),
            ],
          ),
          
          if (isLastQuestion) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dernière question ! Votre simulation se terminera après cette réponse.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Color _getQuestionColor(bool isAnswered, bool isCurrent, bool isCorrect) {
    if (isAnswered) {
      return isCorrect ? Colors.green : Colors.red;
    } else if (isCurrent) {
      return Colors.blue;
    } else {
      return Colors.grey[300]!;
    }
  }
}
