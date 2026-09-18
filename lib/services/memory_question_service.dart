import '../models/question.dart';
import '../utils/memory_question_utils.dart';

/// Service pour gérer les questions mémoire
class MemoryQuestionService {
  static final MemoryQuestionService _instance = MemoryQuestionService._internal();
  factory MemoryQuestionService() => _instance;
  MemoryQuestionService._internal();

  /// Analyser une question mémoire
  MemoryQuestionAnalysis analyzeQuestion(Question question) {
    final analysis = MemoryQuestionAnalysis();
    
    analysis.isMemoryQuestion = MemoryQuestionUtils.isMemoryQuestion(question.question);
    if (!analysis.isMemoryQuestion) return analysis;

    analysis.sequence = MemoryQuestionUtils.extractMemorySequence(question.question);
    analysis.questionText = MemoryQuestionUtils.extractMemoryQuestion(question.question);
    analysis.sequenceType = _getSequenceType(analysis.sequence);
    analysis.recommendedDuration = _getDuration(analysis.sequenceType, analysis.sequence);
    analysis.errors = _validateQuestion(question, analysis);
    analysis.isValid = analysis.errors.isEmpty;

    return analysis;
  }

  MemorySequenceType _getSequenceType(String sequence) {
    if (RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true).hasMatch(sequence)) {
      return MemorySequenceType.symbols;
    }
    if (['rouge', 'bleu', 'vert', 'jaune'].any((c) => sequence.toLowerCase().contains(c))) {
      return MemorySequenceType.colors;
    }
    if (RegExp(r'^\d+').hasMatch(sequence)) return MemorySequenceType.numbers;
    if (RegExp(r'^[A-Za-z]').hasMatch(sequence)) return MemorySequenceType.letters;
    return MemorySequenceType.words;
  }

  int _getDuration(MemorySequenceType type, String sequence) {
    final baseTime = {
      MemorySequenceType.numbers: 2,
      MemorySequenceType.letters: 3,
      MemorySequenceType.colors: 3,
      MemorySequenceType.words: 4,
      MemorySequenceType.symbols: 5,
    }[type] ?? 3;
    
    final elements = sequence.split(RegExp(r'[,\s-–]+'));
    return (baseTime + (elements.length > 6 ? 1 : 0)).clamp(2, 8);
  }

  List<String> _validateQuestion(Question question, MemoryQuestionAnalysis analysis) {
    final errors = <String>[];
    
    if (analysis.sequence.isEmpty) errors.add('Séquence vide');
    if (analysis.questionText.contains('Répondez à la question')) errors.add('Question générique');
    
    // Erreur: demander couleur pour animaux
    if (analysis.questionText.toLowerCase().contains('couleur') && 
        ['chat', 'chien', 'oiseau'].any((a) => analysis.sequence.toLowerCase().contains(a))) {
      errors.add('Incohérence couleur/animaux');
    }
    
    return errors;
  }
}

/// Types de séquences mémoire
enum MemorySequenceType { numbers, letters, colors, words, symbols, mixed, unknown }

/// Analyse d'une question mémoire
class MemoryQuestionAnalysis {
  bool isMemoryQuestion = false;
  String sequence = '';
  String questionText = '';
  MemorySequenceType sequenceType = MemorySequenceType.unknown;
  int recommendedDuration = 3;
  List<String> errors = [];
  bool isValid = false;
}
