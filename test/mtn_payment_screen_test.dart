import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:psychotest_plus/presentation/mtn_payment_screen/mtn_payment_screen.dart';

// Couvre les branches UI du cycle de vie ET8 non couvertes par les tests
// service : ré-attachement du CTA en vol après app death, validation du
// numéro, initiation du paiement (USSD), attestation "J'ai payé" et grant
// au retour d'app (resumed).
Widget _app({void Function(Map<String, dynamic>)? onSuccess}) {
  return MaterialApp(
    home: MtnPaymentScreen(
      amount: 3000,
      description: 'Accès Complet',
      onPaymentSuccess: onSuccess,
    ),
  );
}

// Écran large et haut (800x1200 logiques) : laisse tous les CTA hittables
// sans déclencher les overflow horizontaux de l'écran à 360px (voir note QA).
void _setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 3600);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void _seedPending({required String txnId, required String status}) {
  SharedPreferences.setMockInitialValues({
    'pending_transaction': jsonEncode({
      'id': txnId,
      'phone_number': '90770000',
      'provider': 'mtn',
      'amount': 3000.0,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    }),
  });
}

String _oldIso() =>
    DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String();

// Laisse les timers de SnackBar (durée 4-5 s) expirer avant de continuer.
Future<void> _drainSnackbars(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

// Va jusqu'à l'écran USSD (initiation réussie) depuis l'écran de saisie.
Future<void> _initiateValidPayment(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), '90770000');
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirmer'));
  await tester.pumpAndSettle();
  expect(find.text('Code USSD généré'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ET8 — ré-attachement du CTA en vol', () {
    testWidgets('transaction en attente valide → CTA USSD ré-attaché à l\'init',
        (tester) async {
      _setPhoneSurface(tester);
      _seedPending(txnId: 'TX_1', status: 'pending');
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Code USSD généré'), findsOneWidget);
      expect(find.text('*133*1*3000#'), findsOneWidget);
      expect(find.text("J'ai payé sur mon téléphone"), findsOneWidget);
    });

    testWidgets('transaction expirée → pas de ré-attache, écran au pas 1',
        (tester) async {
      _setPhoneSurface(tester);
      SharedPreferences.setMockInitialValues({
        'pending_transaction': jsonEncode({
          'id': 'TX_2',
          'phone_number': '90770000',
          'provider': 'mtn',
          'amount': 3000.0,
          'status': 'pending',
          'created_at': _oldIso(),
        }),
      });
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // L'écran proposérique reste à l'étape de saisie du numéro.
      expect(find.text('Numéro MTN Mobile Money'), findsOneWidget);
      expect(find.text('Code USSD généré'), findsNothing);
      expect(find.text("J'ai payé sur mon téléphone"), findsNothing);
    });
  });

  group('ET8 — flux d\'initiation', () {
    testWidgets('numéro invalide → snackbar ; valide → USSD généré + txn stockée',
        (tester) async {
      _setPhoneSurface(tester);
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Trop court.
      await tester.enterText(find.byType(TextFormField), '9077');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(find.text('Le numéro doit contenir 8 chiffres'), findsOneWidget);

      await _drainSnackbars(tester);

      // Mauvais préfixe MTN.
      await tester.enterText(find.byType(TextFormField), '50770000');
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      expect(
          find.text('Numéro MTN invalide. Doit commencer par 9 ou 6'),
          findsOneWidget);

      await _drainSnackbars(tester);

      // Numéro valide → dialogue de confirmation, puis initiation.
      await _initiateValidPayment(tester);

      // La transaction persistée permet le ré-attachement après app death.
      final prefs = await SharedPreferences.getInstance();
      final pending =
          jsonDecode(prefs.getString('pending_transaction')!) as Map;
      expect(pending['status'], 'pending');

      await _drainSnackbars(tester);
    });

    testWidgets('attestation "J\'ai payé" → succès, callback onPaymentSuccess',
        (tester) async {
      _setPhoneSurface(tester);
      SharedPreferences.setMockInitialValues({});
      Map<String, dynamic>? callbackResult;
      var callbackCalled = false;
      await tester.pumpWidget(_app(onSuccess: (r) {
        callbackCalled = true;
        callbackResult = r;
      }));
      await tester.pumpAndSettle();

      await _initiateValidPayment(tester);

      // Attestation manuelle → grant immédiat (pas d'API opérateur).
      await tester.tap(find.text("J'ai payé sur mon téléphone"));
      await tester.pumpAndSettle();
      expect(find.text('Paiement réussi !'), findsOneWidget);
      expect(callbackCalled, isTrue);
      expect(callbackResult?['success'], isTrue);

      await _drainSnackbars(tester);
    });

    testWidgets('retour d\'app (resumed) avec txn attestée → grant ET8',
        (tester) async {
      _setPhoneSurface(tester);
      _seedPending(txnId: 'TX_3', status: 'attested');
      Map<String, dynamic>? callbackResult;
      await tester
          .pumpWidget(_app(onSuccess: (r) => callbackResult = r));
      await tester.pumpAndSettle();
      expect(find.text('Code USSD généré'), findsOneWidget);

      // Simule le retour d'app : verifyOnResume débloque le grant idempotent.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('Paiement réussi !'), findsOneWidget);
      expect(callbackResult?['success'], isTrue);

      // La transaction est consommée par le grant (pas de double effet).
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_transaction'), isNull);
    });
  });
}