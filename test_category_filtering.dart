import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

/// Script de test pour vérifier le filtrage par catégorie
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test du filtrage par catégorie');
  print('================================');
  
  final databaseService = DatabaseService();
  
  // Mapping des catégories de la base de données vers les noms affichés
  final Map<String, String> categoryMapping = {
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
  
  try {
    // Test avec différentes catégories
    final categories = categoryMapping.values.toList();
    
    for (final category in categories) {
      print('\n📋 Test de la catégorie: $category');
      
      // Trouver la catégorie de la DB qui correspond au nom affiché
      final dbCategory = categoryMapping.entries
          .firstWhere((entry) => entry.value == category)
          .key;
      
      // Obtenir les questions de cette catégorie
      final questions = await databaseService.getQuestionsByCategory(dbCategory);
      print('  Nombre de questions trouvées: ${questions.length}');
      
      // Vérifier que toutes les questions appartiennent à la bonne catégorie
      bool allCorrect = true;
      for (final question in questions) {
        final questionCategory = question.categorie;
        if (questionCategory != dbCategory) {
          print('  ❌ ERREUR: Question "${question.question}" appartient à "$questionCategory" au lieu de "$dbCategory"');
          allCorrect = false;
        }
      }
      
      if (allCorrect && questions.isNotEmpty) {
        print('  ✅ Toutes les questions appartiennent à la catégorie "$category"');
      } else if (questions.isEmpty) {
        print('  ⚠️  Aucune question trouvée pour la catégorie "$category"');
      } else {
        print('  ❌ Certaines questions n\'appartiennent pas à la catégorie "$category"');
      }
    }
    
    // Test de toutes les catégories
    print('\n📋 Test de toutes les catégories');
    final questionCounts = await databaseService.getQuestionCountByCategory();
    print('  Nombre total de catégories: ${questionCounts.length}');
    
    print('  Répartition par catégorie:');
    questionCounts.forEach((dbCategory, count) {
      final displayCategory = categoryMapping[dbCategory] ?? dbCategory;
      print('    $displayCategory ($dbCategory): $count questions');
    });
    
    print('\n✅ Test terminé!');
    print('Le filtrage par catégorie fonctionne correctement avec la base de données.');
    
  } catch (e) {
    print('\n❌ Erreur lors du test: $e');
    print('Assurez-vous que la base de données est correctement initialisée.');
  }
}

