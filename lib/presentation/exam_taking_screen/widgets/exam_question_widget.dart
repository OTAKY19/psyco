import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/question.dart';

class ExamQuestionWidget extends StatefulWidget {
  final Question question;
  final int? selectedAnswer;
  final Function(int) onAnswerSelected;

  const ExamQuestionWidget({
    super.key,
    required this.question,
    this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<ExamQuestionWidget> createState() => _ExamQuestionWidgetState();
}

class _ExamQuestionWidgetState extends State<ExamQuestionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de la question
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getCategoryColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getCategoryLabel(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: _getCategoryColor(),
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDifficultyLabel(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: _getDifficultyColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Texte de la question
              Text(
                widget.question.question,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              
              // Image si nécessaire
              if (widget.question.imagePath != null) ...[
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.question.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 24),
              
              // Options de réponse
              ...widget.question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = widget.selectedAnswer == index;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => widget.onAnswerSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.blue
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Indicateur de sélection
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected 
                                  ? Colors.blue
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.blue
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          
                          SizedBox(width: 16),
                          
                          // Lettre de l'option
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blue
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected 
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: 16),
                          
                          // Texte de l'option
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isSelected 
                                    ? Colors.blue[800]
                                    : Colors.grey[800],
                                fontWeight: isSelected 
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.question.categorie) {
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

  String _getCategoryLabel() {
    switch (widget.question.categorie) {
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
        return widget.question.categorie;
    }
  }

  Color _getDifficultyColor() {
    switch (widget.question.niveau) {
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

  String _getDifficultyLabel() {
    switch (widget.question.niveau) {
      case 'facile':
        return 'Facile';
      case 'moyen':
        return 'Moyen';
      case 'difficile':
        return 'Difficile';
      default:
        return widget.question.niveau;
    }
  }
}
