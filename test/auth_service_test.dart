import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:psychotest_plus/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService (ET7) — rail non configuré (fail-open)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AuthService().resetForTest();
    });

    test('ensureAnonSession sans URL/clef → railConfigured=false, aucun réseau',
        () async {
      final result = await AuthService().ensureAnonSession();

      expect(result.success, isFalse);
      expect(result.railConfigured, isFalse);
      expect(result.uid, isNull);
      expect(result.rateLimited, isFalse);
    });

    test('lastRateLimitedMessage reste null sans tentative réseau', () async {
      await AuthService().ensureAnonSession();
      expect(AuthService().lastRateLimitedMessage, isNull);
      expect(AuthService().isRailConfigured, isFalse);
    });

    test('getStoredAnonUid sans session persistée → null', () async {
      final uid = await AuthService().getStoredAnonUid();
      expect(uid, isNull);
    });

    test('le sign-in ne conserve jamais de UID en fail-open', () async {
      await AuthService().ensureAnonSession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthService.uidKey), isNull);
    });
  });
}