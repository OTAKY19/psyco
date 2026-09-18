import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_service.dart';
import 'activation_service.dart';
import 'demo_service.dart';

class AppStateService extends ChangeNotifier {
  // Services
  final OfflineService _offlineService = OfflineService();
  final ActivationService _activationService = ActivationService();
  final DemoService _demoService = DemoService();
  
  // État de l'application
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  
  // État utilisateur
  bool _isActivated = false;
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _offlineStatus;
  
  // État de la démo
  bool _isDemoCompleted = false;
  bool _shouldShowDemo = false;
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isActivated => _isActivated;
  Map<String, dynamic>? get userStats => _userStats;
  Map<String, dynamic>? get offlineStatus => _offlineStatus;
  bool get isDemoCompleted => _isDemoCompleted;
  bool get shouldShowDemo => _shouldShowDemo;
  
  // Initialiser l'état de l'application
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Charger l'état d'activation
      _isActivated = await _activationService.isAppActivated();
      
      // Statistiques utilisateur fictives (service supprimé)
      _userStats = {
        'totalTests': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'weakCategories': [],
        'improvementSuggestions': [],
        'progressTrend': 'stable',
      };
      
      // Charger l'état hors-ligne
      _offlineStatus = await _offlineService.getOfflineStatus();
      
      // Vérifier l'état de la démo
      final demoStep = await _demoService.getNextDemoStep();
      _shouldShowDemo = demoStep != DemoStep.none;
      _isDemoCompleted = await _demoService.isSimulationDemoCompleted();
      
      _isInitialized = true;
      
      // Synchroniser les données si connecté
      if (_offlineStatus?['connected'] == true) {
        await _offlineService.syncPendingResults();
      }
      
    } catch (e) {
      _setError('Erreur d\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Activer l'application
  Future<void> activateApp(String subscriptionType, {String? transactionId}) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _activationService.activateAppWithSubscription(
        subscriptionType,
        transactionId: transactionId,
      );
      
      _isActivated = true;
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur d\'activation: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Enregistrer un résultat de test
  Future<void> recordTestResult(Map<String, dynamic> result) async {
    try {
      // Analytics supprimé - juste sauvegarder hors-ligne si nécessaire
      if (_offlineStatus?['connected'] != true) {
        await _offlineService.savePendingResult(result);
      }
      
      // Statistiques fictives (service supprimé)
      _userStats = {
        'totalTests': (_userStats?['totalTests'] ?? 0) + 1,
        'averageScore': result['score'] ?? 0.0,
        'bestScore': result['score'] ?? 0.0,
        'weakCategories': [],
        'improvementSuggestions': [],
        'progressTrend': 'stable',
      };
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur d\'enregistrement: $e');
    }
  }
  
  // Basculer le mode hors-ligne
  Future<void> toggleOfflineMode() async {
    _setLoading(true);
    
    try {
      final currentStatus = _offlineStatus?['enabled'] ?? false;
      await _offlineService.setOfflineMode(!currentStatus);
      
      _offlineStatus = await _offlineService.getOfflineStatus();
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur de mode hors-ligne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Marquer la démo comme terminée
  Future<void> completeDemoStep(DemoStep step) async {
    try {
      switch (step) {
        case DemoStep.showDemo:
          await _demoService.markDemoShown();
          break;
        case DemoStep.showPaymentSuggestion:
          await _demoService.markPaymentSuggestionShown();
          break;
        case DemoStep.showSimulationDemo:
          await _demoService.markSimulationDemoCompleted();
          _isDemoCompleted = true;
          break;
        case DemoStep.none:
          break;
      }
      
      // Vérifier la prochaine étape
      final nextStep = await _demoService.getNextDemoStep();
      _shouldShowDemo = nextStep != DemoStep.none;
      
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur de démo: $e');
    }
  }
  
  // Synchroniser les données
  Future<void> syncData() async {
    if (_offlineStatus?['connected'] != true) {
      _setError('Pas de connexion internet');
      return;
    }
    
    _setLoading(true);
    
    try {
      await _offlineService.syncPendingResults();
      _offlineStatus = await _offlineService.getOfflineStatus();
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur de synchronisation: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Rafraîchir les données
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Recharger toutes les données
      _isActivated = await _activationService.isAppActivated();
      // Statistiques fictives (service supprimé)
      _userStats = {
        'totalTests': _userStats?['totalTests'] ?? 0,
        'averageScore': _userStats?['averageScore'] ?? 0.0,
        'bestScore': _userStats?['bestScore'] ?? 0.0,
        'weakCategories': [],
        'improvementSuggestions': [],
        'progressTrend': 'stable',
      };
      _offlineStatus = await _offlineService.getOfflineStatus();
      
      final demoStep = await _demoService.getNextDemoStep();
      _shouldShowDemo = demoStep != DemoStep.none;
      _isDemoCompleted = await _demoService.isSimulationDemoCompleted();
      
      notifyListeners();
      
    } catch (e) {
      _setError('Erreur de rafraîchissement: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Réinitialiser l'application (pour les tests)
  Future<void> resetApp() async {
    _setLoading(true);
    
    try {
      await _activationService.resetActivation();
      await _demoService.resetDemoData();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Réinitialiser l'état
      _isActivated = false;
      _userStats = null;
      _offlineStatus = null;
      _isDemoCompleted = false;
      _shouldShowDemo = true;
      _isInitialized = false;
      
      // Réinitialiser
      await initialize();
      
    } catch (e) {
      _setError('Erreur de réinitialisation: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtenir les suggestions d'amélioration
  List<String> getImprovementSuggestions() {
    return _userStats?['improvementSuggestions'] ?? [];
  }
  
  // Obtenir les catégories faibles
  List<String> getWeakCategories() {
    return _userStats?['weakCategories'] ?? [];
  }
  
  // Obtenir la tendance de progression
  String getProgressTrend() {
    return _userStats?['progressTrend'] ?? 'stable';
  }
  
  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
