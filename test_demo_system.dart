import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/services/demo_service.dart';
import 'lib/services/activation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demo System Tests', () {
    late DemoService demoService;
    late ActivationService activationService;

    setUp(() async {
      // Initialiser SharedPreferences pour les tests
      SharedPreferences.setMockInitialValues({});
      demoService = DemoService();
      activationService = ActivationService();

      // Réinitialiser les données de test
      await demoService.resetDemoData();
      await activationService.resetActivation();
    });

    test('Test première connexion - démo doit être affichée', () async {
      // Vérifier que c'est la première connexion
      final isFirstLogin = await demoService.isFirstLogin();
      expect(isFirstLogin, true);

      // Vérifier que la démo n'a pas encore été montrée
      final demoShown = await demoService.isDemoShown();
      expect(demoShown, false);

      // Vérifier l'étape suivante de la démo
      final nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showDemo);
    });

    test('Test séquence complète de démonstration', () async {
      // Étape 1: Première connexion - montrer la démo
      var nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showDemo);

      // Marquer la démo comme montrée
      await demoService.markDemoShown();
      await demoService.markFirstLoginCompleted();

      // Étape 2: Après la démo - montrer la suggestion de paiement
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showPaymentSuggestion);

      // Marquer la suggestion de paiement comme montrée
      await demoService.markPaymentSuggestionShown();

      // Étape 3: Après la suggestion - montrer la simulation de démo
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showSimulationDemo);

      // Marquer la simulation de démo comme terminée
      await demoService.markSimulationDemoCompleted();

      // Étape 4: Tout est terminé - aucune étape suivante
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.none);
    });

    test('Test app non activée - fonctionnalités bloquées', () async {
      // Vérifier que l'app n'est pas activée
      final isActivated = await activationService.isAppActivated();
      expect(isActivated, false);

      // Vérifier que c'est la première connexion pour l'activation
      final shouldShowPrompt = await activationService.shouldShowActivationPrompt();
      expect(shouldShowPrompt, true);
    });

    test('Test app activée - fonctionnalités débloquées', () async {
      // Activer l'app
      await activationService.activateApp();

      // Vérifier que l'app est activée
      final isActivated = await activationService.isAppActivated();
      expect(isActivated, true);

      // Vérifier que le prompt d'activation ne doit plus être affiché
      final shouldShowPrompt = await activationService.shouldShowActivationPrompt();
      expect(shouldShowPrompt, false);
    });

    test('Test réinitialisation des données', () async {
      // Modifier quelques données
      await demoService.markDemoShown();
      await demoService.markFirstLoginCompleted();
      await demoService.markPaymentSuggestionShown();
      await demoService.markSimulationDemoCompleted();
      await activationService.activateApp();

      // Vérifier que les données sont modifiées
      expect(await demoService.isDemoShown(), true);
      expect(await demoService.isFirstLogin(), false);
      expect(await activationService.isAppActivated(), true);

      // Réinitialiser
      await demoService.resetDemoData();
      await activationService.resetActivation();

      // Vérifier que tout est réinitialisé
      expect(await demoService.isDemoShown(), false);
      expect(await demoService.isFirstLogin(), true);
      expect(await activationService.isAppActivated(), false);
    });

    test('Test logique des étapes de démonstration', () async {
      // Test étape par étape
      var nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showDemo);

      // Après avoir marqué la démo comme montrée mais pas la première connexion
      await demoService.markDemoShown();
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showDemo); // Doit encore montrer la démo car première connexion pas marquée

      // Marquer la première connexion comme terminée
      await demoService.markFirstLoginCompleted();
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showPaymentSuggestion);

      // Marquer la suggestion de paiement comme montrée
      await demoService.markPaymentSuggestionShown();
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.showSimulationDemo);

      // Marquer la simulation comme terminée
      await demoService.markSimulationDemoCompleted();
      nextStep = await demoService.getNextDemoStep();
      expect(nextStep, DemoStep.none);
    });
  });

  group('Activation Logic Tests', () {
    late ActivationService activationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      activationService = ActivationService();
      await activationService.resetActivation();
    });

    test('Test premier examen terminé tracking', () async {
      // Vérifier que le premier examen n'est pas marqué comme terminé
      var isCompleted = await activationService.isFirstExamCompleted();
      expect(isCompleted, false);

      // Marquer le premier examen comme terminé
      await activationService.markFirstExamCompleted();

      // Vérifier qu'il est maintenant marqué comme terminé
      isCompleted = await activationService.isFirstExamCompleted();
      expect(isCompleted, true);
    });

    test('Test logique du prompt d\'activation', () async {
      // Au début, l'app n'est pas activée et le prompt n'a pas été montré
      var shouldShow = await activationService.shouldShowActivationPrompt();
      expect(shouldShow, true);

      // Marquer le prompt comme montré
      await activationService.markActivationPromptShown();

      // Maintenant le prompt ne devrait plus être affiché
      shouldShow = await activationService.shouldShowActivationPrompt();
      expect(shouldShow, false);

      // Même si on réinitialise (sauf l'activation), le prompt ne devrait pas être affiché
      await activationService.resetActivation();
      shouldShow = await activationService.shouldShowActivationPrompt();
      expect(shouldShow, true); // Reviens à true car tout est réinitialisé
    });
  });
}
