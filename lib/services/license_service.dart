import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class LicenseService {
  static final LicenseService _instance = LicenseService._internal();
  factory LicenseService() => _instance;
  LicenseService._internal();

  static const String _licenseKey = 'user_license';
  static const String _deviceIdKey = 'device_id';

  /// Vérifie si l'utilisateur a une licence active
  Future<bool> hasActiveLicense() async {
    final licenseInfo = await getLicenseInfo();
    if (licenseInfo == null) return false;

    final expiryDate = licenseInfo['expiryDate'] as DateTime?;
    if (expiryDate == null) return false;

    return expiryDate.isAfter(DateTime.now());
  }

  /// Obtient les informations de la licence
  Future<Map<String, dynamic>?> getLicenseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final licenseString = prefs.getString(_licenseKey);

    if (licenseString == null) return null;

    try {
      final licenseData = jsonDecode(licenseString);

      // Vérifier la validité de la licence
      final isValid = await _validateLicense(licenseData);
      if (!isValid) return null;

      return {
        'subscriptionType': licenseData['subscription_type'] ?? 'premium',
        'expiryDate': DateTime.parse(licenseData['exp'] ?? ''),
        'deviceId': licenseData['device_id'],
        'userId': licenseData['sub'],
        'isValid': true,
      };
    } catch (e) {
      debugPrint('❌ Erreur décodage licence: $e');
      return null;
    }
  }

  /// Stocke une nouvelle licence
  Future<bool> storeLicense(String licenseToken) async {
    try {
      final licenseData = _decodeLicenseToken(licenseToken);
      if (licenseData == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_licenseKey, jsonEncode(licenseData));

      return true;
    } catch (e) {
      debugPrint('❌ Erreur stockage licence: $e');
      return false;
    }
  }

  /// Synchronise la licence avec le serveur
  Future<bool> syncLicense() async {
    try {
      // Simulation de synchronisation avec le serveur
      await Future.delayed(const Duration(seconds: 1));

      final licenseInfo = await getLicenseInfo();
      if (licenseInfo == null) return false;

      // Ici vous feriez un appel API pour synchroniser
      // await _syncWithServer(licenseInfo);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur sync licence: $e');
      return false;
    }
  }

  /// Supprime la licence actuelle
  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseKey);
  }

  /// Valide une licence
  Future<bool> _validateLicense(Map<String, dynamic> licenseData) async {
    try {
      // Vérifier la date d'expiration
      final expiryString = licenseData['exp'];
      if (expiryString == null) return false;

      final expiryDate = DateTime.parse(expiryString);
      if (expiryDate.isBefore(DateTime.now())) return false;

      // Vérifier l'ID de l'appareil
      final deviceId = licenseData['device_id'];
      if (deviceId == null) return false;

      final currentDeviceId = await _getDeviceId();
      if (deviceId != currentDeviceId) return false;

      // Vérifier la signature (simulation)
      final signature = licenseData['signature'];
      if (signature == null) return false;

      return _verifySignature(licenseData, signature);
    } catch (e) {
      debugPrint('❌ Erreur validation licence: $e');
      return false;
    }
  }

  /// Décode un token de licence JWT
  Map<String, dynamic>? _decodeLicenseToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final payloadBytes = base64Url.decode(normalizedPayload);
      final payloadString = utf8.decode(payloadBytes);

      return jsonDecode(payloadString);
    } catch (e) {
      debugPrint('❌ Erreur décodage token: $e');
      return null;
    }
  }

  /// Obtient l'ID de l'appareil
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Générer un nouvel ID d'appareil
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Génère un ID d'appareil unique
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'DEV_${timestamp}_$random';
  }

  /// Vérifie la signature de la licence
  bool _verifySignature(Map<String, dynamic> data, String signature) {
    try {
      // Simulation de vérification de signature
      // En production, utilisez une vraie vérification cryptographique
      final dataString = jsonEncode(data);
      final expectedSignature =
          sha256.convert(utf8.encode(dataString)).toString();

      return signature == expectedSignature.substring(0, 32);
    } catch (e) {
      return false;
    }
  }

  /// Obtient le statut détaillé de la licence
  Future<Map<String, dynamic>> getLicenseStatus() async {
    final hasLicense = await hasActiveLicense();
    final licenseInfo = await getLicenseInfo();

    return {
      'hasLicense': hasLicense,
      'licenseInfo': licenseInfo,
      'isExpired': licenseInfo != null && !hasLicense,
      'daysRemaining': licenseInfo != null
          ? _calculateDaysRemaining(licenseInfo['expiryDate'])
          : 0,
    };
  }

  /// Calcule les jours restants
  int _calculateDaysRemaining(DateTime? expiryDate) {
    if (expiryDate == null) return 0;
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }
}
