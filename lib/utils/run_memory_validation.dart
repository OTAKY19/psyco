import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;

import '../services/memory_question_service.dart';
import 'memory_questions_validator.dart';

/// Script pour exécuter la validation des questions mémoire
/// Usage: dart run lib/utils/run_memory_validation.dart
void main() async {
  debugPrint('🚀 DÉMARRAGE DE LA VALIDATION DES QUESTIONS MÉMOIRE');
  debugPrint('=' * 60);

  try {
    final validator = MemoryQuestionsValidator();

    // Exécuter la validation
    final report = await validator.validateAllMemoryQuestions();

    // Générer le rapport détaillé
    final detailedReport = validator.generateDetailedReport(report);

    // Sauvegarder le rapport
    final reportFile = File('memory_validation_report.json');
    await reportFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(detailedReport));

    debugPrint('\n✅ VALIDATION TERMINÉE !');
    debugPrint('📄 Rapport sauvegardé: ${reportFile.absolute.path}');

    // Afficher les actions recommandées
    _printRecommendedActions(report);
  } catch (e) {
    debugPrint('❌ ERREUR LORS DE LA VALIDATION: $e');
    exit(1);
  }
}

void _printRecommendedActions(MemoryValidationReport report) {
  debugPrint('\n🎯 ACTIONS RECOMMANDÉES:');

  if (report.summary.totalInvalidQuestions > 0) {
    debugPrint(
        '1. 🔧 Corriger ${report.summary.totalInvalidQuestions} questions invalides');
  }

  if (report.summary.errorDistribution
      .containsKey('Incohérence couleur/animaux')) {
    final count =
        report.summary.errorDistribution['Incohérence couleur/animaux']!;
    debugPrint(
        '2. 🎨 Corriger $count questions demandant des couleurs pour des animaux');
  }

  if (report.summary.errorDistribution.containsKey('Séquence vide')) {
    final count = report.summary.errorDistribution['Séquence vide']!;
    debugPrint(
        '3. 🔍 Améliorer la détection pour $count questions avec séquences vides');
  }

  if (report.summary.errorDistribution.containsKey('Question générique')) {
    final count = report.summary.errorDistribution['Question générique']!;
    debugPrint(
        '4. ❓ Remplacer $count questions génériques par des questions spécifiques');
  }

  debugPrint('\n💡 SUGGESTIONS D\'AMÉLIORATION:');
  debugPrint(
      '• Ajouter plus de questions avec des symboles/emojis (${report.summary.typeDistribution[MemorySequenceType.symbols] ?? 0} actuellement)');
  debugPrint(
      '• Équilibrer les types de séquences pour une meilleure diversité');
  debugPrint('• Implémenter des durées adaptatives selon la difficulté');
  debugPrint('• Ajouter des questions mémoire de niveau intermédiaire');
}
