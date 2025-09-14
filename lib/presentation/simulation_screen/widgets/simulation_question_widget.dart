import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/simulation_model.dart';
import '../../../services/simulation_service.dart';

class SimulationQuestionWidget extends StatefulWidget {
  final SimulationSession session;
  final Function(String) onAnswer;
  final VoidCallback? onQuestionTimeUp;

  const SimulationQuestionWidget({
    Key? key,
    required this.session,
    required this.onAnswer,
    this.onQuestionTimeUp,
  }) : super(key: key);

  @override
  State<SimulationQuestionWidget> createState() => _SimulationQuestionWidgetState();
}

class _SimulationQuestionWidgetState extends State<SimulationQuestionWidget> {
  String? _selectedOption;
  final SimulationService _simulationService = SimulationService();

  @override
  void initState() {
    super.initState();
    _selectedOption = null;
  }

  @override
  void didUpdateWidget(SimulationQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.currentQuestionIndex != widget.session.currentQuestionIndex) {
      _selectedOption = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _simulationService.getCurrentQuestion(widget.session);
    
    if (currentQuestion == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Simulation terminée !',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la question
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${widget.session.currentQuestionIndex + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryDisplayName(currentQuestion.categorie),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        'Niveau: ${_getLevelDisplayName(currentQuestion.niveau)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer de la question
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuestionTimeColor(widget.session.currentQuestionRemainingTime),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _simulationService.formatTime(widget.session.currentQuestionRemainingTime),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Question
          Text(
            currentQuestion.question,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          
          SizedBox(height: 24),
          
          // Options de réponse
          ...currentQuestion.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedOption = option;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedOption == option
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedOption == option
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: _selectedOption == option ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedOption == option
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            optionLetter,
                            style: TextStyle(
                              color: _selectedOption == option
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: _selectedOption == option
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_selectedOption == option)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          
          SizedBox(height: 32),
          
          // Bouton de validation
          if (_selectedOption != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onAnswer(_selectedOption!);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Valider la réponse',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'culture_generale':
        return 'Culture Générale';
      case 'francais':
        return 'Français';
      case 'droit_douane':
        return 'Droit de la Douane';
      case 'mathematiques':
        return 'Mathématiques';
      case 'logique':
        return 'Logique';
      case 'ethique_personnalite':
        return 'Éthique & Personnalité';
      default:
        return category;
    }
  }

  String _getLevelDisplayName(String level) {
    switch (level) {
      case 'facile':
        return 'Facile';
      case 'moyen':
        return 'Moyen';
      case 'difficile':
        return 'Difficile';
      default:
        return level;
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
