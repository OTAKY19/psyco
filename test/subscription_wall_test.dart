import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psychotest_plus/services/subscription_service.dart';

// R1 (E5) : le mur freemium bloque réellement après retrait des bypass TEST.
// Si ce test casse, le lancement est à revenu zéro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mur freemium', () {
    test('canTakeTest est faux après 10 gratuits sans abonnement', () async {
      SharedPreferences.setMockInitialValues({'free_tests_used': 10});
      expect(await SubscriptionService().canTakeTest(), isFalse);
    });

    test('canTakeTest est vrai sous la limite', () async {
      SharedPreferences.setMockInitialValues({'free_tests_used': 3});
      expect(await SubscriptionService().canTakeTest(), isTrue);
      expect(await SubscriptionService().canTakeFreeTest(), isTrue);
    });

    test('pas premium par défaut (ni abonnement, ni accès à vie)', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SubscriptionService().isPremiumUser(), isFalse);
      expect(await SubscriptionService().hasActiveSubscription(), isFalse);
    });

    test('compteur restant cohérent', () async {
      SharedPreferences.setMockInitialValues({'free_tests_used': 7});
      expect(await SubscriptionService().getRemainingFreeTests(), 3);
    });
  });
}
