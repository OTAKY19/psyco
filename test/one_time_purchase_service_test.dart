import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:psychotest_plus/services/one_time_purchase_service.dart';

// Couvre les branches critiques NON couvertes par resume_paywall_test.dart :
// initiatePurchase (guards + succès), confirmPayment, attestation, nettoyage,
// détection du fournisseur et wrapper de compatibilité.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Éviter la fuite du cache premium du singleton entre les scénarios.
    OneTimePurchaseService().resetCachedStatusForTest();
  });

  final service = OneTimePurchaseService();

  group('initiatePurchase — guards et validation', () {
    test('déjà premium → ALREADY_PREMIUM sans nouvelle transaction', () async {
      SharedPreferences.setMockInitialValues({'has_premium_access': true});
      final result = await service.initiatePurchase(
          provider: 'mtn', phoneNumber: '90770000');
      expect(result['success'], isFalse);
      expect(result['error_code'], 'ALREADY_PREMIUM');
      expect(await service.getPendingTransaction(), isNull);
    });

    test('fournisseur inconnu → INVALID_PROVIDER', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await service.initiatePurchase(
          provider: 'vodafone', phoneNumber: '90770000');
      expect(result['success'], isFalse);
      expect(result['error_code'], 'INVALID_PROVIDER');
    });

    test('numéro invalide (longueur ou préfixe) → INVALID_PHONE, rien stocké',
        () async {
      SharedPreferences.setMockInitialValues({});
      // Trop court.
      final short = await service.initiatePurchase(
          provider: 'mtn', phoneNumber: '9077');
      expect(short['error_code'], 'INVALID_PHONE');
      // Mauvaise longueur → aucun fournisseur ne passe.
      expect(
          await service.initiatePurchase(provider: 'mtn', phoneNumber: '9'),
          containsPair('error_code', 'INVALID_PHONE'));
      // Mauvais préfixe MTN (5 est Moov, pas MTN).
      final badMtn = await service.initiatePurchase(
          provider: 'mtn', phoneNumber: '50770000');
      expect(badMtn['error_code'], 'INVALID_PHONE');
      // Mauvais préfixe Moov (4 n'est ni Moov ni MTN).
      final badMoov = await service.initiatePurchase(
          provider: 'moov', phoneNumber: '40770000');
      expect(badMoov['error_code'], 'INVALID_PHONE');
      // Rien n'a été persisté après les échecs.
      expect(await service.getPendingTransaction(), isNull);
    });
  });

  group('initiatePurchase — succès', () {
    test('transaction en attente sauvegardée avec USSD et montant 3000',
        () async {
      SharedPreferences.setMockInitialValues({'pending_expired': true});
      final result = await service.initiatePurchase(
          provider: 'mtn', phoneNumber: '90770000');
      expect(result['success'], isTrue);
      expect(result['amount'], OneTimePurchaseService.fixedPrice);
      expect(result['currency'], 'FCFA');
      expect(result['ussd_code'], '*133*1*3000#');
      expect(result['message'], contains('*133*1*3000#'));
      expect(result['instructions'], isNotEmpty);

      final pending = await service.getPendingTransaction();
      expect(pending?['id'], result['transaction_id']);
      expect(pending?['status'], 'pending');
      expect(pending?['phone_number'], '90770000');

      // Le flag pending_expired est nettoyé à l'initiation.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pending_expired'), isNull);
    });
  });

  group('confirmPayment — expiré / non attesté / attesté', () {
    test('flag pending_expired → PAYMENT_EXPIRED + retry, flag nettoyé',
        () async {
      SharedPreferences.setMockInitialValues({'pending_expired': true});
      final result = await service.confirmPayment('TX_ANY');
      expect(result['success'], isFalse);
      expect(result['error_code'], 'PAYMENT_EXPIRED');
      expect(result['retry_suggested'], isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pending_expired'), isNull);
    });

    test('non attestée → PAYMENT_NOT_CONFIRMED, aucun grant', () async {
      SharedPreferences.setMockInitialValues({
        'pending_transaction': jsonEncode({
          'id': 'TX_1',
          'phone_number': '90770000',
          'provider': 'mtn',
          'amount': OneTimePurchaseService.fixedPrice,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        }),
      });
      final result = await service.confirmPayment('TX_1');
      expect(result['success'], isFalse);
      expect(result['error_code'], 'PAYMENT_NOT_CONFIRMED');
      expect(await service.hasPremiumAccess(), isFalse);
    });

    test('attestée → grant : clés premium écrites, transaction nettoyée, cache',
        () async {
      SharedPreferences.setMockInitialValues({
        'pending_transaction': jsonEncode({
          'id': 'TX_2',
          'phone_number': '90770000',
          'provider': 'mtn',
          'amount': OneTimePurchaseService.fixedPrice,
          'status': 'attested',
          'created_at': DateTime.now().toIso8601String(),
        }),
      });
      final result = await service.confirmPayment('TX_2');
      expect(result['success'], isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_premium_access'), isTrue);
      expect(prefs.getString('premium_transaction_id'), 'TX_2');
      expect(prefs.getString('premium_purchase_date'), isNotNull);
      expect(prefs.getString('pending_transaction'), isNull);
      expect(await service.hasPremiumAccess(), isTrue);
    });
  });

  group('attestation manuelle', () {
    test('mismatch → false ; correspondance → true et status attesté',
        () async {
      SharedPreferences.setMockInitialValues({});
      expect(await service.markUserAttested('TX_ABSENT'), isFalse);

      SharedPreferences.setMockInitialValues({
        'pending_transaction': jsonEncode({
          'id': 'TX_3',
          'phone_number': '90770000',
          'provider': 'mtn',
          'amount': OneTimePurchaseService.fixedPrice,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        }),
      });
      expect(await service.markUserAttested('TX_AUTRE'), isFalse);
      expect(await service.markUserAttested('TX_3'), isTrue);
      final pending = await service.getPendingTransaction();
      expect(pending?['status'], 'attested');
      expect(pending?['attested_at'], isNotNull);
    });
  });

  group('persistance et utilitaires', () {
    test('getPendingTransaction : JSON corrompu → transaction retirée',
        () async {
      SharedPreferences.setMockInitialValues(
          {'pending_transaction': 'pas-json-'});
      expect(await service.getPendingTransaction(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pending_transaction'), isNull);
    });

    test('detectProviderFromPhone : mtn / moov / null', () {
      expect(service.detectProviderFromPhone('90000000'), 'mtn');
      expect(service.detectProviderFromPhone('50000000'), 'moov');
      expect(service.detectProviderFromPhone('40000000'), isNull);
      expect(service.detectProviderFromPhone('9'), isNull);
    });
  });

  group('compatibilité', () {
    test('purchaseFullAccess : wrapper succès et erreur', () async {
      SharedPreferences.setMockInitialValues({});
      final ok = await service.purchaseFullAccess('mtn', '90770000');
      expect(ok.success, isTrue);
      expect(ok.ussdCode, '*133*1*3000#');
      expect(ok.amount, OneTimePurchaseService.fixedPrice);
      expect(ok.transactionId, isNotNull);
      expect(ok.instructions, isNotEmpty);

      final err = await service.purchaseFullAccess('mtn', '12');
      expect(err.success, isFalse);
      expect(err.errorMessage, isNotNull);
    });
  });
}