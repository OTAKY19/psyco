import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'license_service.dart';
import '../services/subscription_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _licenseService = LicenseService();
  static const String _lastSyncKey = 'last_full_sync';

  /// Synchronise toutes les données avec le serveur
  Future<bool> performFullSync() async {
    try {
      debugPrint('🔄 Démarrage synchronisation complète...');

      // 1. Vérifier la licence
      final licenseValid = await _licenseService.syncLicense();

      // 2. Synchroniser les données utilisateur
      final userSyncSuccess = await _syncUserData();

      // 3. Synchroniser les abonnements
      final subscriptionSyncSuccess = await _syncSubscriptions();

      // 4. Mettre à jour les timestamps
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      final success =
          licenseValid && userSyncSuccess && subscriptionSyncSuccess;

      debugPrint(success
          ? '✅ Synchronisation réussie'
          : '❌ Erreurs lors de la synchronisation');
      return success;
    } catch (e) {
      debugPrint('❌ Erreur synchronisation: $e');
      return false;
    }
  }

  /// Synchronise les données utilisateur
  Future<bool> _syncUserData() async {
    try {
      // Simulation de synchronisation des progrès, scores, etc.
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('❌ Erreur sync utilisateur: $e');
      return false;
    }
  }

  /// Synchronise les données d'abonnement
  Future<bool> _syncSubscriptions() async {
    try {
      final licenseInfo = await _licenseService.getLicenseInfo();
      if (licenseInfo == null) return false;

      final subscriptionService = SubscriptionService();

      // Mettre à jour l'abonnement local selon la licence
      await subscriptionService.setSubscriptionType(
        licenseInfo['subscriptionType'] ?? 'premium',
        expiryDate: licenseInfo['expiryDate'],
      );

      return true;
    } catch (e) {
      debugPrint('❌ Erreur sync abonnements: $e');
      return false;
    }
  }

  /// Vérifie si une synchronisation est nécessaire
  Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    if (lastSyncString == null) return true;

    final lastSync = DateTime.parse(lastSyncString);
    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;

    return hoursSinceSync >= 24; // Sync quotidienne
  }

  /// Synchronise uniquement les données critiques
  Future<bool> performCriticalSync() async {
    try {
      debugPrint('🔄 Synchronisation critique...');

      // Vérifier uniquement la licence et les abonnements
      final licenseValid = await _licenseService.syncLicense();
      final subscriptionSyncSuccess = await _syncSubscriptions();

      return licenseValid && subscriptionSyncSuccess;
    } catch (e) {
      debugPrint('❌ Erreur sync critique: $e');
      return false;
    }
  }

  /// Obtient le statut de synchronisation
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    final needsSync = await this.needsSync();

    return {
      'lastSync':
          lastSyncString != null ? DateTime.parse(lastSyncString) : null,
      'needsSync': needsSync,
      'hoursSinceLastSync': lastSyncString != null
          ? DateTime.now().difference(DateTime.parse(lastSyncString)).inHours
          : null,
    };
  }

  /// Force une synchronisation immédiate
  Future<bool> forceSync() async {
    try {
      debugPrint('🔄 Synchronisation forcée...');
      return await performFullSync();
    } catch (e) {
      debugPrint('❌ Erreur sync forcée: $e');
      return false;
    }
  }
}
