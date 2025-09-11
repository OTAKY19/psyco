import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les abonnements, limitations et paiements mobile money
class SubscriptionService {
  // Constants
  static const String _freeTestsCountKey = 'free_tests_count';
  static const String _isPremiumKey = 'is_premium_user';
  static const String _subscriptionDateKey = 'subscription_date';
  static const String _paymentTransactionKey = 'payment_transaction_id';
  static const String _paymentMethodKey = 'payment_method';
  static const String _subscriptionTypeKey = 'subscription_type';
  
  // Limites
  static const int maxFreeTests = 3;
  static const double premiumPrice = 5000.0; // Prix en francs CFA ou autre devise locale

  // Singleton
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  /// Vérifie si l'utilisateur peut faire un test
  Future<bool> canTakeTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Si l'utilisateur est premium, pas de limitation
      if (await isPremiumUser()) {
        return true;
      }
      
      // Sinon, vérifier le nombre de tests gratuits restants
      final testsUsed = prefs.getInt(_freeTestsCountKey) ?? 0;
      return testsUsed < maxFreeTests;
    } catch (e) {
      // En cas d'erreur, permettre le test par défaut
      return true;
    }
  }

  /// Récupère le nombre de tests gratuits restants
  Future<int> getRemainingFreeTests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testsUsed = prefs.getInt(_freeTestsCountKey) ?? 0;
      return maxFreeTests - testsUsed;
    } catch (e) {
      return maxFreeTests;
    }
  }

  /// Incrémente le compteur de tests gratuits utilisés
  Future<void> incrementFreeTestsUsed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(_freeTestsCountKey) ?? 0;
      await prefs.setInt(_freeTestsCountKey, currentCount + 1);
      
      print('[SubscriptionService] Tests gratuits utilisés: ${currentCount + 1}/$maxFreeTests');
    } catch (e) {
      print('[SubscriptionService] Erreur lors de l\'incrémentation des tests: $e');
    }
  }

  /// Vérifie si l'utilisateur est premium
  Future<bool> isPremiumUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isPremiumKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Active le compte premium après paiement
  Future<bool> activatePremiumAccount({
    required String transactionId,
    required String paymentMethod,
    String subscriptionType = 'lifetime',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Marquer comme premium
      await prefs.setBool(_isPremiumKey, true);
      await prefs.setString(_subscriptionDateKey, DateTime.now().toIso8601String());
      await prefs.setString(_paymentTransactionKey, transactionId);
      await prefs.setString(_paymentMethodKey, paymentMethod);
      await prefs.setString(_subscriptionTypeKey, subscriptionType);
      
      print('[SubscriptionService] Compte premium activé avec succès!');
      print('[SubscriptionService] Transaction ID: $transactionId');
      print('[SubscriptionService] Méthode: $paymentMethod');
      
      return true;
    } catch (e) {
      print('[SubscriptionService] Erreur lors de l\'activation premium: $e');
      return false;
    }
  }

  /// Récupère les informations d'abonnement
  Future<Map<String, dynamic>> getSubscriptionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'isPremium': prefs.getBool(_isPremiumKey) ?? false,
        'subscriptionDate': prefs.getString(_subscriptionDateKey),
        'transactionId': prefs.getString(_paymentTransactionKey),
        'paymentMethod': prefs.getString(_paymentMethodKey),
        'subscriptionType': prefs.getString(_subscriptionTypeKey) ?? 'lifetime',
        'freeTestsUsed': prefs.getInt(_freeTestsCountKey) ?? 0,
        'freeTestsRemaining': maxFreeTests - (prefs.getInt(_freeTestsCountKey) ?? 0),
      };
    } catch (e) {
      return {
        'isPremium': false,
        'subscriptionDate': null,
        'transactionId': null,
        'paymentMethod': null,
        'subscriptionType': 'lifetime',
        'freeTestsUsed': 0,
        'freeTestsRemaining': maxFreeTests,
      };
    }
  }

  /// Simule le traitement d'un paiement mobile money
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String phoneNumber,
    required String paymentMethod, // 'orange_money', 'mtn_money', 'moov_money', etc.
    required double amount,
  }) async {
    try {
      print('[SubscriptionService] Traitement paiement Mobile Money...');
      print('[SubscriptionService] Téléphone: $phoneNumber');
      print('[SubscriptionService] Méthode: $paymentMethod');
      print('[SubscriptionService] Montant: $amount');

      // Simulation d'un appel API au service de paiement mobile money
      await Future.delayed(const Duration(seconds: 3));
      
      // Générer un ID de transaction simulé
      final transactionId = 'MM${DateTime.now().millisecondsSinceEpoch}';
      
      // Simuler différents scénarios (85% de succès)
      final success = DateTime.now().millisecond % 100 < 85;
      
      if (success) {
        return {
          'success': true,
          'transactionId': transactionId,
          'message': 'Paiement effectué avec succès',
          'amount': amount,
          'paymentMethod': paymentMethod,
          'phoneNumber': phoneNumber,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'Paiement échoué. Veuillez vérifier votre solde ou réessayer.',
          'errorCode': 'PAYMENT_FAILED',
        };
      }
    } catch (e) {
      print('[SubscriptionService] Erreur lors du paiement: $e');
      return {
        'success': false,
        'error': 'Erreur technique. Veuillez réessayer.',
        'errorCode': 'TECHNICAL_ERROR',
      };
    }
  }

  /// Vérifie le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      print('[SubscriptionService] Vérification du statut de paiement: $transactionId');
      
      // Simulation d'un appel API de vérification
      await Future.delayed(const Duration(seconds: 2));
      
      // Simuler différents statuts
      final statuses = ['pending', 'completed', 'failed'];
      final status = statuses[DateTime.now().millisecond % statuses.length];
      
      return {
        'transactionId': transactionId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'transactionId': transactionId,
        'status': 'unknown',
        'error': e.toString(),
      };
    }
  }

  /// Obtient la liste des méthodes de paiement mobile money disponibles
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'id': 'orange_money',
        'name': 'Orange Money',
        'icon': 'orange_money_icon',
        'color': 0xFFFF6600,
        'instructions': 'Composez *144# pour Orange Money',
        'available': true,
      },
      {
        'id': 'mtn_money',
        'name': 'MTN Mobile Money',
        'icon': 'mtn_money_icon', 
        'color': 0xFFFFCC00,
        'instructions': 'Composez *133# pour MTN Money',
        'available': true,
      },
      {
        'id': 'moov_money',
        'name': 'Moov Money',
        'icon': 'moov_money_icon',
        'color': 0xFF00AEEF,
        'instructions': 'Composez *555# pour Moov Money',
        'available': true,
      },
      {
        'id': 'wave',
        'name': 'Wave',
        'icon': 'wave_icon',
        'color': 0xFF6C5CE7,
        'instructions': 'Utilisez votre application Wave',
        'available': true,
      },
      {
        'id': 'free_money',
        'name': 'Free Money',
        'icon': 'free_money_icon',
        'color': 0xFF00B894,
        'instructions': 'Composez *880# pour Free Money',
        'available': true,
      },
    ];
  }

  /// Remet à zéro les compteurs (pour tests ou débogage)
  Future<void> resetSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_freeTestsCountKey);
      await prefs.remove(_isPremiumKey);
      await prefs.remove(_subscriptionDateKey);
      await prefs.remove(_paymentTransactionKey);
      await prefs.remove(_paymentMethodKey);
      await prefs.remove(_subscriptionTypeKey);
      
      print('[SubscriptionService] Abonnement remis à zéro');
    } catch (e) {
      print('[SubscriptionService] Erreur lors de la remise à zéro: $e');
    }
  }

  /// Fonction utilitaire pour formater le prix selon la devise locale
  String formatPrice(double amount, {String currency = 'CFA'}) {
    return '${amount.toStringAsFixed(0)} $currency';
  }

  /// Vérifie si le numéro de téléphone est valide pour les paiements mobile money
  bool isValidPhoneNumber(String phoneNumber, String paymentMethod) {
    // Nettoyer le numéro
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    switch (paymentMethod) {
      case 'orange_money':
        // Orange : commence par 07 ou 77 (8 chiffres au total)
        return RegExp(r'^(07|77)\d{6}$').hasMatch(phoneNumber);
      case 'mtn_money':
        // MTN : commence par 06 ou 76 (8 chiffres au total)
        return RegExp(r'^(06|76)\d{6}$').hasMatch(phoneNumber);
      case 'moov_money':
        // Moov : commence par 05 ou 75 (8 chiffres au total)
        return RegExp(r'^(05|75)\d{6}$').hasMatch(phoneNumber);
      case 'wave':
        // Wave : plus flexible, tout numéro local valide
        return RegExp(r'^(05|06|07|75|76|77)\d{6}$').hasMatch(phoneNumber);
      case 'free_money':
        // Free : commence par 04 ou 74 (8 chiffres au total)
        return RegExp(r'^(04|74)\d{6}$').hasMatch(phoneNumber);
      default:
        return phoneNumber.length >= 8;
    }
  }
}
