import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psychotest_plus/services/user_state_service.dart';
import 'package:psychotest_plus/services/user_data_service.dart';

// E5 (T3) : identité invité persistée + flag onboarding.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Identité invité', () {
    test('guest id créé une fois puis stable', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await UserStateService.ensureGuestUserId();
      final second = await UserStateService.ensureGuestUserId();
      expect(first.startsWith('guest_'), isTrue);
      expect(second, first);
    });

    test('onboarding flag lecture/écriture', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = UserDataService();
      expect(await svc.isOnboardingCompleted(), isFalse);
      await svc.completeOnboarding();
      expect(await svc.isOnboardingCompleted(), isTrue);
    });
  });
}
