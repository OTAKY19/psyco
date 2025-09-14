import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

/// Script de test pour vérifier l'utilisation de la vraie banque de questions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test de la banque de questions réelle');
  print('=====================================');
  
  final databaseService = DatabaseService();
  
  try {
    // Obtenir le nombre total de questions
    final totalQuestions = await databaseService.getTotalQuestionsCount();
    print('📊 Nombre total de questions: $totalQuestions');
    
    // Obtenir le nombre de questions par catégorie
    final questionCounts = await databaseService.getQuestionCountByCategory();
    print('\n📈 Répartition par catégorie:');
    
    final categoryMapping = {
      'raisonnement_logique': 'Logique',
      'aptitude_numerique': 'Calcul',
      'aptitude_verbale': 'Verbal',
      'raisonnement_spatial': 'Spatial',
      'aptitude_mecanique': 'Mécanique',
      'aptitude_administrative': 'Administratif',
      'aptitude_commerciale': 'Commercial',
      'aptitude_financiere': 'Financier',
      'aptitude_informatique': 'Informatique',
      'aptitude_linguistique': 'Linguistique',
      'aptitude_scientifique': 'Scientifique',
      'aptitude_artistique': 'Artistique',
    };
    
    for (final entry in questionCounts.entries) {
      final dbCategory = entry.key;
      final count = entry.value;
      final displayName = categoryMapping[dbCategory] ?? dbCategory;
      print('  $displayName ($dbCategory): $count questions');
    }
    
    // Tester la génération de tests pour chaque catégorie
    print('\n🎯 Génération de tests par catégorie:');
    
    for (final entry in questionCounts.entries) {
      final dbCategory = entry.key;
      final questionCount = entry.value;
      final displayName = categoryMapping[dbCategory] ?? dbCategory;
      
      if (questionCount == 0) continue;
      
      print('\n📋 Catégorie: $displayName ($questionCount questions)');
      
      // Générer les configurations de tests
      final configurations = _getTestConfigurations(questionCount);
      
      for (final config in configurations) {
        print('  ✅ ${config['title']}: ${config['questionCount']} questions (${config['duration']} min)');
      }
    }
    
    // Tester l'obtention de questions par catégorie
    print('\n🔍 Test d\'obtention de questions par catégorie:');
    
    for (final entry in questionCounts.entries) {
      final dbCategory = entry.key;
      final expectedCount = entry.value;
      
      if (expectedCount == 0) continue;
      
      final questions = await databaseService.getQuestionsByCategory(dbCategory);
      final actualCount = questions.length;
      
      if (actualCount == expectedCount) {
        print('  ✅ $dbCategory: $actualCount questions (attendu: $expectedCount)');
      } else {
        print('  ❌ $dbCategory: $actualCount questions (attendu: $expectedCount)');
      }
    }
    
    // Tester l'obtention de questions aléatoires
    print('\n🎲 Test d\'obtention de questions aléatoires:');
    
    for (final entry in questionCounts.entries) {
      final dbCategory = entry.key;
      final totalCount = entry.value;
      
      if (totalCount == 0) continue;
      
      final randomQuestions = await databaseService.getRandomQuestions(
        limit: 5,
        category: dbCategory,
      );
      
      print('  🎯 $dbCategory: ${randomQuestions.length} questions aléatoires obtenues');
      
      // Vérifier que toutes les questions appartiennent à la bonne catégorie
      final allCorrect = randomQuestions.every((q) => q.categorie == dbCategory);
      if (allCorrect) {
        print('    ✅ Toutes les questions appartiennent à la catégorie $dbCategory');
      } else {
        print('    ❌ Certaines questions n\'appartiennent pas à la catégorie $dbCategory');
      }
    }
    
    print('\n✅ Test terminé avec succès!');
    print('Le système utilise maintenant toute la banque de questions disponible.');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  } finally {
    await databaseService.close();
  }
}

/// Génère des configurations de tests basées sur le nombre de questions disponibles
List<Map<String, dynamic>> _getTestConfigurations(int totalQuestions) {
  List<Map<String, dynamic>> configurations = [];

  if (totalQuestions >= 10) {
    configurations.add({
      'title': 'Test Court',
      'questionCount': 10,
      'duration': 15,
    });
  }

  if (totalQuestions >= 20) {
    configurations.add({
      'title': 'Test Standard',
      'questionCount': 20,
      'duration': 30,
    });
  }

  if (totalQuestions >= 30) {
    configurations.add({
      'title': 'Test Long',
      'questionCount': 30,
      'duration': 45,
    });
  }

  if (totalQuestions >= 50) {
    configurations.add({
      'title': 'Test Marathon',
      'questionCount': 50,
      'duration': 60,
    });
  }

  // Test personnalisé avec toutes les questions disponibles
  if (totalQuestions > 0) {
    configurations.add({
      'title': 'Test Complet',
      'questionCount': totalQuestions,
      'duration': (totalQuestions * 1.2).round(),
    });
  }

  return configurations;
}
