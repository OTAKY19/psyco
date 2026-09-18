import 'package:flutter/foundation.dart';

/// Utilitaires pour la détection et gestion des questions mémoire
class MemoryQuestionUtils {
  
  /// Détecte si une question est de type mémoire
  static bool isMemoryQuestion(String questionText) {
    final memoryKeywords = [
      'reten',
      'mémoris',
      'suite',
      'séquence',
      'mémoire',
      'retenez',
      'mémorisez',
      'cette suite',
      'cette séquence',
      'rappelez-vous',
      'souvenez-vous'
    ];

    final lowerText = questionText.toLowerCase();
    
    // Vérifier les mots-clés
    bool hasKeyword = memoryKeywords.any((keyword) => lowerText.contains(keyword));
    
    // Vérifier la structure typique : "mot : éléments. Question ?"
    bool hasStructure = lowerText.contains(':') && 
                       (lowerText.contains('quel') || lowerText.contains('quelle'));
    
    if (kDebugMode) {
      debugPrint('🔍 [MemoryUtils] Analyse question: "${questionText.substring(0, questionText.length > 50 ? 50 : questionText.length)}..."');
      debugPrint('   - Mot-clé trouvé: $hasKeyword');
      debugPrint('   - Structure détectée: $hasStructure');
    }
    
    return hasKeyword || hasStructure;
  }

  /// Extrait la séquence à mémoriser d'une question
  static String extractMemorySequence(String questionText) {
    if (kDebugMode) {
      debugPrint('🔍 [MemoryUtils] Extraction séquence de: "$questionText"');
    }
    
    // Patterns améliorés pour capturer différents formats
    final patterns = [
      RegExp(r'[Rr]etenez.*?:\s*([^.?!]+)', caseSensitive: false),
      RegExp(r'[Mm]émorisez.*?:\s*([^.?!]+)', caseSensitive: false),
      RegExp(r'cette\s+suite\s*:\s*([^.?!]+)', caseSensitive: false),
      RegExp(r'cette\s+séquence\s*:\s*([^.?!]+)', caseSensitive: false),
      RegExp(r'suite\s*:\s*([^.?!]+)', caseSensitive: false),
      RegExp(r'séquence\s*:\s*([^.?!]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(questionText);
      if (match != null && match.groupCount >= 1) {
        final sequence = match.group(1)?.trim() ?? '';
        if (kDebugMode) {
          debugPrint('✅ [MemoryUtils] Séquence extraite: "$sequence"');
        }
        return sequence;
      }
    }

    // Fallback: chercher après le premier deux-points
    final colonIndex = questionText.indexOf(':');
    if (colonIndex != -1) {
      final afterColon = questionText.substring(colonIndex + 1).trim();
      // Chercher jusqu'au premier point, point d'interrogation ou d'exclamation
      final endMarkers = ['.', '?', '!'];
      int endIndex = afterColon.length;
      
      for (final marker in endMarkers) {
        final markerIndex = afterColon.indexOf(marker);
        if (markerIndex != -1 && markerIndex < endIndex) {
          endIndex = markerIndex;
        }
      }
      
      final sequence = afterColon.substring(0, endIndex).trim();
      if (kDebugMode) {
        debugPrint('🔄 [MemoryUtils] Fallback séquence: "$sequence"');
      }
      return sequence;
    }

    if (kDebugMode) {
      debugPrint('❌ [MemoryUtils] Aucune séquence trouvée');
    }
    return 'Séquence non trouvée';
  }

  /// Extrait la question réelle après la séquence
  static String extractMemoryQuestion(String questionText) {
    if (kDebugMode) {
      debugPrint('🔍 [MemoryUtils] Extraction question de: "$questionText"');
    }
    
    final questionPatterns = [
      RegExp(r'[Qq]uel.*?est.*?élément.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uelle.*?était.*?couleur.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uel.*?était.*?élément.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uelle.*?était.*?position.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uel.*?était.*?lettre.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uel.*?était.*?chiffre.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uel.*?\?', caseSensitive: false),
      RegExp(r'[Qq]uelle.*?\?', caseSensitive: false),
    ];

    for (final pattern in questionPatterns) {
      final match = pattern.firstMatch(questionText);
      if (match != null) {
        final question = match.group(0)?.trim() ?? '';
        if (kDebugMode) {
          debugPrint('✅ [MemoryUtils] Question extraite: "$question"');
        }
        return question;
      }
    }

    // Fallback: chercher après le premier point
    final markers = ['.', '!'];
    for (final marker in markers) {
      final markerIndex = questionText.indexOf(marker);
      if (markerIndex != -1) {
        final afterMarker = questionText.substring(markerIndex + 1).trim();
        if (afterMarker.isNotEmpty && afterMarker.contains('?')) {
          if (kDebugMode) {
            debugPrint('🔄 [MemoryUtils] Fallback question: "$afterMarker"');
          }
          return afterMarker;
        }
      }
    }

    // Question générique basée sur le contenu
    const genericQuestion = 'Répondez à la question sur la séquence mémorisée.';
    if (kDebugMode) {
      debugPrint('🔄 [MemoryUtils] Question générique: "$genericQuestion"');
    }
    return genericQuestion;
  }
}
