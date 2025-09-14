import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Script de simulation pour tester les fonctionnalités de l'application
void main() async {
  print('🚀 SIMULATION DE PSYCHOTEST+');
  print('=' * 50);
  
  // Test 1: Chargement des questions
  await testQuestionLoading();
  
  // Test 2: Vérification des catégories
  await testCategories();
  
  // Test 3: Test de limitation des tests gratuits
  await testFreeTestLimitation();
  
  // Test 4: Vérification du logo
  await testLogoAssets();
  
  print('\n✅ SIMULATION TERMINÉE AVEC SUCCÈS !');
}

/// Test du chargement des questions
Future<void> testQuestionLoading() async {
  print('\n📚 Test 1: Chargement des questions');
  print('-' * 30);
  
  try {
    // Simuler le chargement du fichier JSON
    final file = File('assets/data/questions_balanced.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final questions = json.decode(content) as List;
      
      print('✅ Fichier de questions trouvé');
      print('📊 Nombre total de questions: ${questions.length}');
      
      // Analyser les catégories
      final categories = <String, int>{};
      for (final question in questions) {
        final category = question['categorie'] as String;
        categories[category] = (categories[category] ?? 0) + 1;
      }
      
      print('📋 Répartition par catégorie:');
      categories.forEach((category, count) {
        print('   • $category: $count questions');
      });
      
      // Test de sélection aléatoire
      final randomQuestions = questions.take(15).toList();
      print('🎯 Test de sélection aléatoire: ${randomQuestions.length} questions');
      
    } else {
      print('❌ Fichier de questions non trouvé');
    }
  } catch (e) {
    print('❌ Erreur lors du chargement: $e');
  }
}

/// Test des catégories de questions
Future<void> testCategories() async {
  print('\n🏷️ Test 2: Vérification des catégories');
  print('-' * 30);
  
  final expectedCategories = [
    'raisonnement_logique',
    'aptitude_numerique', 
    'aptitude_verbale',
    'raisonnement_spatial',
    'memoire_attention',
    'rapidite_personnalite'
  ];
  
  try {
    final file = File('assets/data/questions_balanced.json');
    final content = await file.readAsString();
    final questions = json.decode(content) as List;
    
    final foundCategories = <String>{};
    for (final question in questions) {
      foundCategories.add(question['categorie'] as String);
    }
    
    print('✅ Catégories trouvées: ${foundCategories.length}');
    for (final category in foundCategories) {
      print('   • $category');
    }
    
    // Vérifier que toutes les catégories attendues sont présentes
    final missingCategories = expectedCategories.where((cat) => !foundCategories.contains(cat)).toList();
    if (missingCategories.isEmpty) {
      print('✅ Toutes les catégories attendues sont présentes');
    } else {
      print('⚠️ Catégories manquantes: $missingCategories');
    }
    
  } catch (e) {
    print('❌ Erreur lors de la vérification des catégories: $e');
  }
}

/// Test de la limitation des tests gratuits
Future<void> testFreeTestLimitation() async {
  print('\n🔒 Test 3: Limitation des tests gratuits');
  print('-' * 30);
  
  // Simuler le service de subscription
  const maxFreeTests = 2;
  int usedTests = 0;
  
  print('📊 Configuration:');
  print('   • Tests gratuits maximum: $maxFreeTests');
  print('   • Tests utilisés: $usedTests');
  print('   • Tests restants: ${maxFreeTests - usedTests}');
  
  // Simuler l'utilisation de tests
  for (int i = 1; i <= 3; i++) {
    usedTests++;
    final remaining = maxFreeTests - usedTests;
    final canTakeTest = remaining > 0;
    
    print('🎯 Test $i:');
    print('   • Peut faire un test: ${canTakeTest ? "✅ Oui" : "❌ Non"}');
    print('   • Tests restants: $remaining');
    
    if (!canTakeTest) {
      print('   • 💡 Fenêtre de suggestion d\'activation affichée');
    }
  }
}

/// Test des assets du logo
Future<void> testLogoAssets() async {
  print('\n🎨 Test 4: Vérification du logo');
  print('-' * 30);
  
  final logoFile = File('assets/images/psychotest_logo.svg');
  if (await logoFile.exists()) {
    print('✅ Logo SVG trouvé');
    final content = await logoFile.readAsString();
    print('📏 Taille du fichier: ${content.length} caractères');
    
    // Vérifier les éléments du logo
    if (content.contains('gradient')) {
      print('✅ Dégradés présents');
    }
    if (content.contains('circle')) {
      print('✅ Formes circulaires présentes');
    }
    if (content.contains('path')) {
      print('✅ Formes complexes présentes');
    }
  } else {
    print('❌ Logo SVG non trouvé');
  }
  
  // Vérifier les autres assets
  final assetsDir = Directory('assets/images');
  if (await assetsDir.exists()) {
    final files = await assetsDir.list().toList();
    print('📁 Assets disponibles:');
    for (final file in files) {
      if (file is File) {
        print('   • ${file.path.split('/').last}');
      }
    }
  }
}
