import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:psychotest_plus/services/subscription_service.dart';

// Couvre les branches d'entitlement ajoutées par le mur freemium (ET) :
// bypass accès à vie / abonnement dans canTakeTest, isPremiumUser et la
// matrice canAccessPremiumFeature (basic_tests toujours accessible).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = SubscriptionService();

  group('canTakeTest — bypass d\'entitlement', () {
    test('true à 10 gratuits avec accès à vie (bypass du mur)', () async {
      SharedPreferences.setMockInitialValues(
          {'free_tests_used': 10, 'has_lifetime_access': true});
      expect(await service.canTakeTest(), isTrue);
    });

    test('true à 10 gratuits avec abonnement actif', () async {
      final expiry =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'free_tests_used': 10,
        'subscription_type': 'premium',
        'subscription_expiry': expiry,
      });
      expect(await service.canTakeTest(), isTrue);
      // Abonnement expiré → le mur freemium reprend.
      final past =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'free_tests_used': 10,
        'subscription_type': 'premium',
        'subscription_expiry': past,
      });
      expect(await service.canTakeTest(), isFalse);
    });
  });

  group('isPremiumUser', () {
    test('faux par défaut, vrai avec accès à vie ou abonnement actif',
        () async {
      SharedPreferences.setMockInitialValues({});
      expect(await service.isPremiumUser(), isFalse);

      SharedPreferences.setMockInitialValues({'has_lifetime_access': true});
      expect(await service.isPremiumUser(), isTrue);

      final expiry =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'subscription_type': 'premium',
        'subscription_expiry': expiry,
      });
      expect(await service.isPremiumUser(), isTrue);
    });
  });

  group('canAccessPremiumFeature — matrice', () {
    test('basic_tests toujours vrai (freemium), premium verrouillés', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await service.canAccessPremiumFeature('basic_tests'), isTrue);
      expect(await service.canAccessPremiumFeature('premium_tests'), isFalse);
      expect(await service.canAccessPremiumFeature('advanced_stats'), isFalse);
      expect(await service.canAccessPremiumFeature('unlimited_access'), isFalse);
      expect(await service.canAccessPremiumFeature('inconnu'), isFalse);
    });

    test('avec abonnement actif, tout est accessible', () async {
      final expiry =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'subscription_type': 'premium',
        'subscription_expiry': expiry,
      });
      expect(await service.canAccessPremiumFeature('premium_tests'), isTrue);
      expect(await service.canAccessPremiumFeature('advanced_stats'), isTrue);
    });
  });
}