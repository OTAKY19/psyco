import 'package:flutter/foundation.dart';

/// Configuration centralisée de toutes les APIs utilisées dans PsychoTest+
class ApiConfig {
  static const String _version = '1.0.0';

  // ===========================================
  // ENVIRONNEMENTS
  // ===========================================

  static bool get isDevelopment => kDebugMode;
  static bool get isProduction => !kDebugMode;
  static bool get isStaging => false; // Configure selon vos besoins

  // ===========================================
  // URLs DE BASE
  // ===========================================

  /// URL de base de votre API backend
  static String get baseUrl {
    if (isDevelopment) {
      return 'https://api-dev.psychotest-plus.com/v1';
    } else if (isStaging) {
      return 'https://api-staging.psychotest-plus.com/v1';
    } else {
      return 'https://api.psychotest-plus.com/v1';
    }
  }

  /// URL pour les webhooks de paiement
  static String get webhookUrl => '$baseUrl/webhooks';

  /// URL pour l'authentification
  static String get authUrl => '$baseUrl/auth';

  /// URL pour les analytics
  static String get analyticsUrl => '$baseUrl/analytics';

  // ===========================================
  // MTN MOBILE MONEY API
  // ===========================================

  static const String mtnSandboxUrl = 'https://sandbox.momodeveloper.mtn.com';
  static const String mtnProductionUrl = 'https://momodeveloper.mtn.com';

  static String get mtnBaseUrl =>
      isDevelopment ? mtnSandboxUrl : mtnProductionUrl;

  /// Endpoints MTN
  static String get mtnTokenUrl => '$mtnBaseUrl/collection/token/';
  static String get mtnPaymentUrl => '$mtnBaseUrl/collection/v1_0/requesttopay';
  static String get mtnPaymentStatusUrl =>
      '$mtnBaseUrl/collection/v1_0/requesttopay';
  static String get mtnAccountBalanceUrl =>
      '$mtnBaseUrl/collection/v1_0/account/balance';
  static String get mtnAccountStatusUrl =>
      '$mtnBaseUrl/collection/v1_0/accountholder';

  /// Clés API MTN (À configurer via variables d'environnement)
  static const String mtnSubscriptionKey = String.fromEnvironment(
    'MTN_SUBSCRIPTION_KEY',
    defaultValue: 'your_mtn_subscription_key_here',
  );

  static const String mtnApiUser = String.fromEnvironment(
    'MTN_API_USER',
    defaultValue: 'your_mtn_api_user_here',
  );

  static const String mtnApiKey = String.fromEnvironment(
    'MTN_API_KEY',
    defaultValue: 'your_mtn_api_key_here',
  );

  /// Configuration MTN spécifique au Bénin
  static const Map<String, dynamic> mtnBeninConfig = {
    'country_code': 'BJ',
    'currency': 'XOF', // Franc CFA
    'phone_prefixes': ['9', '6'], // Préfixes MTN Bénin
    'fixed_amount': 3000.0, // Montant fixe pour PsychoTest+
    'ussd_code': '*133*1*3000#', // Code USSD MTN fixe
  };

  // ===========================================
  // MOOV MONEY API
  // ===========================================

  static const String moovSandboxUrl = 'https://api-sandbox.moov-africa.com';
  static const String moovProductionUrl = 'https://api.moov-africa.com';

  static String get moovBaseUrl =>
      isDevelopment ? moovSandboxUrl : moovProductionUrl;

  /// Endpoints Moov
  static String get moovTokenUrl => '$moovBaseUrl/oauth/token';
  static String get moovPaymentUrl => '$moovBaseUrl/v1/payments';
  static String get moovPaymentStatusUrl => '$moovBaseUrl/v1/payments';
  static String get moovWalletUrl => '$moovBaseUrl/v1/wallets';

  /// Clés API Moov
  static const String moovClientId = String.fromEnvironment(
    'MOOV_CLIENT_ID',
    defaultValue: 'your_moov_client_id_here',
  );

  static const String moovClientSecret = String.fromEnvironment(
    'MOOV_CLIENT_SECRET',
    defaultValue: 'your_moov_client_secret_here',
  );

  static const String moovApiKey = String.fromEnvironment(
    'MOOV_API_KEY',
    defaultValue: 'your_moov_api_key_here',
  );

  /// Configuration Moov spécifique au Bénin
  static const Map<String, dynamic> moovBeninConfig = {
    'country_code': 'BJ',
    'currency': 'XOF',
    'phone_prefixes': ['5', '9'], // Préfixes Moov Bénin
    'fixed_amount': 3000.0, // Montant fixe pour PsychoTest+
    'ussd_code': '*155*1*3000#', // Code USSD Moov fixe
  };

  // ===========================================
  // FIREBASE CONFIGURATION
  // ===========================================

  /// Configuration Firebase
  static const Map<String, String> firebaseConfig = {
    // Android
    'android_api_key':
        String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: ''),
    'android_app_id':
        String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: ''),
    'android_messaging_sender_id': String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: ''),
    'android_project_id': String.fromEnvironment('FIREBASE_PROJECT_ID',
        defaultValue: 'psychotest-plus'),

    // iOS
    'ios_api_key':
        String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: ''),
    'ios_app_id':
        String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: ''),
    'ios_client_id':
        String.fromEnvironment('FIREBASE_IOS_CLIENT_ID', defaultValue: ''),

    // Web
    'web_api_key':
        String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: ''),
  };

  // ===========================================
  // TIMEOUTS ET RETRY
  // ===========================================

  /// Timeout pour les requêtes API (en secondes)
  static const int apiTimeout = 30;

  /// Timeout pour les paiements (en secondes)
  static const int paymentTimeout = 60;

  /// Nombre maximum de tentatives
  static const int maxRetryAttempts = 3;

  /// Délai entre les tentatives (en secondes)
  static const int retryDelay = 2;

  // ===========================================
  // HEADERS COMMUNS
  // ===========================================

  /// Headers par défaut pour toutes les requêtes
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent':
            'PsychoTest+/$_version (${isProduction ? 'production' : 'development'})',
        'X-App-Version': _version,
        'X-Platform': 'flutter',
        'X-Environment': isProduction ? 'production' : 'development',
      };

  /// Headers pour l'authentification
  static Map<String, String> authHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };

  /// Headers pour MTN
  static Map<String, String> get mtnHeaders => {
        ...defaultHeaders,
        'Ocp-Apim-Subscription-Key': mtnSubscriptionKey,
        'X-Reference-Id': generateRequestId(),
        'X-Target-Environment': isDevelopment ? 'sandbox' : 'live',
      };

  /// Headers pour Moov
  static Map<String, String> moovHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
        'X-API-Key': moovApiKey,
      };

  // ===========================================
  // SÉCURITÉ
  // ===========================================

  /// Clé secrète pour la signature des webhooks
  static const String webhookSecret = String.fromEnvironment(
    'WEBHOOK_SECRET',
    defaultValue: 'your_webhook_secret_here_change_in_production',
  );

  /// Clé de chiffrement pour les données sensibles
  static const String encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: 'your_32_character_encryption_key_here',
  );

  /// Salt pour le hashage
  static const String passwordSalt = String.fromEnvironment(
    'PASSWORD_SALT',
    defaultValue: 'your_password_salt_here',
  );

  // ===========================================
  // CONFIGURATION DU PRIX UNIQUE
  // ===========================================

  /// Prix unique pour l'accès complet (en FCFA)
  static const double premiumPrice = 3000.0;

  /// Pas d'abonnement - paiement unique seulement
  static const Map<String, double> pricing = {
    'full_access': 3000.0, // Accès complet à vie
  };

  /// Configuration des devises
  static const Map<String, dynamic> currencyConfig = {
    'default': 'XOF',
    'symbol': 'FCFA',
    'precision': 0, // Pas de décimales pour le FCFA
    'supported': ['XOF'], // Seulement FCFA pour le Bénin
  };

  // ===========================================
  // ANALYTICS ET MONITORING
  // ===========================================

  /// Configuration Google Analytics
  static const String googleAnalyticsId = String.fromEnvironment(
    'GA_MEASUREMENT_ID',
    defaultValue: 'G-XXXXXXXXXX',
  );

  /// Configuration pour les logs
  static Map<String, dynamic> get loggingConfig => {
        'level': isDevelopment ? 'debug' : 'info',
        'enable_crash_reporting': true,
        'enable_analytics': true,
        'log_api_requests': isDevelopment,
        'log_payments': false, // Pour la sécurité
      };

  // ===========================================
  // RATE LIMITING
  // ===========================================

  /// Limites de taux pour éviter le spam
  static const Map<String, int> rateLimits = {
    'payment_requests_per_minute': 5,
    'api_requests_per_minute': 60,
    'failed_login_attempts': 5,
    'verification_attempts_per_hour': 10,
  };

  // ===========================================
  // NOTIFICATIONS PUSH
  // ===========================================

  /// Configuration Firebase Cloud Messaging
  static const Map<String, String> fcmConfig = {
    'server_key': String.fromEnvironment('FCM_SERVER_KEY', defaultValue: ''),
    'topic_prefix': 'psychotest_plus_',
    'default_topic': 'general',
  };

  // ===========================================
  // MÉTHODES UTILITAIRES
  // ===========================================

  /// Génère un ID unique pour les requêtes
  static String generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'REQ_${timestamp}_$random';
  }

  /// Génère un ID de transaction
  static String generateTransactionId(String provider) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${provider.toUpperCase()}_${timestamp}_$random';
  }

  /// Valide une URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Obtient l'URL complète pour un endpoint
  static String getEndpointUrl(String endpoint) {
    if (endpoint.startsWith('/')) {
      return '$baseUrl$endpoint';
    } else {
      return '$baseUrl/$endpoint';
    }
  }

  /// Valide un numéro de téléphone selon l'opérateur
  static bool isValidPhoneNumber(String phoneNumber, String operator) {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanNumber.length != 8) return false;

    switch (operator.toLowerCase()) {
      case 'mtn':
        return mtnBeninConfig['phone_prefixes']
            .any((prefix) => cleanNumber.startsWith(prefix));
      case 'moov':
        return moovBeninConfig['phone_prefixes']
            .any((prefix) => cleanNumber.startsWith(prefix));
      default:
        return false;
    }
  }

  /// Obtient le montant fixe pour PsychoTest+
  static double getFixedAmount() => premiumPrice;

  /// Vérifie si un montant est valide (doit être exactement 3000 FCFA)
  static bool isValidAmount(double amount) => amount == premiumPrice;

  /// Formate un montant selon la devise
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(currencyConfig['precision'])} ${currencyConfig['symbol']}';
  }

  /// Obtient la configuration complète pour debugging
  static Map<String, dynamic> getDebugConfig() {
    if (isProduction) {
      return {'error': 'Debug config not available in production'};
    }

    return {
      'environment': isDevelopment ? 'development' : 'production',
      'version': _version,
      'base_url': baseUrl,
      'mtn_base_url': mtnBaseUrl,
      'moov_base_url': moovBaseUrl,
      'firebase_project': firebaseConfig['android_project_id'],
      'timeouts': {
        'api': apiTimeout,
        'payment': paymentTimeout,
      },
      'rate_limits': rateLimits,
      'pricing': pricing,
      'currency': currencyConfig,
    };
  }
}
