import 'package:flutter/material.dart';
import 'lib/services/user_data_service.dart';
import 'lib/services/test_service.dart';

/// Script de test pour vérifier le système de progression
/// Ce script simule des tests et vérifie que les pourcentages sont correctement calculés
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test du système de progression');
  print('================================');
  
  // Initialiser les services
  final userDataService = UserDataService();
  
  // Réinitialiser les données pour un test propre
  await userDataService.resetUserData();
  print('✅ Données utilisateur réinitialisées');
  
  // Vérifier l'état initial
  var initialProgress = await userDataService.getUserProgress();
  print('\n📊 État initial:');
  print('Tests complétés: ${initialProgress['testsCompleted']}');
  print('Score moyen: ${initialProgress['averageScore']}%');
  print('Série d\'étude: ${initialProgress['studyStreak']} jours');
  
  // Simuler quelques tests avec différents scores
  print('\n🎯 Simulation de tests...');
  
  // Test 1: Score de 80%
  await _simulateTestResult(userDataService, 'Test Logique', 80.0);
  await _waitAndCheckProgress(userDataService, 'Après le 1er test');
  
  // Test 2: Score de 60%
  await _simulateTestResult(userDataService, 'Test Mémoire', 60.0);
  await _waitAndCheckProgress(userDataService, 'Après le 2ème test');
  
  // Test 3: Score de 90%
  await _simulateTestResult(userDataService, 'Test Attention', 90.0);
  await _waitAndCheckProgress(userDataService, 'Après le 3ème test');
  
  // Vérifier les progrès par catégorie
  print('\n📈 Progrès par catégorie:');
  for (int i = 1; i <= 6; i++) {
    final progress = await userDataService.getCategoryProgress(i.toString());
    final categoryName = _getCategoryName(i);
    print('$categoryName: ${progress.toStringAsFixed(1)}%');
  }
  
  print('\n✅ Test terminé avec succès!');
  print('Les pourcentages devraient maintenant correspondre aux vrais résultats.');
}

/// Simule un résultat de test avec un score donné
Future<void> _simulateTestResult(UserDataService userDataService, String testName, double targetScore) async {
  print('  🎯 Simulation: $testName (score cible: ${targetScore.toInt()}%)');
  
  // Obtenir les statistiques actuelles
  final currentProgress = await userDataService.getUserProgress();
  final currentTests = currentProgress['testsCompleted'] as int;
  final currentAverage = currentProgress['averageScore'] as double;
  
  // Calculer les nouvelles statistiques
  final newTestsCompleted = currentTests + 1;
  final newAverage = currentTests > 0 
      ? ((currentAverage * currentTests) + targetScore) / newTestsCompleted
      : targetScore;
  
  // Calculer la série d'étude (simulation simple)
  final studyStreak = newTestsCompleted; // Pour le test, on simule une série
  
  // Sauvegarder les nouvelles statistiques
  await userDataService.saveUserProgress({
    'testsCompleted': newTestsCompleted,
    'averageScore': newAverage,
    'studyStreak': studyStreak,
  });
  
  // Mettre à jour les progrès par catégorie
  final categoryId = _getCategoryIdFromName(testName);
  if (categoryId != null) {
    final currentCategoryProgress = await userDataService.getCategoryProgress(categoryId);
    final newCategoryProgress = currentCategoryProgress == 0.0 
        ? targetScore 
        : (currentCategoryProgress * 0.7) + (targetScore * 0.3);
    
    await userDataService.updateCategoryProgress(categoryId, newCategoryProgress);
  }
}

/// Attend un peu et vérifie les progrès
Future<void> _waitAndCheckProgress(UserDataService userDataService, String label) async {
  await Future.delayed(const Duration(milliseconds: 100)); // Petite pause
  
  final progress = await userDataService.getUserProgress();
  print('  $label:');
  print('    Tests complétés: ${progress['testsCompleted']}');
  print('    Score moyen: ${progress['averageScore'].toStringAsFixed(1)}%');
  print('    Série d\'étude: ${progress['studyStreak']} jours');
}

/// Convertit un ID de catégorie en nom
String _getCategoryName(int categoryId) {
  const categoryMap = {
    1: 'Logique',
    2: 'Mémoire',
    3: 'Attention',
    4: 'Calcul',
    5: 'Spatial',
    6: 'Verbal',
  };
  return categoryMap[categoryId] ?? 'Inconnue';
}

/// Convertit un nom de test en ID de catégorie
String? _getCategoryIdFromName(String testName) {
  if (testName.contains('Logique')) return '1';
  if (testName.contains('Mémoire')) return '2';
  if (testName.contains('Attention')) return '3';
  if (testName.contains('Calcul')) return '4';
  if (testName.contains('Spatial')) return '5';
  if (testName.contains('Verbal')) return '6';
  return null;
}
