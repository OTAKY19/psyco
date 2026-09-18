import 'package:flutter/foundation.dart';

/// Service de logging professionnel pour remplacer tous les debugPrint()
class AppLogger {
  static const String _tag = 'PsychoTest+';

  /// Log de debug - seulement en mode développement
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      if (error != null) {
        debugPrint('🐛 [$_tag] $message - Error: $error');
        if (stackTrace != null) {
          debugPrint('🐛 [$_tag] StackTrace: $stackTrace');
        }
      } else {
        debugPrint('🐛 [$_tag] $message');
      }
    }
  }

  /// Log d'information
  static void info(String message, [dynamic data]) {
    if (data != null) {
      debugPrint('ℹ️ [$_tag] $message - Data: $data');
    } else {
      debugPrint('ℹ️ [$_tag] $message');
    }
  }

  /// Log d'avertissement
  static void warning(String message, [dynamic data]) {
    debugPrint('⚠️ [$_tag] $message${data != null ? ' - Data: $data' : ''}');
  }

  /// Log d'erreur
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('❌ [$_tag] $message');
    if (error != null) {
      debugPrint('❌ [$_tag] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('❌ [$_tag] StackTrace: $stackTrace');
    }
  }

  /// Log de succès
  static void success(String message, [dynamic data]) {
    debugPrint('✅ [$_tag] $message${data != null ? ' - $data' : ''}');
  }

  /// Log d'événement business
  static void business(String event, [Map<String, dynamic>? parameters]) {
    final params = parameters != null ? ' - ${parameters.toString()}' : '';
    debugPrint('💼 [$_tag] $event$params');
  }

  /// Log de performance
  static void performance(String operation, Duration duration) {
    debugPrint(
        '⚡ [$_tag] $operation completed in ${duration.inMilliseconds}ms');
  }

  /// Log de navigation
  static void navigation(String from, String to, [Map<String, dynamic>? args]) {
    final argsInfo = args != null ? ' with args: ${args.keys.join(', ')}' : '';
    debugPrint('🧭 [$_tag] Navigation: $from → $to$argsInfo');
  }

  /// Log de conversion
  static void conversion(String event, String source, [String? details]) {
    final detailInfo = details != null ? ' - $details' : '';
    debugPrint('🎯 [$_tag] Conversion: $event from $source$detailInfo');
  }

  /// Log de paiement
  static void payment(String event, double amount, String method) {
    debugPrint('💰 [$_tag] Payment: $event - ${amount}FCFA via $method');
  }

  /// Log de fonctionnalité
  static void feature(String featureName, String action, [String? context]) {
    final contextInfo = context != null ? ' in $context' : '';
    debugPrint('🔧 [$_tag] Feature: $featureName - $action$contextInfo');
  }

  /// Log de base de données
  static void database(String operation, [String? details]) {
    final detailInfo = details != null ? ' - $details' : '';
    debugPrint('🗄️ [$_tag] Database: $operation$detailInfo');
  }

  /// Log de réseau
  static void network(String operation, String url, [int? statusCode]) {
    final statusInfo = statusCode != null ? ' (Status: $statusCode)' : '';
    debugPrint('🌐 [$_tag] Network: $operation $url$statusInfo');
  }

  /// Log de sécurité
  static void security(String event, [String? details]) {
    final detailInfo = details != null ? ' - $details' : '';
    debugPrint('🔒 [$_tag] Security: $event$detailInfo');
  }

  /// Log d'initialisation
  static void init(String component, [String? status]) {
    final statusInfo = status != null ? ' - $status' : '';
    debugPrint('🚀 [$_tag] Init: $component$statusInfo');
  }

  /// Log de test
  static void test(String testName, String result, [String? details]) {
    final detailInfo = details != null ? ' - $details' : '';
    final emoji = result.toLowerCase().contains('success') ||
            result.toLowerCase().contains('pass') ||
            result.toLowerCase().contains('ok')
        ? '✅'
        : '❌';
    debugPrint('$emoji [$_tag] Test: $testName - $result$detailInfo');
  }
}
