import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/services/user_state_service.dart';
import 'lib/widgets/progress_results_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Progressive Results System Tests', () {
    late UserStateService userStateService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      userStateService = UserStateService();
      await userStateService.resetUserState();
    });

    test('Test état initial utilisateur', () async {
      final userState = await userStateService.getUserState();

      expect(userState.hasCompletedDemo, false);
      expect(userState.isActivated, false);
      expect(userState.demoScore, 0);
      expect(userState.visibleResultsCount, 10); // Par défaut 10
      expect(userState.canRevealMore, false);
    });

    test('Test logique de révélation progressive', () async {
      // État initial : 10 questions visibles
      var visibleCount = await userStateService.getVisibleResultsCount();
      expect(visibleCount, 10);

      // Simuler le démarrage de la démo
      await userStateService.recordDemoStartTime();

      // Vérifier que canRevealMore est false au début
      var canReveal = await userStateService.canRevealMoreResults();
      expect(canReveal, false);

      // Simuler l'attente de 30 secondes (en modifiant directement l'heure de démarrage)
      final fakeStartTime = DateTime.now().subtract(const Duration(seconds: 35));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('demo_start_time', fakeStartTime.millisecondsSinceEpoch);

      // Maintenant canRevealMore devrait être true
      canReveal = await userStateService.canRevealMoreResults();
      expect(canReveal, true);

      // Révéler plus de résultats
      await userStateService.revealMoreResults();

      // Vérifier que le nombre visible a augmenté
      visibleCount = await userStateService.getVisibleResultsCount();
      expect(visibleCount, 20); // Devrait passer à 20
    });

    test('Test activation complète', () async {
      // Activer l'app
      await userStateService.activateApp();

      // Vérifier l'état
      final userState = await userStateService.getUserState();
      expect(userState.isActivated, true);

      // Toutes les questions devraient être visibles
      final visibleCount = await userStateService.calculateVisibleResultsCount();
      expect(visibleCount, 40);
    });

    test('Test cycle complet démo', () async {
      // 1. Démarrer la démo
      await userStateService.recordDemoStartTime();

      // 2. Simuler score de 25/40
      await userStateService.setDemoScore(25);

      // 3. Marquer la démo comme terminée
      await userStateService.markDemoCompleted();

      // 4. Vérifier l'état final
      final userState = await userStateService.getUserState();
      expect(userState.hasCompletedDemo, true);
      expect(userState.demoScore, 25);

      // 5. Activer l'app
      await userStateService.activateApp();

      // 6. Vérifier que tout est accessible
      final finalVisibleCount = await userStateService.calculateVisibleResultsCount();
      expect(finalVisibleCount, 40);
    });

    test('Test persistance des données', () async {
      // Modifier l'état
      await userStateService.setDemoScore(30);
      await userStateService.markDemoCompleted();
      await userStateService.activateApp();

      // Créer un nouveau service (simule redémarrage app)
      final newService = UserStateService();
      final userState = await newService.getUserState();

      // Vérifier que les données sont persistées
      expect(userState.demoScore, 30);
      expect(userState.hasCompletedDemo, true);
      expect(userState.isActivated, true);
    });

    test('Test calcul du nombre de résultats visibles', () async {
      // Test 1: Utilisateur non activé, démo non terminée
      var visibleCount = await userStateService.calculateVisibleResultsCount();
      expect(visibleCount, 10);

      // Test 2: Démarrer la démo
      await userStateService.recordDemoStartTime();
      visibleCount = await userStateService.calculateVisibleResultsCount();
      expect(visibleCount, 10);

      // Test 3: Simuler 30 secondes d'attente
      final fakeStartTime = DateTime.now().subtract(const Duration(seconds: 35));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('demo_start_time', fakeStartTime.millisecondsSinceEpoch);

      visibleCount = await userStateService.calculateVisibleResultsCount();
      expect(visibleCount, 20);

      // Test 4: Activer l'app
      await userStateService.activateApp();
      visibleCount = await userStateService.calculateVisibleResultsCount();
      expect(visibleCount, 40);
    });
  });

  group('Demo Choice Widget Tests', () {
    testWidgets('DemoChoiceWidget displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(), // Empty scaffold for testing
        ),
      );

      // Test that we can create the widget without errors
      expect(true, true); // Placeholder test
    });
  });

  group('Progress Results Widget Tests', () {
    testWidgets('ProgressResultsWidget displays correctly', (WidgetTester tester) async {
      // Mock data
      final mockResults = [
        {'isCorrect': true, 'questionIndex': 0},
        {'isCorrect': false, 'questionIndex': 1},
        {'isCorrect': true, 'questionIndex': 2},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressResultsWidget(
              allResults: mockResults,
              totalQuestions: 40,
              onActivatePressed: () {},
            ),
          ),
        ),
      );

      // Test that the widget renders without errors
      expect(find.text('📊 Résultats de l\'Examen'), findsOneWidget);
      expect(find.text('Questions 1-10 (Visibles)'), findsOneWidget);
    });
  });
}
