import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psychotest_plus/services/entitlement_service.dart';
import 'package:psychotest_plus/presentation/progress_exam_results_screen.dart';

// ET9 : matrice de remplacement des 5 tests USSD supprimés.
// Couvre la lecture OR (superset) de l'entitlement et le CTA du mur de
// résultats (bannière d'activation). subscription_wall_test.dart garde le mur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntitlementService OR (matrice superset)', () {
    test('aucune source : pas premium', () async {
      SharedPreferences.setMockInitialValues({});
      final status = await EntitlementService().getStatus();
      expect(status.isPremium, isFalse);
      expect(status.hasLifetime, isFalse);
    });

    test('has_lifetime_access seule => premium', () async {
      SharedPreferences.setMockInitialValues({'has_lifetime_access': true});
      final status = await EntitlementService().getStatus();
      expect(status.isPremium, isTrue);
      expect(status.hasLifetime, isTrue);
    });

    test('has_premium_access seule (achat unique legacy) => premium', () async {
      SharedPreferences.setMockInitialValues({'has_premium_access': true});
      final status = await EntitlementService().getStatus();
      expect(status.isPremium, isTrue);
    });

    test('abonnement actif (expiry futur) => premium', () async {
      final expiry =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'subscription_type': 'premium',
        'subscription_expiry': expiry,
      });
      final status = await EntitlementService().getStatus();
      expect(status.hasActiveSubscription, isTrue);
      expect(status.isPremium, isTrue);
    });

    test('abonnement expiré => pas premium', () async {
      final expiry =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'subscription_type': 'premium',
        'subscription_expiry': expiry,
      });
      final status = await EntitlementService().getStatus();
      expect(status.hasActiveSubscription, isFalse);
      expect(status.isPremium, isFalse);
    });

    test('abonnement type free => pas premium', () async {
      SharedPreferences.setMockInitialValues({'subscription_type': 'free'});
      final status = await EntitlementService().getStatus();
      expect(status.isPremium, isFalse);
    });

    test('backfill élève has_lifetime_access quand premium (à vie > sources)', () async {
      SharedPreferences.setMockInitialValues({'has_premium_access': true});
      final status = await EntitlementService().backfill();
      expect(status.isPremium, isTrue);
      expect(status.hasLifetime, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_lifetime_access'), isTrue);
    });

    test('backfill ne dégrade pas un accès à vie existant', () async {
      SharedPreferences.setMockInitialValues({'has_lifetime_access': true});
      final status = await EntitlementService().backfill();
      expect(status.hasLifetime, isTrue);
      expect(status.isPremium, isTrue);
    });
  });

  group('EntitlementService — essai legacy & refresh', () {
    test('essai activé non utilisé et < 7 jours ⇒ premium', () async {
      final start =
          DateTime.now().subtract(const Duration(days: 3)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'app_activated': true,
        'subscription_type': 'trial',
        'trial_start': start,
      });
      final status = await EntitlementService().getStatus();
      expect(status.hasActiveSubscription, isTrue);
      expect(status.isPremium, isTrue);
    });

    test('essai utilisé ou expiré ⇒ pas premium', () async {
      SharedPreferences.setMockInitialValues({
        'app_activated': true,
        'subscription_type': 'trial',
        'trial_used': true,
      });
      expect((await EntitlementService().getStatus()).isPremium, isFalse);

      final old =
          DateTime.now().subtract(const Duration(days: 8)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'app_activated': true,
        'subscription_type': 'trial',
        'trial_start': old,
      });
      expect((await EntitlementService().getStatus()).isPremium, isFalse);
    });

    test(
        'activation legacy (app_activated + premium sans expiry) ⇒ premium ; '
        'refresh() backfill + isPremium()', () async {
      SharedPreferences.setMockInitialValues({
        'app_activated': true,
        'subscription_type': 'premium',
      });
      final status = await EntitlementService().getStatus();
      expect(status.hasActiveSubscription, isTrue);
      expect(status.isPremium, isTrue);

      // Premium sans expiry ni activation legacy ⇒ inactif (pas de bypass).
      SharedPreferences.setMockInitialValues({'subscription_type': 'premium'});
      expect(
          (await EntitlementService().getStatus()).hasActiveSubscription,
          isFalse);

      // refresh() = lecture + backfill du drapeau superset.
      SharedPreferences.setMockInitialValues({'has_premium_access': true});
      await EntitlementService().refresh();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_lifetime_access'), isTrue);
      expect(await EntitlementService().isPremium(), isTrue);
    });
  });

  group('Results paywall CTA (mur de résultats)', () {
    Future<void> pumpResults(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProgressExamResultsScreen(
            arguments: {
              'results': <Map<String, dynamic>>[],
              'totalQuestions': 25,
              'correctAnswers': 12,
              'timeSpent': 30,
            },
          ),
        ),
      );
      await tester.pump();
    }

    Future<void> dispose(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpWidget(const SizedBox());
    }

    testWidgets('non-premium : bannière d\'activation visible', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpResults(tester);
      expect(find.text('Débloquez les corrections détaillées'), findsOneWidget);
      await dispose(tester);
    });

    testWidgets('accès à vie : pas de bannière d\'activation',
        (tester) async {
      SharedPreferences.setMockInitialValues({'has_lifetime_access': true});
      await pumpResults(tester);
      expect(find.text('Débloquez les corrections détaillées'), findsNothing);
      await dispose(tester);
    });
  });
}