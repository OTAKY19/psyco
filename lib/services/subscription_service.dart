import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Constantes pour les limites et prix
  static const int maxFreeTests = 10;
  static const double premiumPrice = 2499.0;
  static const double basicPrice = 3000.0;
  static const double annualPrice = 10000.0;

  // Clés pour SharedPreferences
  static const String _freeTestsUsedKey = 'free_tests_used';
  static const String _subscriptionTypeKey = 'subscription_type';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _lastResetKey = 'last_reset';
  // Mirroir de UserStateService._hasLifetimeAccessKey (accès à vie post-paiement)
  static const String _lifetimeAccessKey = 'has_lifetime_access';

  /// Vérifie si l'utilisateur peut faire un test gratuit
  Future<bool> canTakeFreeTest() async {
    final prefs = await SharedPreferences.getInstance();
    final usedTests = prefs.getInt(_freeTestsUsedKey) ?? 0;
    return usedTests < maxFreeTests;
  }

  /// Incrémente le compteur de tests gratuits utilisés
  Future<void> incrementFreeTestCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_freeTestsUsedKey) ?? 0;
    await prefs.setInt(_freeTestsUsedKey, currentCount + 1);
  }

  /// Obtient le nombre de tests gratuits restants
  Future<int> getRemainingFreeTests() async {
    final prefs = await SharedPreferences.getInstance();
    final usedTests = prefs.getInt(_freeTestsUsedKey) ?? 0;
    return (maxFreeTests - usedTests).clamp(0, maxFreeTests);
  }

  /// Obtient le nombre de tests gratuits utilisés
  Future<int> getUsedFreeTests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_freeTestsUsedKey) ?? 0;
  }

  /// Réinitialise le compteur de tests gratuits (mensuel)
  Future<void> resetFreeTestsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString(_lastResetKey);
    final now = DateTime.now();

    if (lastReset != null) {
      final lastResetDate = DateTime.parse(lastReset);
      final daysSinceReset = now.difference(lastResetDate).inDays;

      // Réinitialise chaque mois
      if (daysSinceReset >= 30) {
        await prefs.setInt(_freeTestsUsedKey, 0);
        await prefs.setString(_lastResetKey, now.toIso8601String());
      }
    } else {
      // Première fois
      await prefs.setString(_lastResetKey, now.toIso8601String());
    }
  }

  /// Vérifie si l'utilisateur a un abonnement actif
  Future<bool> hasActiveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionType = prefs.getString(_subscriptionTypeKey);

    if (subscriptionType == null || subscriptionType == 'free') {
      return false;
    }

    final expiryString = prefs.getString(_subscriptionExpiryKey);
    if (expiryString != null) {
      final expiryDate = DateTime.parse(expiryString);
      return expiryDate.isAfter(DateTime.now());
    }

    return false;
  }

  /// Obtient le type d'abonnement actuel
  Future<String> getCurrentSubscriptionType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionTypeKey) ?? 'free';
  }

  /// Définit le type d'abonnement
  Future<void> setSubscriptionType(String type, {DateTime? expiryDate}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionTypeKey, type);

    if (expiryDate != null) {
      await prefs.setString(
          _subscriptionExpiryKey, expiryDate.toIso8601String());
    }
  }

  /// Obtient la date d'expiration de l'abonnement
  Future<DateTime?> getSubscriptionExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_subscriptionExpiryKey);

    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }

    return null;
  }

  /// Formate un prix en FCFA
  String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }

  /// Calcule le prix avec remise pour l'abonnement annuel
  double calculateAnnualDiscount() {
    const monthlyTotal = premiumPrice * 12;
    return monthlyTotal - annualPrice;
  }

  /// Obtient les informations d'abonnement formatées
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    final hasSubscription = await hasActiveSubscription();
    final subscriptionType = await getCurrentSubscriptionType();
    final remainingFreeTests = await getRemainingFreeTests();
    final expiryDate = await getSubscriptionExpiry();

    return {
      'isPremium': hasSubscription,
      'hasActiveSubscription': hasSubscription,
      'subscriptionType': subscriptionType,
      'remainingFreeTests': remainingFreeTests,
      'totalFreeTests': maxFreeTests,
      'expiryDate': expiryDate,
      'prices': {
        'basic': basicPrice,
        'premium': premiumPrice,
        'annual': annualPrice,
      },
      'formattedPrices': {
        'basic': formatPrice(basicPrice),
        'premium': formatPrice(premiumPrice),
        'annual': formatPrice(annualPrice),
      },
    };
  }

  /// Réinitialise tous les compteurs (pour les tests)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_freeTestsUsedKey);
    await prefs.remove(_subscriptionTypeKey);
    await prefs.remove(_subscriptionExpiryKey);
    await prefs.remove(_lastResetKey);
  }

  /// Vérifie si l'utilisateur peut accéder à une fonctionnalité premium
  Future<bool> canAccessPremiumFeature(String feature) async {
    final hasSubscription = await hasActiveSubscription();

    if (hasSubscription) {
      return true;
    }

    // Certaines fonctionnalités peuvent être accessibles avec des tests gratuits
    switch (feature) {
      case 'basic_tests':
        return true; // Tests basiques toujours accessibles (freemium)
      case 'premium_tests':
      case 'advanced_stats':
      case 'unlimited_access':
        return false;
      default:
        return false;
    }
  }

  /// Obtient les statistiques d'utilisation
  Future<Map<String, dynamic>> getUsageStats() async {
    final usedTests = await getUsedFreeTests();
    final remainingTests = await getRemainingFreeTests();
    final hasSubscription = await hasActiveSubscription();
    final subscriptionType = await getCurrentSubscriptionType();

    return {
      'usedFreeTests': usedTests,
      'remainingFreeTests': remainingTests,
      'totalFreeTests': maxFreeTests,
      'hasActiveSubscription': hasSubscription,
      'subscriptionType': subscriptionType,
      'usagePercentage':
          maxFreeTests > 0 ? (usedTests / maxFreeTests * 100).round() : 0,
    };
  }

  /// Vérifie si l'utilisateur peut faire un test
  Future<bool> canTakeTest() async {
    if (await hasActiveSubscription()) return true;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_lifetimeAccessKey) ?? false) return true;
    final usedTests = prefs.getInt(_freeTestsUsedKey) ?? 0;
    return usedTests < maxFreeTests;
  }

  /// Vérifie si l'utilisateur est premium
  Future<bool> isPremiumUser() async {
    if (await hasActiveSubscription()) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lifetimeAccessKey) ?? false;
  }

  /// Marque un test gratuit comme utilisé
  Future<void> markFreeTestUsed() async {
    await incrementFreeTestCount();
  }

  /// Incrémente le compteur de tests gratuits utilisés (alias)
  Future<void> incrementFreeTestsUsed() async {
    await incrementFreeTestCount();
  }

  /// Valide un numéro de téléphone pour une méthode de paiement
  bool isValidPhoneNumber(String phoneNumber, String paymentMethod) {
    if (paymentMethod == 'mtn') {
      return isValidMtnNumber(phoneNumber);
    }
    // Pour les autres méthodes, validation basique
    return phoneNumber.length >= 8;
  }

  /// Valide un numéro MTN (méthode publique)
  bool isValidMtnNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length != 8) return false;
    return cleanNumber.startsWith('9') || cleanNumber.startsWith('6');
  }

  /// Traite un paiement mobile money
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required double amount,
    required String phoneNumber,
    required String paymentMethod,
    required String description,
  }) async {
    // Simulation de traitement de paiement
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount,
      'phoneNumber': phoneNumber,
      'method': paymentMethod,
      'status': 'completed',
      'message': 'Paiement traité avec succès',
    };
  }

  /// Vérifie le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));

    return {
      'status': 'completed',
      'transactionId': transactionId,
      'message': 'Paiement confirmé',
    };
  }

  /// Active un compte premium
  Future<bool> activatePremiumAccount({
    required String transactionId,
    required double amount,
  }) async {
    try {
      // Calculer la durée basée sur le montant
      int durationDays = 30; // Par défaut 30 jours
      if (amount >= annualPrice) {
        durationDays = 365;
      } else if (amount >= premiumPrice) {
        durationDays = 90;
      }

      final expiryDate = DateTime.now().add(Duration(days: durationDays));
      await setSubscriptionType('premium', expiryDate: expiryDate);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obtient les méthodes de paiement disponibles
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'id': 'mtn',
        'name': 'MTN Mobile Money',
        'description': 'Paiement via MTN Mobile Money',
        'icon': 'phone_android',
        'enabled': true,
      },
      {
        'id': 'orange',
        'name': 'Orange Money',
        'description': 'Paiement via Orange Money',
        'icon': 'phone_android',
        'enabled': false,
      },
      {
        'id': 'moov',
        'name': 'Moov Money',
        'description': 'Paiement via Moov Money',
        'icon': 'phone_android',
        'enabled': false,
      },
    ];
  }
}

// Fin subscription_service.dart
