import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  static const String _activationKey = 'app_activated';
  static const String _subscriptionTypeKey = 'subscription_type';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _paymentHistoryKey = 'payment_history';
  static const String _firstExamCompletedKey = 'first_exam_completed';
  static const String _activationPromptShownKey = 'activation_prompt_shown';
  static const String _trialStartKey = 'trial_start';
  static const String _trialUsedKey = 'trial_used';

  // Types d'activation disponibles
  static const Map<String, Map<String, dynamic>> _subscriptionPlans = {
    'trial': {
      'name': 'Essai Gratuit',
      'duration_days': 7,
      'price': 0.0,
      'features': ['Accès limité', '3 tests par jour', 'Support basique'],
    },
    'basic': {
      'name': 'Basique',
      'duration_days': 30,
      'price': 5000.0, // 5000 FCFA
      'features': ['Accès complet', 'Tests illimités', 'Support standard'],
    },
    'premium': {
      'name': 'Premium',
      'duration_days': 90,
      'price': 12000.0, // 12000 FCFA
      'features': [
        'Accès complet',
        'Tests illimités',
        'Support premium',
        'Rapports détaillés'
      ],
    },
    'annual': {
      'name': 'Annuel',
      'duration_days': 365,
      'price': 35000.0, // 35000 FCFA
      'features': [
        'Accès complet',
        'Tests illimités',
        'Support premium',
        'Rapports détaillés',
        'Mises à jour gratuites'
      ],
    },
  };

  // Vérifier si l'app est activée (basé sur l'activation active)
  Future<bool> isAppActivated() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier d'abord si il y a une activation payante active
    final subscriptionType = prefs.getString(_subscriptionTypeKey);
    if (subscriptionType != null && subscriptionType != 'trial') {
      final expiryString = prefs.getString(_subscriptionExpiryKey);
      if (expiryString != null) {
        final expiryDate = DateTime.parse(expiryString);
        if (expiryDate.isAfter(DateTime.now())) {
          return true; // Activation payante active
        }
      }
    }

    // Vérifier si la période d'essai est encore active
    final trialStartString = prefs.getString(_trialStartKey);
    if (trialStartString != null) {
      final trialStart = DateTime.parse(trialStartString);
      final trialEnd = trialStart.add(const Duration(days: 7));
      final trialUsed = prefs.getBool(_trialUsedKey) ?? false;

      if (!trialUsed && trialEnd.isAfter(DateTime.now())) {
        return true; // Période d'essai active
      }
    }

    return false; // Aucune activation active
  }

  // Activer l'app (méthode de compatibilité - utilise l'essai par défaut)
  Future<void> activateApp() async {
    await activateAppWithSubscription('trial');
  }

  // Activer l'app avec un abonnement spécifique
  Future<void> activateAppWithSubscription(String subscriptionType,
      {String? transactionId}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setString(_subscriptionTypeKey, subscriptionType);

    if (subscriptionType == 'trial') {
      // Démarrer la période d'essai
      await prefs.setString(_trialStartKey, now.toIso8601String());
      await prefs.setBool(_trialUsedKey, false);
    } else {
      // Calculer la date d'expiration pour les activations payantes
      final plan = _subscriptionPlans[subscriptionType];
      if (plan != null) {
        final durationDays = plan['duration_days'] as int;
        final expiryDate = now.add(Duration(days: durationDays));
        await prefs.setString(
            _subscriptionExpiryKey, expiryDate.toIso8601String());

        // Enregistrer le paiement dans l'historique
        if (transactionId != null) {
          await _addPaymentToHistory(
              transactionId, subscriptionType, plan['price'] as double, now);
        }
      }
    }

    await prefs.setBool(_activationKey, true);
  }

  // Obtenir les informations d'activation actuelles
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final prefs = await SharedPreferences.getInstance();

    final subscriptionType = prefs.getString(_subscriptionTypeKey);
    if (subscriptionType == null) return null;

    final plan = _subscriptionPlans[subscriptionType];
    if (plan == null) return null;

    final expiryString = prefs.getString(_subscriptionExpiryKey);
    DateTime? expiryDate;
    if (expiryString != null) {
      expiryDate = DateTime.parse(expiryString);
    }

    final trialStartString = prefs.getString(_trialStartKey);
    DateTime? trialStart;
    if (trialStartString != null) {
      trialStart = DateTime.parse(trialStartString);
    }

    return {
      'type': subscriptionType,
      'name': plan['name'],
      'price': plan['price'],
      'features': plan['features'],
      'expiry_date': expiryDate,
      'trial_start': trialStart,
      'is_trial': subscriptionType == 'trial',
      'is_active': await isAppActivated(),
    };
  }

  // Vérifier si l'activation est expirée
  Future<bool> isSubscriptionExpired() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return true;

    final expiryDate = subscription['expiry_date'] as DateTime?;
    if (expiryDate == null) return false; // Activation illimitée (trial actif)

    return expiryDate.isBefore(DateTime.now());
  }

  // Renouveler l'activation
  Future<void> renewSubscription(String subscriptionType,
      {String? transactionId}) async {
    await activateAppWithSubscription(subscriptionType,
        transactionId: transactionId);
  }

  // Méthode supprimée - paiement unique uniquement

  // Calculer les jours restants pour l'activation actuelle
  Future<int> getRemainingDays() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return 0;

    final expiryDate = subscription['expiry_date'] as DateTime?;
    if (expiryDate == null) {
      // Pour l'essai, calculer les jours restants
      final trialStart = subscription['trial_start'] as DateTime?;
      if (trialStart != null) {
        final trialEnd = trialStart.add(const Duration(days: 7));
        final remaining = trialEnd.difference(DateTime.now()).inDays;
        return remaining > 0 ? remaining : 0;
      }
      return 0;
    }

    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Marquer la période d'essai comme utilisée
  Future<void> markTrialAsUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trialUsedKey, true);
  }

  // Vérifier si la période d'essai a été utilisée
  Future<bool> isTrialUsed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_trialUsedKey) ?? false;
  }

  // Ajouter un paiement à l'historique (simplifié - pas d'historique stocké)
  Future<void> _addPaymentToHistory(String transactionId,
      String subscriptionType, double amount, DateTime date) async {
    // Historique des paiements supprimé selon les nouvelles spécifications
    // L'app utilise maintenant un paiement unique sans suivi d'historique
  }

  // Marquer le premier examen comme terminé
  Future<void> markFirstExamCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstExamCompletedKey, true);
  }

  // Vérifier si le premier examen est terminé
  Future<bool> isFirstExamCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstExamCompletedKey) ?? false;
  }

  // Marquer la popup d'activation comme affichée
  Future<void> markActivationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_activationPromptShownKey, true);
  }

  // Vérifier si la popup d'activation a été affichée
  Future<bool> isActivationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activationPromptShownKey) ?? false;
  }

  // Réinitialiser l'état (pour les tests)
  Future<void> resetActivation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activationKey);
    await prefs.remove(_subscriptionTypeKey);
    await prefs.remove(_subscriptionExpiryKey);
    await prefs.remove(_paymentHistoryKey);
    await prefs.remove(_firstExamCompletedKey);
    await prefs.remove(_activationPromptShownKey);
    await prefs.remove(_trialStartKey);
    await prefs.remove(_trialUsedKey);
  }

  // Vérifier si on doit afficher la popup d'activation
  Future<bool> shouldShowActivationPrompt() async {
    final isActivated = await isAppActivated();
    if (isActivated) return false;

    final isPromptShown = await isActivationPromptShown();
    return !isPromptShown;
  }

  // Vérifier si l'utilisateur peut accéder à une fonctionnalité premium
  Future<bool> canAccessPremiumFeature() async {
    final subscription = await getCurrentSubscription();
    if (subscription == null) return false;

    final type = subscription['type'] as String;
    return type == 'premium' || type == 'annual';
  }

  // Obtenir le statut détaillé de l'activation
  Future<Map<String, dynamic>> getActivationStatus() async {
    final isActivated = await isAppActivated();
    final subscription = await getCurrentSubscription();
    final remainingDays = await getRemainingDays();
    final isExpired = await isSubscriptionExpired();

    return {
      'is_activated': isActivated,
      'subscription': subscription,
      'remaining_days': remainingDays,
      'is_expired': isExpired,
      'can_access_premium': await canAccessPremiumFeature(),
    };
  }
}
