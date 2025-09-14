import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ExamNavigationWidget extends StatelessWidget {
  final bool hasPrevious;
  final bool hasNext;
  final bool isLastQuestion;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onComplete;

  const ExamNavigationWidget({
    super.key,
    required this.hasPrevious,
    required this.hasNext,
    required this.isLastQuestion,
    required this.onPrevious,
    required this.onNext,
    required this.onComplete,
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
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          Expanded(
            child: OutlinedButton.icon(
              onPressed: hasPrevious ? onPrevious : null,
              icon: Icon(Icons.arrow_back_ios, size: 16),
              label: Text('Précédent'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Bouton Suivant/Terminer
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLastQuestion ? onComplete : onNext,
              icon: Icon(
                isLastQuestion ? Icons.check : Icons.arrow_forward_ios,
                size: 16,
              ),
              label: Text(isLastQuestion ? 'Terminer' : 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion ? Colors.green : Colors.blue,
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
    );
  }
}
