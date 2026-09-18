import 'package:shared_preferences/shared_preferences.dart';

/// Résultat agrégé de l'entitlement (droits d'accès premium).
class EntitlementStatus {
  final bool hasLifetime;
  final bool hasPremiumAccess;
  final bool hasActiveSubscription;
  final String subscriptionType;
  final DateTime? subscriptionExpiry;

  const EntitlementStatus({
    required this.hasLifetime,
    required this.hasPremiumAccess,
    required this.hasActiveSubscription,
    required this.subscriptionType,
    required this.subscriptionExpiry,
  });

  /// Un seul superset : toute source la plus large (accès à vie) gagne.
  bool get isPremium =>
      hasLifetime || hasPremiumAccess || hasActiveSubscription;

  @override
  String toString() =>
      'EntitlementStatus(isPremium: $isPremium, lifetime: $hasLifetime, '
      'premium: $hasPremiumAccess, subscription: $hasActiveSubscription '
      '($subscriptionType))';
}

/// Source unique de vérité premium (ET2) : lit tous les écrivains legacy
/// (`has_lifetime_access`, `has_premium_access`, `subscription_type`+expiry,
/// `activation_service` trial) et re-backfill le drapeau superset le plus
/// large (`has_lifetime_access`) — migration vers 1 seule lecture.
class EntitlementService {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  EntitlementService._internal();

  static const String lifetimeKey = 'has_lifetime_access';
  static const String premiumAccessKey = 'has_premium_access';
  static const String subscriptionTypeKey = 'subscription_type';
  static const String subscriptionExpiryKey = 'subscription_expiry';
  static const String activationKey = 'app_activated';
  static const String trialStartKey = 'trial_start';
  static const String trialUsedKey = 'trial_used';
  static const String paymentHistoryKey = 'payment_history';

  /// Lecture OR sur tous les écrivains legacy. N'écrit rien.
  Future<EntitlementStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final hasLifetime = prefs.getBool(lifetimeKey) ?? false;
    final hasPremiumAccess = prefs.getBool(premiumAccessKey) ?? false;

    final subscriptionType = prefs.getString(subscriptionTypeKey);
    DateTime? subscriptionExpiry;
    String? expiryString;
    if (subscriptionType != null) {
      expiryString = prefs.getString(subscriptionExpiryKey);
      if (expiryString != null) {
        subscriptionExpiry = DateTime.tryParse(expiryString);
      }
    }

    var hasActiveSubscription = false;
    if (subscriptionType != null &&
        subscriptionType != 'free' &&
        subscriptionType != 'trial') {
      hasActiveSubscription =
          subscriptionExpiry != null &&
          subscriptionExpiry.isAfter(DateTime.now());
    }

    // L'activation legacy (paiement "Accès à vie") est un écrivain terminal.
    if ((prefs.getBool(activationKey) ?? false) &&
        (subscriptionType == 'premium' || subscriptionType == 'annual')) {
      hasActiveSubscription = true;
    }

    // Période d'essai legacy (activation_service) encore valide.
    if ((prefs.getBool(activationKey) ?? false) &&
        subscriptionType == 'trial' &&
        !(prefs.getBool(trialUsedKey) ?? false)) {
      final trialStartString = prefs.getString(trialStartKey);
      if (trialStartString != null) {
        final trialStart = DateTime.tryParse(trialStartString);
        if (trialStart != null &&
            trialStart.add(const Duration(days: 7)).isAfter(DateTime.now())) {
          hasActiveSubscription = true;
        }
      }
    }

    return EntitlementStatus(
      hasLifetime: hasLifetime,
      hasPremiumAccess: hasPremiumAccess,
      hasActiveSubscription: hasActiveSubscription,
      subscriptionType: subscriptionType ?? 'free',
      subscriptionExpiry: subscriptionExpiry,
    );
  }

  /// Agrégation superset : 1 = premium si n'importe quelle source est vraie.
  Future<bool> isPremium() async {
    final status = await getStatus();
    return status.isPremium;
  }

  /// Lit le drapeau gate canonique (`has_lifetime_access`).
  Future<bool> hasLifetimeAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(lifetimeKey) ?? false;
  }

  /// Re-backfill superset : si une source indique premium, on élève
  /// `has_lifetime_access` (le plus large). Ne retire jamais un accès.
  Future<EntitlementStatus> backfill() async {
    final status = await getStatus();
    if (status.isPremium && !status.hasLifetime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(lifetimeKey, true);
      return EntitlementStatus(
        hasLifetime: true,
        hasPremiumAccess: status.hasPremiumAccess,
        hasActiveSubscription: status.hasActiveSubscription,
        subscriptionType: status.subscriptionType,
        subscriptionExpiry: status.subscriptionExpiry,
      );
    }
    return status;
  }

  /// Recalcul complet = lecture + backfill.
  Future<EntitlementStatus> refresh() async {
    await backfill();
    return getStatus();
  }
}