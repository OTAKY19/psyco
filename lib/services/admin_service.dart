import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String _adminModeKey = 'admin_mode_enabled';
  static const String _adminPasswordKey = 'admin_password';
  
  // Mot de passe admin par défaut (à changer en production)
  static const String defaultAdminPassword = 'admin123';
  
  // Singleton
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  /// Vérifie si le mode admin est activé
  Future<bool> isAdminModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_adminModeKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Active le mode admin
  Future<bool> enableAdminMode(String password) async {
    try {
      if (password != defaultAdminPassword) {
        return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminModeKey, true);
      await prefs.setString(_adminPasswordKey, password);
      
      print('[AdminService] Mode admin activé');
      return true;
    } catch (e) {
      print('[AdminService] Erreur lors de l\'activation du mode admin: $e');
      return false;
    }
  }

  /// Désactive le mode admin
  Future<void> disableAdminMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminModeKey, false);
      await prefs.remove(_adminPasswordKey);
      
      print('[AdminService] Mode admin désactivé');
    } catch (e) {
      print('[AdminService] Erreur lors de la désactivation du mode admin: $e');
    }
  }

  /// Vérifie si un mot de passe admin est correct
  Future<bool> verifyAdminPassword(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPassword = prefs.getString(_adminPasswordKey);
      return storedPassword == password || password == defaultAdminPassword;
    } catch (e) {
      return password == defaultAdminPassword;
    }
  }

  /// Réinitialise tous les compteurs et données de test
  Future<void> resetAllCounters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Réinitialiser les tests gratuits
      await prefs.remove('free_tests_count');
      
      // Réinitialiser le statut premium
      await prefs.remove('is_premium_user');
      await prefs.remove('subscription_date');
      await prefs.remove('payment_transaction_id');
      await prefs.remove('payment_method');
      await prefs.remove('subscription_type');
      
      // Réinitialiser les résultats d'examens
      await prefs.remove('exam_results');
      await prefs.remove('user_progress');
      
      print('[AdminService] Tous les compteurs ont été réinitialisés');
    } catch (e) {
      print('[AdminService] Erreur lors de la réinitialisation: $e');
    }
  }

  /// Force l'activation du compte premium (mode admin)
  Future<void> forceActivatePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('is_premium_user', true);
      await prefs.setString('subscription_date', DateTime.now().toIso8601String());
      await prefs.setString('payment_transaction_id', 'ADMIN_${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString('payment_method', 'admin_mode');
      await prefs.setString('subscription_type', 'lifetime');
      
      print('[AdminService] Compte premium forcé activé');
    } catch (e) {
      print('[AdminService] Erreur lors de l\'activation forcée: $e');
    }
  }

  /// Force la désactivation du compte premium (mode admin)
  Future<void> forceDeactivatePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('is_premium_user', false);
      await prefs.remove('subscription_date');
      await prefs.remove('payment_transaction_id');
      await prefs.remove('payment_method');
      await prefs.remove('subscription_type');
      
      print('[AdminService] Compte premium forcé désactivé');
    } catch (e) {
      print('[AdminService] Erreur lors de la désactivation forcée: $e');
    }
  }

  /// Définit le nombre de tests gratuits restants (mode admin)
  Future<void> setFreeTestsCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('free_tests_count', count);
      
      print('[AdminService] Nombre de tests gratuits défini à: $count');
    } catch (e) {
      print('[AdminService] Erreur lors de la définition du nombre de tests: $e');
    }
  }

  /// Obtient les informations de debug
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'adminModeEnabled': await isAdminModeEnabled(),
        'isPremiumUser': prefs.getBool('is_premium_user') ?? false,
        'freeTestsUsed': prefs.getInt('free_tests_count') ?? 0,
        'subscriptionDate': prefs.getString('subscription_date'),
        'paymentMethod': prefs.getString('payment_method'),
        'subscriptionType': prefs.getString('subscription_type'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
