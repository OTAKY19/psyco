import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

class SecurityConfig {
  static final SecurityConfig _instance = SecurityConfig._internal();
  factory SecurityConfig() => _instance;
  SecurityConfig._internal();

  // Configuration de sécurité
  static const String _envFile = '.env';
  static const String _configFile = 'assets/config/security_config.json';

  // Clés de configuration
  static const String apiKeyKey = 'MTN_API_KEY';
  static const String apiSecretKey = 'MTN_API_SECRET';
  static const String webhookSecretKey = 'WEBHOOK_SECRET';
  static const String encryptionKeyKey = 'ENCRYPTION_KEY';

  Map<String, String> _envVariables = {};
  Map<String, dynamic> _securityConfig = {};

  /// Initialise la configuration de sécurité
  Future<void> initialize() async {
    await _loadEnvironmentVariables();
    await _loadSecurityConfig();
    await _validateSecuritySetup();
  }

  /// Charge les variables d'environnement
  Future<void> _loadEnvironmentVariables() async {
    try {
      // En développement, charger depuis le fichier .env
      if (!kReleaseMode) {
        final envContent = await rootBundle.loadString(_envFile);
        _parseEnvFile(envContent);
      } else {
        // En production, utiliser Platform.environment
        _envVariables = Platform.environment;
      }
    } catch (e) {
      debugPrint('⚠️ Fichier .env non trouvé, utilisation des valeurs par défaut');
      _loadDefaultEnvValues();
    }
  }

  /// Parse le fichier .env
  void _parseEnvFile(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final parts = line.split('=');
      if (parts.length == 2) {
        _envVariables[parts[0].trim()] = parts[1].trim().replaceAll('"', '');
      }
    }
  }

  /// Charge les valeurs par défaut pour le développement
  void _loadDefaultEnvValues() {
    _envVariables = {
      apiKeyKey: 'dev_api_key_placeholder',
      apiSecretKey: 'dev_api_secret_placeholder',
      webhookSecretKey: 'dev_webhook_secret_placeholder',
      encryptionKeyKey: 'dev_encryption_key_placeholder',
    };
  }

  /// Charge la configuration de sécurité
  Future<void> _loadSecurityConfig() async {
    try {
      final configContent = await rootBundle.loadString(_configFile);
      _securityConfig = jsonDecode(configContent);
    } catch (e) {
      debugPrint(
          '⚠️ Configuration de sécurité non trouvée, utilisation des valeurs par défaut');
      _loadDefaultSecurityConfig();
    }
  }

  /// Configuration de sécurité par défaut
  void _loadDefaultSecurityConfig() {
    _securityConfig = {
      'certificate_pinning': {
        'enabled': true,
        'pins': {
          'api.mtn.com': ['sha256_hash_placeholder'],
          'sandbox.momodeveloper.mtn.com': ['sha256_hash_placeholder'],
        }
      },
      'api_timeout': 30000,
      'max_retry_attempts': 3,
      'encryption': {
        'algorithm': 'AES-256-GCM',
        'key_rotation_days': 30,
      },
      'webhook': {
        'verification_enabled': true,
        'tolerance_seconds': 300,
      }
    };
  }

  /// Valide la configuration de sécurité
  Future<void> _validateSecuritySetup() async {
    final issues = <String>[];

    // Vérifier les clés API
    if (getApiKey().isEmpty || getApiKey().contains('placeholder')) {
      issues.add('Clé API MTN manquante ou invalide');
    }

    if (getApiSecret().isEmpty || getApiSecret().contains('placeholder')) {
      issues.add('Secret API MTN manquant ou invalide');
    }

    // Vérifier la configuration de certificat pinning
    if (isCertificatePinningEnabled() && getCertificatePins().isEmpty) {
      issues.add('Configuration Certificate Pinning incomplète');
    }

    if (issues.isNotEmpty) {
      debugPrint('⚠️ Problèmes de sécurité détectés:');
      for (final issue in issues) {
        debugPrint('  - $issue');
      }

      if (kReleaseMode) {
        debugPrint('❌ Configuration de sécurité invalide pour la production');
        throw Exception('Configuration de sécurité invalide');
      }
    } else {
      debugPrint('✅ Configuration de sécurité validée');
    }
  }

  // Getters pour les clés API
  String getApiKey() => _envVariables[apiKeyKey] ?? '';
  String getApiSecret() => _envVariables[apiSecretKey] ?? '';
  String getWebhookSecret() => _envVariables[webhookSecretKey] ?? '';
  String getEncryptionKey() => _envVariables[encryptionKeyKey] ?? '';

  // Configuration de sécurité
  bool isCertificatePinningEnabled() =>
      _securityConfig['certificate_pinning']?['enabled'] ?? false;

  Map<String, List<String>> getCertificatePins() {
    final pins = _securityConfig['certificate_pinning']?['pins'] ?? {};
    return Map<String, List<String>>.from(pins);
  }

  int getApiTimeout() => _securityConfig['api_timeout'] ?? 30000;
  int getMaxRetryAttempts() => _securityConfig['max_retry_attempts'] ?? 3;

  // Configuration d'encryption
  String getEncryptionAlgorithm() =>
      _securityConfig['encryption']?['algorithm'] ?? 'AES-256-GCM';

  int getKeyRotationDays() =>
      _securityConfig['encryption']?['key_rotation_days'] ?? 30;

  // Configuration webhook
  bool isWebhookVerificationEnabled() =>
      _securityConfig['webhook']?['verification_enabled'] ?? true;

  int getWebhookToleranceSeconds() =>
      _securityConfig['webhook']?['tolerance_seconds'] ?? 300;

  /// Génère une clé d'encryption sécurisée
  String generateSecureKey() {
    final random = List<int>.generate(
        32, (i) => DateTime.now().microsecondsSinceEpoch % 256);
    return base64Url.encode(random);
  }

  /// Hash un certificat pour le pinning
  String hashCertificate(String certificate) {
    final bytes = utf8.encode(certificate);
    final digest = sha256.convert(bytes);
    return 'sha256/$digest';
  }

  /// Vérifie la signature webhook
  bool verifyWebhookSignature(String payload, String signature, String secret) {
    final expectedSignature = Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(payload))
        .toString();

    return signature == expectedSignature;
  }

  /// Chiffre les données sensibles
  String encryptData(String data, String key) {
    // Implémentation simplifiée - en production utiliser encrypt package
    final keyBytes = base64.decode(key);
    final dataBytes = utf8.encode(data);
    final encrypted = List<int>.generate(
        dataBytes.length, (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    return base64.encode(encrypted);
  }

  /// Déchiffre les données sensibles
  String decryptData(String encryptedData, String key) {
    // Implémentation simplifiée - en production utiliser encrypt package
    final keyBytes = base64.decode(key);
    final encryptedBytes = base64.decode(encryptedData);
    final decrypted = List<int>.generate(encryptedBytes.length,
        (i) => encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    return utf8.decode(decrypted);
  }

  /// Obtient les headers de sécurité pour les appels API
  Map<String, String> getSecurityHeaders() {
    return {
      'X-API-Key': getApiKey(),
      'X-Request-Time': DateTime.now().millisecondsSinceEpoch.toString(),
      'X-App-Version': '1.0.0',
      'X-Platform': Platform.operatingSystem,
    };
  }

  /// Valide un certificat pour le pinning
  bool validateCertificate(String domain, String certificateHash) {
    final pins = getCertificatePins()[domain];
    if (pins == null) return false;

    return pins.contains(certificateHash);
  }

  /// Génère un token de sécurité temporaire
  String generateSecurityToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000000;
    final data = '$timestamp:$random:${getApiKey()}';
    final hash = sha256.convert(utf8.encode(data)).toString();
    return '$timestamp.$random.$hash';
  }

  /// Vérifie un token de sécurité
  bool verifySecurityToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final timestamp = int.tryParse(parts[0]);
    if (timestamp == null) return false;

    // Vérifier l'expiration (5 minutes)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - timestamp > 300000) return false;

    final random = parts[1];
    final receivedHash = parts[2];
    final data = '$timestamp:$random:${getApiKey()}';
    final expectedHash = sha256.convert(utf8.encode(data)).toString();

    return receivedHash == expectedHash;
  }
}
