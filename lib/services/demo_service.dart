import 'package:shared_preferences/shared_preferences.dart';

class DemoService {
  static const String _firstLoginKey = 'first_login_completed';
  static const String _demoShownKey = 'demo_shown';
  static const String _paymentSuggestionShownKey = 'payment_suggestion_shown';
  static const String _simulationDemoCompletedKey = 'simulation_demo_completed';

  // Vérifier si c'est la première connexion
  Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_firstLoginKey) ?? false);
  }

  // Marquer la première connexion comme terminée
  Future<void> markFirstLoginCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLoginKey, true);
  }

  // Vérifier si la démo a été montrée
  Future<bool> isDemoShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_demoShownKey) ?? false;
  }

  // Marquer la démo comme montrée
  Future<void> markDemoShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoShownKey, true);
  }

  // Vérifier si la suggestion de paiement a été montrée
  Future<bool> isPaymentSuggestionShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentSuggestionShownKey) ?? false;
  }

  // Marquer la suggestion de paiement comme montrée
  Future<void> markPaymentSuggestionShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_paymentSuggestionShownKey, true);
  }

  // Vérifier si la démo de simulation est terminée
  Future<bool> isSimulationDemoCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_simulationDemoCompletedKey) ?? false;
  }

  // Marquer la démo de simulation comme terminée
  Future<void> markSimulationDemoCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_simulationDemoCompletedKey, true);
  }

  // Vérifier si on doit afficher la séquence de démonstration
  Future<DemoStep> getNextDemoStep() async {
    final isFirst = await isFirstLogin();
    if (!isFirst) return DemoStep.none;

    final demoShown = await isDemoShown();
    if (!demoShown) return DemoStep.showDemo;

    final paymentShown = await isPaymentSuggestionShown();
    if (!paymentShown) return DemoStep.showPaymentSuggestion;

    final simulationCompleted = await isSimulationDemoCompleted();
    if (!simulationCompleted) return DemoStep.showSimulationDemo;

    return DemoStep.none;
  }

  // Réinitialiser toutes les données de démo (pour les tests)
  Future<void> resetDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLoginKey);
    await prefs.remove(_demoShownKey);
    await prefs.remove(_paymentSuggestionShownKey);
    await prefs.remove(_simulationDemoCompletedKey);
  }
}

enum DemoStep {
  none,
  showDemo,
  showPaymentSuggestion,
  showSimulationDemo,
}
