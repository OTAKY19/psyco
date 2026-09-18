import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Importation ajoutée pour ChangeNotifier
import 'entitlement_service.dart';

class UserStateService extends ChangeNotifier {
  static const String _guestUserIdKey = 'guest_user_id';
  static const String _hasCompletedDemoKey = 'has_completed_demo';
  static const String _hasLifetimeAccessKey =
      'has_lifetime_access'; // Nouvelle clé
  static const String _demoScoreKey = 'demo_score';
  static const String _lastDemoDateKey = 'last_demo_date';
  static const String _visibleResultsCountKey = 'visible_results_count';
  static const String _demoStartTimeKey = 'demo_start_time';

  /// Identité invité persistée (T3). Aucun compte requis ; remplace 'current_user'.
  static Future<String> ensureGuestUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_guestUserIdKey);
    if (id == null || id.isEmpty) {
      id = 'guest_${DateTime.now().millisecondsSinceEpoch}'
          '_${math.Random().nextInt(9999).toString().padLeft(4, '0')}';
      await prefs.setString(_guestUserIdKey, id);
    }
    return id;
  }

  bool _hasLifetimeAccess = false; // État local pour l'accès à vie

  // Initialisation de l'état
  UserStateService() {
    _loadLifetimeAccessStatus();
  }

  Future<void> _loadLifetimeAccessStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasLifetimeAccess = prefs.getBool(_hasLifetimeAccessKey) ?? false;
    // Superset backfill (ET2) : toute autre source premium élève l'accès à vie.
    final entitlement = await EntitlementService().refresh();
    if (entitlement.hasLifetime != _hasLifetimeAccess) {
      _hasLifetimeAccess = entitlement.hasLifetime;
      notifyListeners();
    }
  }

  // État utilisateur simplifié
  Future<bool> hasCompletedDemo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedDemoKey) ?? false;
  }

  Future<void> markDemoCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedDemoKey, true);
    await prefs.setInt(_lastDemoDateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Remplacé isActivated par hasLifetimeAccess
  bool get hasLifetimeAccess => _hasLifetimeAccess;

  Future<void> setLifetimeAccess(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasLifetimeAccessKey, value);
    _hasLifetimeAccess = value;
    notifyListeners(); // Notifier les auditeurs du changement
  }

  // Méthodes de compatibilité pour les autres parties du code
  Future<bool> isActivated() async {
    return hasLifetimeAccess;
  }

  Future<void> activateApp() async {
    await setLifetimeAccess(true);
  }

  Future<int> getDemoScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_demoScoreKey) ?? 0;
  }

  Future<void> setDemoScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_demoScoreKey, score);
  }

  Future<DateTime?> getLastDemoDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastDemoDateKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<int> getVisibleResultsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_visibleResultsCountKey) ??
        10; // Par défaut 10 questions visibles
  }

  Future<void> setVisibleResultsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_visibleResultsCountKey, count);
  }

  Future<void> recordDemoStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _demoStartTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getDemoStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_demoStartTimeKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  // Logique des résultats progressifs
  Future<int> calculateVisibleResultsCount() async {
    final hasCompletedDemo = await this.hasCompletedDemo();
    final demoStartTime = await getDemoStartTime();

    if (!hasCompletedDemo) {
      return 10; // Toujours 10 questions visibles pendant la démo
    }

    if (hasLifetimeAccess) {
      // Utilise le nouvel état
      return 40; // Toutes les questions visibles si accès à vie
    }

    // Logique de révélation progressive
    if (demoStartTime != null) {
      final elapsedTime = DateTime.now().difference(demoStartTime);
      final secondsElapsed = elapsedTime.inSeconds;

      if (secondsElapsed >= 30) {
        return 20; // Questions 1-20 visibles après 30 secondes
      }
    }

    return 10; // Questions 1-10 visibles par défaut
  }

  // Vérifier si on peut révéler plus de résultats
  Future<bool> canRevealMoreResults() async {
    final currentVisible = await getVisibleResultsCount();
    final calculatedVisible = await calculateVisibleResultsCount();

    return calculatedVisible > currentVisible;
  }

  // Révéler plus de résultats
  Future<void> revealMoreResults() async {
    final calculatedVisible = await calculateVisibleResultsCount();
    await setVisibleResultsCount(calculatedVisible);
  }

  // Réinitialiser l'état utilisateur (pour les tests)
  Future<void> resetUserState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasCompletedDemoKey);
    await prefs.remove(_hasLifetimeAccessKey); // Supprimé _isActivatedKey
    await prefs.remove(_demoScoreKey);
    await prefs.remove(_lastDemoDateKey);
    await prefs.remove(_visibleResultsCountKey);
    await prefs.remove(_demoStartTimeKey);
    _hasLifetimeAccess = false; // Réinitialiser l'état local
    notifyListeners();
  }

  // Obtenir l'état complet de l'utilisateur
  Future<UserState> getUserState() async {
    return UserState(
      hasCompletedDemo: await hasCompletedDemo(),
      hasLifetimeAccess: hasLifetimeAccess, // Utilise le nouvel état
      demoScore: await getDemoScore(),
      lastDemoDate: await getLastDemoDate(),
      visibleResultsCount: await getVisibleResultsCount(),
      canRevealMore: await canRevealMoreResults(),
    );
  }
}

class UserState {
  final bool hasCompletedDemo;
  final bool hasLifetimeAccess; // Remplacé isActivated
  final int demoScore;
  final DateTime? lastDemoDate;
  final int visibleResultsCount;
  final bool canRevealMore;

  const UserState({
    required this.hasCompletedDemo,
    required this.hasLifetimeAccess, // Remplacé isActivated
    required this.demoScore,
    required this.lastDemoDate,
    required this.visibleResultsCount,
    required this.canRevealMore,
  });

  // Getter de compatibilité pour les autres parties du code
  bool get isActivated => hasLifetimeAccess;

  @override
  String toString() {
    return 'UserState(hasCompletedDemo: $hasCompletedDemo, hasLifetimeAccess: $hasLifetimeAccess, demoScore: $demoScore, visibleResultsCount: $visibleResultsCount, canRevealMore: $canRevealMore)';
  }
}
