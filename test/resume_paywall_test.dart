import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:psychotest_plus/services/one_time_purchase_service.dart';

Future<void> _seedPending({
  required String txnId,
  required String status,
  String? createdAt,
  String provider = 'mtn',
}) async {
  SharedPreferences.setMockInitialValues({
    'pending_transaction': jsonEncode({
      'id': txnId,
      'phone_number': '90770000',
      'provider': provider,
      'amount': OneTimePurchaseService.fixedPrice,
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    }),
  });
}

String _oldIso() =>
    DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Éviter la fuite du cache premium du singleton entre les scénarios.
    OneTimePurchaseService().resetCachedStatusForTest();
  });

  group('ET8 — verify-on-resume', () {
    test('aucune transaction → none (jamais de grant)', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await OneTimePurchaseService().verifyOnResume();
      expect(result, ResumeVerification.none);
      expect(await OneTimePurchaseService().hasPremiumAccess(), isFalse);
    });

    test('transaction non attestée non expirée → inFlight (CTA en vol)',
        () async {
      await _seedPending(txnId: 'TX_1', status: 'pending');
      final result = await OneTimePurchaseService().verifyOnResume();
      expect(result, ResumeVerification.inFlight);
      expect(await OneTimePurchaseService().hasPremiumAccess(), isFalse);

      // La transaction reste pour que le CTA puisse se ré-attacher.
      final pending = await OneTimePurchaseService().getPendingTransaction();
      expect(pending?['id'], 'TX_1');
    });

    test('transaction attestée → granted, grant idempotent (un seul appel)',
        () async {
      await _seedPending(txnId: 'TX_2', status: 'attested');
      final result = await OneTimePurchaseService().verifyOnResume();
      expect(result, ResumeVerification.granted);
      expect(await OneTimePurchaseService().hasPremiumAccess(), isTrue);

      // Second verify : la transaction est déjà consommée par le grant →
      // none (no-op idempotent), aucun double effet, l'accès reste actif.
      final again = await OneTimePurchaseService().verifyOnResume();
      expect(again, ResumeVerification.none);
      expect(await OneTimePurchaseService().hasPremiumAccess(), isTrue);
    });

    test('transaction expirée non attestée → expired + nettoyée', () async {
      await _seedPending(
          txnId: 'TX_3', status: 'pending', createdAt: _oldIso());
      final result = await OneTimePurchaseService().verifyOnResume();
      expect(result, ResumeVerification.expired);
      expect(await OneTimePurchaseService().hasPremiumAccess(), isFalse);
      expect(await OneTimePurchaseService().getPendingTransaction(), isNull);
    });

    test('short-poll : revient inFlight après timeout sans attestation',
        () async {
      await _seedPending(txnId: 'TX_4', status: 'pending');
      final result = await OneTimePurchaseService().shortPollVerification(
        timeout: const Duration(milliseconds: 200),
        interval: const Duration(milliseconds: 40),
      );
      expect(result, ResumeVerification.inFlight);
    });
  });

  group('ET8 — helpers', () {
    test('ussdCodeFor expose le code MTN/Moov (ré-attachement CTA)', () {
      final service = OneTimePurchaseService();
      expect(service.ussdCodeFor('mtn'), '*133*1*3000#');
      expect(service.ussdCodeFor('moov'), '*155*1*3000#');
      expect(service.ussdCodeFor('safaricom'), '*#');
    });

    test('isTransactionExpired reste testable en isolé', () {
      expect(OneTimePurchaseService.isTransactionExpired(null), isTrue);
      expect(
        OneTimePurchaseService.isTransactionExpired(DateTime.now()
            .add(const Duration(minutes: 1))
            .toIso8601String()),
        isFalse,
      );
    });
  });
}