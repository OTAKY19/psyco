import 'dart:math';
import 'package:flutter/material.dart'; // Importation ajoutée pour Color

// Définition des modèles nécessaires (à adapter si déjà existants)
class MobileMoneyProvider {
  final String name;
  final String code;
  final String logo;
  final List<String> prefixes;
  final String ussdCode;
  final Color color;

  MobileMoneyProvider({
    required this.name,
    required this.code,
    required this.logo,
    required this.prefixes,
    required this.ussdCode,
    required this.color,
  });
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? ussdCode;
  final int? amount;
  final String? provider;
  final String? errorMessage;

  PaymentResult.success({
    required this.transactionId,
    required this.ussdCode,
    required this.amount,
    required this.provider,
  })  : success = true,
        errorMessage = null;

  PaymentResult.error(this.errorMessage)
      : success = false,
        transactionId = null,
        ussdCode = null,
        amount = null,
        provider = null;
}

enum PaymentStatus { success, pending, failed }

class PremiumLicense {
  final String id;
  final String transactionId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final Map<String, bool> features;
  final LicenseType type;

  PremiumLicense({
    required this.id,
    required this.transactionId,
    required this.issuedAt,
    required this.expiresAt,
    required this.features,
    required this.type,
  });

  bool isValid() {
    return DateTime.now().isBefore(expiresAt);
  }
}

enum LicenseType { LIFETIME, SUBSCRIPTION }

class LicenseService {
  static Future<PremiumLicense?> getStoredLicense() async {
    // Simulation de récupération de licence
    await Future.delayed(Duration(milliseconds: 500));
    // Retourne null pour simuler l'absence de licence au début
    return null;
  }

  static Future<void> installLicense(PremiumLicense license) async {
    // Simulation d'installation de licence
    print("Licence installée: ${license.id}");
    await Future.delayed(Duration(milliseconds: 500));
  }

  static String generateLicenseId() {
    return 'LICENSE_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}

class PremiumOffer {
  final String id;
  final String name;
  final String description;
  final int price;
  final String currency;
  final Map<String, bool> features;
  final List<String> benefits;

  PremiumOffer({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.features,
    required this.benefits,
  });
}

class PsychoTestOffer {
  static const String FULL_ACCESS_ID = "psychotest_full_access";
  static const int PRICE_FCFA = 1500; // 1500 FCFA ≈ 2,3€

  static PremiumOffer get fullAccess => PremiumOffer(
    id: FULL_ACCESS_ID,
    name: "PsychoTest+ Complet",
    description: "Accès à vie à toutes les fonctionnalités",
    price: PRICE_FCFA,
    currency: "FCFA",
    features: {
      "unlimited_tests": true,
      "full_results": true,
      "detailed_statistics": true,
      "offline_access": true,
      "all_categories": true,
      "lifetime_access": true, // ← Clé : accès à vie
    },
    benefits: [
      "✅ Tests illimités",
      "✅ Résultats complets (40 questions)",
      "✅ Statistiques détaillées",
      "✅ Accès hors-ligne",
      "✅ Toutes catégories débloquées",
      "✅ Accès à vie (pas d'abonnement)",
    ]
  );
}

// SPÉCIFICATIONS BÉNIN
final Map<String, MobileMoneyProvider> beninProviders = {
  'mtn': MobileMoneyProvider(
    name: 'MTN Mobile Money',
    code: 'MTN_MOMO',
    logo: 'assets/images/mtn_logo.png',
    prefixes: ['90', '91', '96', '97'], // Préfixes MTN Bénin
    ussdCode: '*133*1*{amount}#',
    color: Color(0xFFFFC107),
  ),
  'moov': MobileMoneyProvider(
    name: 'Moov Money',
    code: 'MOOV_MONEY',
    logo: 'assets/images/moov_logo.png',
    prefixes: ['94', '95', '98', '99'], // Préfixes Moov Bénin
    ussdCode: '*555*1*{amount}#',
    color: Color(0xFF00BFFF),
  )
};

// Validation numéro béninois
bool isValidBeninNumber(String phone, String provider) {
  final clean = phone.replaceAll(RegExp(r'[^\d]'), '');

  if (clean.length != 8) return false;

  final providerData = beninProviders[provider];
  return providerData?.prefixes.any((prefix) => clean.startsWith(prefix)) ?? false;
}

class OneTimePurchaseService {
  static const int FULL_ACCESS_PRICE = 1500; // FCFA

  Future<PaymentResult> purchaseFullAccess(String provider, String phoneNumber) async {
    try {
      // 1. Validation du numéro selon l'opérateur
      if (!isValidBeninNumber(phoneNumber, provider)) {
        return PaymentResult.error("Numéro invalide pour $provider");
      }

      // 2. Générer transaction unique
      final transactionId = _generateTransactionId();

      // 3. Générer code USSD approprié
      final ussdCode = _generateUssdCode(provider, FULL_ACCESS_PRICE);

      // 4. Sauvegarder transaction en attente
      await _saveTransaction(transactionId, phoneNumber, provider);

      return PaymentResult.success(
        transactionId: transactionId,
        ussdCode: ussdCode,
        amount: FULL_ACCESS_PRICE,
        provider: provider,
      );

    } catch (e) {
      return PaymentResult.error("Erreur: $e");
    }
  }

  String _generateUssdCode(String provider, int amount) {
    switch (provider) {
      case 'mtn':
        return "*133*1*$amount#";
      case 'moov':
        return "*555*1*$amount#";
      default:
        return "*#";
    }
  }

  // Vérification statut paiement (simulation)
  Future<PaymentStatus> checkPaymentStatus(String transactionId) async {
    // Simulation - en production, vérifier avec l'API de l'agrégateur
    await Future.delayed(Duration(seconds: 2));

    // Random success pour demo (remplacer par vraie API)
    final success = Random().nextBool();

    if (success) {
      // Générer licence d'accès à vie
      await _generateLifetimeLicense(transactionId);
      return PaymentStatus.success;
    } else {
      return PaymentStatus.pending;
    }
  }

  Future<void> _generateLifetimeLicense(String transactionId) async {
    final license = PremiumLicense(
      id: LicenseService.generateLicenseId(),
      transactionId: transactionId,
      issuedAt: DateTime.now(),
      expiresAt: DateTime(2050, 1, 1), // Expire en 2050 = "à vie"
      features: PsychoTestOffer.fullAccess.features,
      type: LicenseType.LIFETIME,
    );

    await LicenseService.installLicense(license);
  }

  String _generateTransactionId() {
    return 'TXN_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<void> _saveTransaction(String transactionId, String phoneNumber, String provider) async {
    // Simulation de sauvegarde de transaction
    print("Transaction sauvegardée: $transactionId pour $phoneNumber via $provider");
    await Future.delayed(Duration(milliseconds: 500));
  }

  Future<bool> hasLifetimeAccess() async {
    // Vérification accès à vie
    final license = await LicenseService.getStoredLicense();
    return license != null && license.isValid();
  }
}
