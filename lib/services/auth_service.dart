import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

/// Issue 4 : `signInAnonymously` est borné par un rate-limit serveur
/// (`_shared/rate_limit.ts`) et par ce client : on ne le déclenche qu'au
/// premier contact paywall, et on ne retente jamais automatiquement un 429.
class AuthResult {
  final bool success;
  final String? error;
  final bool rateLimited;
  final String? uid;
  final String? accessToken;
  final bool railConfigured;

  const AuthResult({
    this.success = false,
    this.error,
    this.rateLimited = false,
    this.uid,
    this.accessToken,
    this.railConfigured = true,
  });

  bool get isAnonymous => uid != null;

  @override
  String toString() => 'AuthResult(success: $success, rateLimited: '
      '$rateLimited, uid: $uid, railConfigured: $railConfigured)';
}

/// Auth anon Supabase (ET7) : `signInAnonymously` + persistance JWT.
///
/// Fail-open : si aucun projet Supabase n'est configuré au build
/// (--dart-define SUPABASE_URL / SUPABASE_ANON_KEY), le rail est désactivé
/// et l'app conserve son flux legacy local (API "AppConfig placeholder"),
/// sans jamais appeler le réseau.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String uidKey = 'supabase_anon_uid';

  SupabaseClient? _client;
  bool? _initFailed;
  String? _lastRateLimited;

  /// Rail Supabase actif uniquement si configuré au build.
  bool get isRailConfigured => ApiConfig.isSupabaseRailEnabled;

  /// Dernier message de rate-limit (429) observé, null sinon.
  String? get lastRateLimitedMessage => _lastRateLimited;

  /// ID anon persisté localement (même après redémarrage), null si jamais
  /// sign-in. N'est jamais rejoué côté réseau.
  Future<String?> getStoredAnonUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(uidKey);
  }

  /// Construit/stocker le client Supabase une seule fois.
  Future<SupabaseClient?> _getClient() async {
    if (_initFailed == true) return null;
    if (_client != null) return _client;

    if (!isRailConfigured) {
      _initFailed = true;
      return null;
    }

    try {
      if (Supabase.instance.isInitialized) {
        _client = Supabase.instance.client;
      } else {
        await Supabase.initialize(
          url: ApiConfig.supabaseUrl,
          publishableKey: ApiConfig.supabaseAnonKey,
        );
        _client = Supabase.instance.client;
      }
      return _client;
    } catch (e) {
      _initFailed = true;
      debugPrint('❌ [auth_service] Échec init Supabase (fail-open): $e');
      return null;
    }
  }

  /// Sign-in anon au premier contact paywall. Idempotent : si une session
  /// anon est déjà persistée (JWT valide), on la réutilise — zéro nouveau
  /// appel réseau. Un 429 est resservi tel quel, jamais retenté ici.
  Future<AuthResult> ensureAnonSession() async {
    _lastRateLimited = null;
    if (!isRailConfigured) {
      return const AuthResult(railConfigured: false);
    }

    final client = await _getClient();
    if (client == null) {
      return const AuthResult(
        railConfigured: false,
        error: 'Rail Supabase indisponible (fallback local).',
      );
    }

    // Session persistée (SharedPreferences, gérée par supabase_flutter).
    final existing = client.auth.currentSession;
    final uid = existing?.user.id;
    if (existing != null && uid != null) {
      await _stashUid(uid);
      return AuthResult(
        success: true,
        uid: uid,
        accessToken: existing.accessToken,
      );
    }

    try {
      final response = await client.auth.signInAnonymously();
      final session = response.session;
      final newUid = session?.user.id ?? response.user?.id;
      if (newUid == null) {
        return const AuthResult(error: 'Session anon sans identifiant.');
      }
      await _stashUid(newUid);
      return AuthResult(
        success: true,
        uid: newUid,
        accessToken: session?.accessToken,
      );
    } on AuthException catch (e) {
      final status = e.statusCode;
      if (status == '429') {
        _lastRateLimited = 'Trop de tentatives. Réessayez dans quelques '
            'minutes.';
        return AuthResult(
          rateLimited: true,
          error: _lastRateLimited,
        );
      }
      debugPrint('❌ [auth_service] AuthException: $e');
      return AuthResult(error: 'Connexion impossible : ${e.message}');
    } catch (e) {
      debugPrint('❌ [auth_service] Erreur signInAnonymously: $e');
      return const AuthResult(error: 'Connexion impossible (hors-ligne ?).');
    }
  }

  /// Persiste l'UID anon localement (chip pour l'entitlement OR/backfill).
  Future<void> _stashUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(uidKey, uid);
  }

  /// Remet l'état interne à zéro (tests). Ne touche pas aux prefs persistées.
  void resetForTest() {
    _client = null;
    _initFailed = null;
    _lastRateLimited = null;
  }
}