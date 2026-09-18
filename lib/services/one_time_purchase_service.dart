import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Service pour la gestion du paiement unique de 3000 FCFA
class OneTimePurchaseService {
  static final OneTimePurchaseService _instance =
      OneTimePurchaseService._internal();
  factory OneTimePurchaseService() => _instance;
  OneTimePurchaseService._internal();

  // Constantes pour PsychoTest+
  static const double fixedPrice = 3000.0; // Prix fixe en FCFA
  static const String premiumKey = 'has_premium_access';
  static const String purchaseDateKey = 'premium_purchase_date';
  static const String transactionIdKey = 'premium_transaction_id';

  /// Durée de validité d'une transaction en attente (vérification manuelle)
  static const Duration pendingTimeout = Duration(minutes: 30);

  // Cache du statut premium
  bool? _cachedPremiumStatus;

  // ===========================================
  // VÉRIFICATION DU STATUT PREMIUM
  // ===========================================

  /// Vérifie si l'utilisateur a l'accès premium
  Future<bool> hasPremiumAccess() async {
    if (_cachedPremiumStatus != null) {
      return _cachedPremiumStatus!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPremium = prefs.getBool(premiumKey) ?? false;

      _cachedPremiumStatus = hasPremium;
      return hasPremium;
    } catch (e) {
      debugPrint('❌ Erreur vérification premium: $e');
      return false;
    }
  }

  /// Obtient les informations d'achat premium
  Future<Map<String, dynamic>?> getPremiumInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPremium = prefs.getBool(premiumKey) ?? false;

      if (!hasPremium) return null;

      final purchaseDateStr = prefs.getString(purchaseDateKey);
      final transactionId = prefs.getString(transactionIdKey);

      return {
        'has_premium': true,
        'purchase_date':
            purchaseDateStr != null ? DateTime.parse(purchaseDateStr) : null,
        'transaction_id': transactionId,
        'price_paid': fixedPrice,
        'access_type': 'lifetime',
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération info premium: $e');
      return null;
    }
  }

  // ===========================================
  // INITIATION DU PAIEMENT
  // ===========================================

  /// Initie le processus de paiement pour l'accès premium
  Future<Map<String, dynamic>> initiatePurchase({
    required String provider,
    required String phoneNumber,
  }) async {
    try {
      // Vérifier si déjà premium
      if (await hasPremiumAccess()) {
        return {
          'success': false,
          'error': 'Vous avez déjà accès à la version premium',
          'error_code': 'ALREADY_PREMIUM',
        };
      }

      // Valider le fournisseur
      if (!['mtn', 'moov'].contains(provider.toLowerCase())) {
        return {
          'success': false,
          'error': 'Fournisseur non supporté: $provider',
          'error_code': 'INVALID_PROVIDER',
        };
      }

      // Valider le numéro de téléphone
      final validation = _validatePhoneNumber(phoneNumber, provider);
      if (!validation['valid']) {
        return {
          'success': false,
          'error': validation['error'],
          'error_code': 'INVALID_PHONE',
        };
      }

      // Générer l'ID de transaction
      final transactionId = _generateTransactionId();

      // Générer le code USSD
      final ussdCode = _generateUssdCode(provider);

      // Sauvegarder la transaction en attente
      await _savePendingTransaction(transactionId, phoneNumber, provider);

      return {
        'success': true,
        'transaction_id': transactionId,
        'amount': fixedPrice,
        'currency': 'FCFA',
        'provider': provider,
        'phone_number': phoneNumber,
        'ussd_code': ussdCode,
        'instructions': _getPaymentInstructions(provider, ussdCode),
        'message':
            'Composez $ussdCode sur votre téléphone pour effectuer le paiement',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de l\'initiation du paiement: $e',
        'error_code': 'PAYMENT_ERROR',
      };
    }
  }

  // ===========================================
  // CONFIRMATION DU PAIEMENT
  // ===========================================

  /// Confirme et active l'accès premium après paiement réussi
  Future<Map<String, dynamic>> confirmPayment(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('pending_expired') ?? false) {
        await prefs.remove('pending_expired');
        return {
          'success': false,
          'error': 'La transaction a expiré. Veuillez recommencer le paiement.',
          'error_code': 'PAYMENT_EXPIRED',
          'retry_suggested': true,
        };
      }
      // Vérification manuelle : attestation de l'utilisateur (pas d'API opérateur)
      final paymentVerified = await _verifyPaymentWithProvider(transactionId);

      if (paymentVerified) {
        // Activer l'accès premium
        await _activatePremiumAccess(transactionId);

        return {
          'success': true,
          'message': 'Paiement confirmé ! Accès premium activé.',
          'transaction_id': transactionId,
          'activated_at': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'success': false,
          'error': 'Le paiement n\'a pas encore été reçu',
          'error_code': 'PAYMENT_NOT_CONFIRMED',
          'retry_suggested': true,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors de la confirmation: $e',
        'error_code': 'CONFIRMATION_ERROR',
      };
    }
  }

  /// Active manuellement l'accès premium (pour tests ou support client)
  Future<void> activatePremiumManually({String? transactionId}) async {
    final txnId =
        transactionId ?? 'MANUAL_${DateTime.now().millisecondsSinceEpoch}';
    await _activatePremiumAccess(txnId);
    debugPrint('✅ Accès premium activé manuellement: $txnId');
  }

  // ===========================================
  // MÉTHODES PRIVÉES
  // ===========================================

  /// Valide un numéro de téléphone selon le fournisseur
  Map<String, dynamic> _validatePhoneNumber(
      String phoneNumber, String provider) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Vérifier la longueur
    if (cleanNumber.length != 8) {
      return {
        'valid': false,
        'error': 'Le numéro doit contenir exactement 8 chiffres',
      };
    }

    // Vérifier les préfixes selon le fournisseur
    switch (provider.toLowerCase()) {
      case 'mtn':
        final mtnPrefixes =
            ApiConfig.mtnBeninConfig['phone_prefixes'] as List<String>;
        final isValidMtn =
            mtnPrefixes.any((prefix) => cleanNumber.startsWith(prefix));
        if (!isValidMtn) {
          return {
            'valid': false,
            'error':
                'Numéro MTN invalide. Doit commencer par ${mtnPrefixes.join(", ")}',
          };
        }
        break;

      case 'moov':
        final moovPrefixes =
            ApiConfig.moovBeninConfig['phone_prefixes'] as List<String>;
        final isValidMoov =
            moovPrefixes.any((prefix) => cleanNumber.startsWith(prefix));
        if (!isValidMoov) {
          return {
            'valid': false,
            'error':
                'Numéro Moov invalide. Doit commencer par ${moovPrefixes.join(", ")}',
          };
        }
        break;

      default:
        return {
          'valid': false,
          'error': 'Fournisseur non reconnu: $provider',
        };
    }

    return {'valid': true};
  }

  /// Génère un code USSD pour le paiement
  String _generateUssdCode(String provider) {
    switch (provider.toLowerCase()) {
      case 'mtn':
        return ApiConfig.mtnBeninConfig['ussd_code'] as String;
      case 'moov':
        return ApiConfig.moovBeninConfig['ussd_code'] as String;
      default:
        return '*#';
    }
  }

  /// Génère un ID de transaction unique
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'PSYCHO_${timestamp}_$random';
  }

  /// Sauvegarde une transaction en attente
  Future<void> _savePendingTransaction(
      String transactionId, String phoneNumber, String provider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionData = {
        'id': transactionId,
        'phone_number': phoneNumber,
        'provider': provider,
        'amount': fixedPrice,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      await prefs.setString(
          'pending_transaction', jsonEncode(transactionData));
      await prefs.remove('pending_expired');
      debugPrint('📝 Transaction sauvegardée: $transactionId');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde transaction: $e');
    }
  }

  /// Lit la transaction en attente (null si absente ou expirée).
  /// Une transaction expirée est nettoyée et flaggée pour message dédié.
  Future<Map<String, dynamic>?> getPendingTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pending_transaction');
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (isTransactionExpired(map['created_at'] as String?)) {
        await prefs.remove('pending_transaction');
        await prefs.setBool('pending_expired', true);
        return null;
      }
      return map;
    } catch (_) {
      await prefs.remove('pending_transaction');
      return null;
    }
  }

  /// L'utilisateur atteste avoir validé le paiement côté opérateur.
  /// Retourne faux si aucune transaction correspondante en attente.
  Future<bool> markUserAttested(String transactionId) async {
    final pending = await getPendingTransaction();
    if (pending == null || pending['id'] != transactionId) return false;
    pending['status'] = 'attested';
    pending['attested_at'] = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_transaction', jsonEncode(pending));
    return true;
  }

  /// Supprime toute transaction en attente (nouvelle tentative, annulation).
  Future<void> clearPendingTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_transaction');
    await prefs.remove('pending_expired');
  }

  /// Prédicat d'expiration, testable isolément.
  static bool isTransactionExpired(String? createdAtIso) {
    final createdAt = DateTime.tryParse(createdAtIso ?? '');
    if (createdAt == null) return true;
    return DateTime.now().difference(createdAt) > pendingTimeout;
  }

  /// Vérifie le paiement : attestation manuelle de l'utilisateur
  /// (pas d'API opérateur — vérification support en cas de litige).
  Future<bool> _verifyPaymentWithProvider(String transactionId) async {
    final pending = await getPendingTransaction();
    if (pending == null) return false;
    if (pending['id'] != transactionId) return false;
    return pending['status'] == 'attested';
  }

  /// Active l'accès premium
  Future<void> _activatePremiumAccess(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Marquer comme premium
      await prefs.setBool(premiumKey, true);
      await prefs.setString(
          purchaseDateKey, DateTime.now().toIso8601String());
      await prefs.setString(transactionIdKey, transactionId);

      // Nettoyer la transaction en attente
      await prefs.remove('pending_transaction');

      // Mettre à jour le cache
      _cachedPremiumStatus = true;

      debugPrint('🎉 Accès premium activé! Transaction: $transactionId');
    } catch (e) {
      debugPrint('❌ Erreur activation premium: $e');
      rethrow;
    }
  }

  /// Obtient les instructions de paiement
  List<String> _getPaymentInstructions(String provider, String ussdCode) {
    final providerName = provider.toUpperCase();

    return [
      '1. Composez $ussdCode sur votre téléphone $providerName',
      '2. Suivez les instructions à l\'écran',
      '3. Entrez votre code PIN $providerName pour confirmer',
      '4. Vous recevrez un SMS de confirmation',
      '5. Votre accès premium sera activé automatiquement',
    ];
  }

  // ===========================================
  // MÉTHODES UTILITAIRES PUBLIQUES
  // ===========================================

  /// Obtient les fournisseurs de paiement disponibles
  List<Map<String, dynamic>> getAvailableProviders() {
    return [
      {
        'id': 'mtn',
        'name': 'MTN Mobile Money',
        'logo': 'assets/images/mtn_logo.png',
        'color': '#FFC107',
        'prefixes': ApiConfig.mtnBeninConfig['phone_prefixes'],
        'ussd_code': ApiConfig.mtnBeninConfig['ussd_code'],
      },
      {
        'id': 'moov',
        'name': 'Moov Money',
        'logo': 'assets/images/moov_logo.png',
        'color': '#00A651',
        'prefixes': ApiConfig.moovBeninConfig['phone_prefixes'],
        'ussd_code': ApiConfig.moovBeninConfig['ussd_code'],
      },
    ];
  }

  /// Obtient le prix fixe formaté
  String getFormattedPrice() {
    return ApiConfig.formatAmount(fixedPrice);
  }

  /// Détecte automatiquement le fournisseur selon le numéro
  String? detectProviderFromPhone(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length != 8) return null;

    // Vérifier MTN
    final mtnPrefixes =
        ApiConfig.mtnBeninConfig['phone_prefixes'] as List<String>;
    if (mtnPrefixes.any((prefix) => cleanNumber.startsWith(prefix))) {
      return 'mtn';
    }

    // Vérifier Moov
    final moovPrefixes =
        ApiConfig.moovBeninConfig['phone_prefixes'] as List<String>;
    if (moovPrefixes.any((prefix) => cleanNumber.startsWith(prefix))) {
      return 'moov';
    }

    return null;
  }

  /// Formate un numéro de téléphone pour l'affichage
  String formatPhoneNumber(String phoneNumber) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length == 8) {
      return '${cleanNumber.substring(0, 2)} ${cleanNumber.substring(2, 4)} ${cleanNumber.substring(4, 6)} ${cleanNumber.substring(6, 8)}';
    }

    return phoneNumber;
  }

  /// Réinitialise le statut premium (pour tests ou debugging)
  Future<void> resetPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(premiumKey);
      await prefs.remove(purchaseDateKey);
      await prefs.remove(transactionIdKey);
      await prefs.remove('pending_transaction');

      _cachedPremiumStatus = null;
      debugPrint('🔄 Statut premium réinitialisé');
    } catch (e) {
      debugPrint('❌ Erreur réinitialisation: $e');
    }
  }

  /// Méthode de compatibilité pour l'ancien code
  Future<PaymentResult> purchaseFullAccess(
      String provider, String phoneNumber) async {
    final result = await initiatePurchase(
      provider: provider,
      phoneNumber: phoneNumber,
    );

    if (result['success']) {
      return PaymentResult(
        success: true,
        transactionId: result['transaction_id'],
        amount: result['amount'],
        ussdCode: result['ussd_code'],
        provider: result['provider'],
        phoneNumber: result['phone_number'],
        instructions: result['instructions'],
      );
    } else {
      return PaymentResult(
        success: false,
        errorMessage: result['error'],
        provider: provider,
        phoneNumber: phoneNumber,
      );
    }
  }

  /// Obtient les statistiques d'utilisation (pour debugging)
  Map<String, dynamic> getDebugInfo() {
    return {
      'service': 'OneTimePurchaseService',
      'fixed_price': fixedPrice,
      'currency': 'FCFA',
      'cached_premium_status': _cachedPremiumStatus,
      'supported_providers': ['mtn', 'moov'],
      'version': '1.0.0',
    };
  }
}

/// Classe pour représenter le résultat d'un paiement
class PaymentResult {
  final bool success;
  final String? transactionId;
  final double? amount;
  final String? ussdCode;
  final String? errorMessage;
  final String provider;
  final String phoneNumber;
  final List<String>? instructions;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.amount,
    this.ussdCode,
    this.errorMessage,
    required this.provider,
    required this.phoneNumber,
    this.instructions,
  });
}
