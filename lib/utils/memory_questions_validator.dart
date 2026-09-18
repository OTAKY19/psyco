import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/question.dart';
import '../services/memory_question_service.dart';
import 'memory_question_utils.dart';

/// Validateur pour analyser toutes les questions mémoire du projet
class MemoryQuestionsValidator {
  static final MemoryQuestionsValidator _instance = MemoryQuestionsValidator._internal();
  factory MemoryQuestionsValidator() => _instance;
  MemoryQuestionsValidator._internal();

  final MemoryQuestionService _memoryService = MemoryQuestionService();
  
  /// Analyser tous les fichiers JSON de questions
  Future<MemoryValidationReport> validateAllMemoryQuestions() async {
    final report = MemoryValidationReport();
    
    final jsonFiles = [
      'assets/data/questions_balanced.json',
      'assets/data/questions_consolidees.json',
      'assets/data/questions_difficiles_200.json',
      'assets/data/questions_final.json',
      'assets/data/questions_optimized.json',
    ];

    for (final filePath in jsonFiles) {
      try {
        if (kDebugMode) {
          debugPrint('🔍 Analyse du fichier: $filePath');
        }
        
        final fileReport = await _analyzeJsonFile(filePath);
        report.addFileReport(filePath, fileReport);
        
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Erreur analyse $filePath: $e');
        }
        report.errors.add('Erreur fichier $filePath: $e');
      }
    }

    _generateSummary(report);
    return report;
  }

  /// Analyser un fichier JSON spécifique
  Future<FileValidationReport> _analyzeJsonFile(String filePath) async {
    final fileReport = FileValidationReport();
    
    try {
      final jsonString = await rootBundle.loadString(filePath);
      final List<dynamic> questionsJson = json.decode(jsonString);
      
      fileReport.totalQuestions = questionsJson.length;
      
      for (final questionData in questionsJson) {
        final question = Question.fromJson(questionData);
        
        // Vérifier si c'est une question mémoire
        final isMemoryQuestion = MemoryQuestionUtils.isMemoryQuestion(question.question);
        
        if (isMemoryQuestion) {
          fileReport.memoryQuestions++;
          
          // Analyser la question
          final analysis = _memoryService.analyzeQuestion(question);
          
          final questionReport = QuestionValidationReport(
            id: question.id,
            originalText: question.question,
            analysis: analysis,
          );
          
          fileReport.questionReports.add(questionReport);
          
          // Compter les erreurs
          if (!analysis.isValid) {
            fileReport.invalidQuestions++;
          }
        }
      }
      
    } catch (e) {
      fileReport.errors.add('Erreur parsing JSON: $e');
    }
    
    return fileReport;
  }

  /// Générer un résumé global
  void _generateSummary(MemoryValidationReport report) {
    int totalMemoryQuestions = 0;
    int totalInvalidQuestions = 0;
    Map<MemorySequenceType, int> typeCount = {};
    Map<String, int> errorCount = {};
    
    for (final fileReport in report.fileReports.values) {
      totalMemoryQuestions += fileReport.memoryQuestions;
      totalInvalidQuestions += fileReport.invalidQuestions;
      
      for (final questionReport in fileReport.questionReports) {
        // Compter les types
        final type = questionReport.analysis.sequenceType;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
        
        // Compter les erreurs
        for (final error in questionReport.analysis.errors) {
          errorCount[error] = (errorCount[error] ?? 0) + 1;
        }
      }
    }
    
    report.summary = ValidationSummary(
      totalMemoryQuestions: totalMemoryQuestions,
      totalInvalidQuestions: totalInvalidQuestions,
      typeDistribution: typeCount,
      errorDistribution: errorCount,
    );
    
    if (kDebugMode) {
      _printSummary(report.summary);
    }
  }

  /// Afficher le résumé dans la console
  void _printSummary(ValidationSummary summary) {
    debugPrint('\n${'='*50}');
    debugPrint('📊 RAPPORT DE VALIDATION DES QUESTIONS MÉMOIRE');
    debugPrint('='*50);
    debugPrint('📈 Total questions mémoire: ${summary.totalMemoryQuestions}');
    debugPrint('❌ Questions invalides: ${summary.totalInvalidQuestions}');
    debugPrint('✅ Questions valides: ${summary.totalMemoryQuestions - summary.totalInvalidQuestions}');
    debugPrint('📊 Taux de validité: ${((summary.totalMemoryQuestions - summary.totalInvalidQuestions) / summary.totalMemoryQuestions * 100).toStringAsFixed(1)}%');
    
    debugPrint('\n🎯 RÉPARTITION PAR TYPE:');
    summary.typeDistribution.forEach((type, count) {
      debugPrint('   ${_getTypeIcon(type)} ${_getTypeName(type)}: $count');
    });
    
    if (summary.errorDistribution.isNotEmpty) {
      debugPrint('\n⚠️ ERREURS DÉTECTÉES:');
      summary.errorDistribution.forEach((error, count) {
        debugPrint('   • $error: $count fois');
      });
    }
    
    debugPrint('\n💡 RECOMMANDATIONS:');
    if (summary.totalInvalidQuestions > 0) {
      debugPrint('   • Corriger les ${summary.totalInvalidQuestions} questions invalides');
    }
    if (summary.errorDistribution.containsKey('Incohérence couleur/animaux')) {
      debugPrint('   • Vérifier les questions demandant des couleurs pour des animaux');
    }
    if (summary.errorDistribution.containsKey('Séquence vide')) {
      debugPrint('   • Améliorer la détection des séquences');
    }
    
    debugPrint('='*50);
  }

  String _getTypeIcon(MemorySequenceType type) {
    switch (type) {
      case MemorySequenceType.numbers: return '🔢';
      case MemorySequenceType.letters: return '🔤';
      case MemorySequenceType.colors: return '🎨';
      case MemorySequenceType.words: return '📝';
      case MemorySequenceType.symbols: return '🔣';
      case MemorySequenceType.mixed: return '🔀';
      default: return '❓';
    }
  }

  String _getTypeName(MemorySequenceType type) {
    switch (type) {
      case MemorySequenceType.numbers: return 'Nombres';
      case MemorySequenceType.letters: return 'Lettres';
      case MemorySequenceType.colors: return 'Couleurs';
      case MemorySequenceType.words: return 'Mots';
      case MemorySequenceType.symbols: return 'Symboles';
      case MemorySequenceType.mixed: return 'Mixte';
      default: return 'Inconnu';
    }
  }

  /// Générer un rapport détaillé en JSON
  Map<String, dynamic> generateDetailedReport(MemoryValidationReport report) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'summary': {
        'total_memory_questions': report.summary.totalMemoryQuestions,
        'invalid_questions': report.summary.totalInvalidQuestions,
        'validity_rate': ((report.summary.totalMemoryQuestions - report.summary.totalInvalidQuestions) / 
                         report.summary.totalMemoryQuestions * 100),
        'type_distribution': report.summary.typeDistribution.map((k, v) => MapEntry(k.toString(), v)),
        'error_distribution': report.summary.errorDistribution,
      },
      'files': report.fileReports.map((file, fileReport) => MapEntry(file, {
        'total_questions': fileReport.totalQuestions,
        'memory_questions': fileReport.memoryQuestions,
        'invalid_questions': fileReport.invalidQuestions,
        'errors': fileReport.errors,
        'questions': fileReport.questionReports.map((q) => {
          'id': q.id,
          'valid': q.analysis.isValid,
          'type': q.analysis.sequenceType.toString(),
          'sequence': q.analysis.sequence,
          'question': q.analysis.questionText,
          'duration': q.analysis.recommendedDuration,
          'errors': q.analysis.errors,
        }).toList(),
      })),
    };
  }
}

/// Rapport de validation global
class MemoryValidationReport {
  final Map<String, FileValidationReport> fileReports = {};
  final List<String> errors = [];
  late ValidationSummary summary;

  void addFileReport(String filePath, FileValidationReport report) {
    fileReports[filePath] = report;
  }
}

/// Rapport de validation par fichier
class FileValidationReport {
  int totalQuestions = 0;
  int memoryQuestions = 0;
  int invalidQuestions = 0;
  final List<QuestionValidationReport> questionReports = [];
  final List<String> errors = [];
}

/// Rapport de validation par question
class QuestionValidationReport {
  final int id;
  final String originalText;
  final MemoryQuestionAnalysis analysis;

  QuestionValidationReport({
    required this.id,
    required this.originalText,
    required this.analysis,
  });
}

/// Résumé de validation
class ValidationSummary {
  final int totalMemoryQuestions;
  final int totalInvalidQuestions;
  final Map<MemorySequenceType, int> typeDistribution;
  final Map<String, int> errorDistribution;

  ValidationSummary({
    required this.totalMemoryQuestions,
    required this.totalInvalidQuestions,
    required this.typeDistribution,
    required this.errorDistribution,
  });
}
