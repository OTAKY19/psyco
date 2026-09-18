import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/app_export.dart';
import '../../../utils/memory_question_utils.dart';
import 'memory_question_widget.dart';

class QuestionContentWidget extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final int? selectedOption;
  final Function(int) onOptionSelected;
  final String? questionImage;

  const QuestionContentWidget({
    super.key,
    required this.questionText,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
    this.questionImage,
  });

  int _calculateMemoryDuration(String questionText) {
    final sequence = MemoryQuestionUtils.extractMemorySequence(questionText);
    
    // Durée de base selon le type de contenu
    int baseDuration = 3;
    
    // Détecter les emojis/symboles (plus difficile)
    if (RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(sequence)) {
      baseDuration = 5;
    }
    // Détecter les couleurs
    else if (['rouge', 'bleu', 'vert', 'jaune', 'blanc'].any((color) => 
        sequence.toLowerCase().contains(color))) {
      baseDuration = 3;
    }
    // Détecter les nombres purs
    else if (RegExp(r'^[\d\s,.-]+$').hasMatch(sequence)) {
      baseDuration = 2;
    }
    // Détecter les mots (plus difficile)
    else if (sequence.split(RegExp(r'[,\s-–]+')).length > 3) {
      baseDuration = 4;
    }
    
    // Ajuster selon la longueur
    final elements = sequence.split(RegExp(r'[,\s-–]+'));
    if (elements.length > 6) baseDuration += 1;
    if (elements.length > 8) baseDuration += 1;
    
    return baseDuration.clamp(2, 8);
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier si c'est une question mémoire
    final isMemoryQuestion = MemoryQuestionUtils.isMemoryQuestion(questionText);
    
    if (isMemoryQuestion) {
      if (kDebugMode) {
        debugPrint('🧠 [QuestionContentWidget] Question mémoire détectée');
      }
      
      // Utiliser le widget mémoire spécialisé
      return MemoryQuestionWidget(
        memorySequence: MemoryQuestionUtils.extractMemorySequence(questionText),
        questionText: MemoryQuestionUtils.extractMemoryQuestion(questionText),
        options: options,
        selectedOption: selectedOption,
        onOptionSelected: onOptionSelected,
        displayDuration: _calculateMemoryDuration(questionText),
      );
    }
    
    // Question normale
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question',
                  style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  questionText,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // Question Image (if available)
                if (questionImage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: questionImage!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Options Label
          Text(
            'Choisissez votre réponse :',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Answer Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedOption == index;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: GestureDetector(
                onTap: () => onOptionSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.lg),

                      // Option Text
                      Expanded(
                        child: Text(
                          option,
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),

                      // Selection Indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: AppSpacing.massive), // Extra space for navigation buttons
        ],
      ),
    );
  }
}