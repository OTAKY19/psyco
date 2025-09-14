import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';
import 'lib/services/exam_blanc_service.dart';

/// Script de test pour vérifier le fonctionnement de la base de données
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Test de fonctionnalité de la base de données');
  print('===============================================');
  
  try {
    // Test 1: Initialisation de la base de données
    print('\n📋 Test 1: Initialisation de la base de données');
    final databaseService = DatabaseService();
    await databaseService.database;
    print('✅ Base de données initialisée avec succès');
    
    // Test 2: Vérification du nombre de questions
    print('\n📋 Test 2: Vérification du chargement des questions');
    final totalQuestions = await databaseService.getTotalQuestionsCount();
    print('✅ Nombre total de questions: $totalQuestions');
    
    if (totalQuestions == 0) {
      print('⚠️  Aucune question trouvée - la base de données pourrait ne pas être initialisée');
      return;
    }
    
    // Test 3: Vérification par catégorie
    print('\n📋 Test 3: Vérification des questions par catégorie');
    final questionsByCategory = await databaseService.getQuestionCountByCategory();
    print('✅ Répartition par catégorie:');
    questionsByCategory.forEach((category, count) {
      print('   $category: $count questions');
    });
    
    // Test 4: Test de récupération de questions aléatoires
    print('\n📋 Test 4: Récupération de questions aléatoires');
    final randomQuestions = await databaseService.getRandomQuestions(limit: 5);
    print('✅ ${randomQuestions.length} questions aléatoires récupérées');
    
    for (int i = 0; i < randomQuestions.length; i++) {
      final q = randomQuestions[i];
      print('   Question ${i+1}: ${q.question.substring(0, 50)}...');
      print('   Catégorie: ${q.categorie}, Niveau: ${q.niveau}');
    }
    
    // Test 5: Test des examens blancs
    print('\n📋 Test 5: Test des examens blancs');
    final examService = ExamBlancService();
    final exams = await examService.loadAllExams();
    print('✅ ${exams.length} examens blancs chargés');
    
    for (final exam in exams) {
      print('   ${exam.title}: ${exam.questions.length} questions');
    }
    
    // Test 6: Test de création de session d'examen
    if (exams.isNotEmpty) {
      print('\n📋 Test 6: Création de session d\'examen');
      final firstExam = exams.first;
      final session = await examService.createExamSession(firstExam.id, 'test_user');
      print('✅ Session d\'examen créée: ${session.id}');
      print('   Examen: ${session.exam.title}');
      print('   Questions: ${session.exam.questions.length}');
    }
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    print('La base de données et les examens blancs fonctionnent correctement.');
    
  } catch (e) {
    print('\n❌ Erreur lors des tests: $e');
    print('Vérifiez que les fichiers de données sont présents et correctement formatés.');
  }
}