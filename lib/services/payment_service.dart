import 'dart:math' as math;
import 'dart:ui';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Simule le traitement d'un paiement
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String method,
    required String description,
  }) async {
    try {
      // Simuler un délai de traitement
      await Future.delayed(Duration(seconds: 2));

      // Générer un ID de transaction
      final transactionId = _generateTransactionId();

      // Simuler différents scénarios selon la méthode de paiement
      switch (method) {
        case 'mobile_money':
          return await _processMobileMoneyPayment(amount, transactionId);
        case 'bank_transfer':
          return await _processBankTransferPayment(amount, transactionId);
        case 'cash':
          return await _processCashPayment(amount, transactionId);
        default:
          return {
            'success': false,
            'error': 'Méthode de paiement non supportée',
          };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du traitement du paiement: $e',
      };
    }
  }

  /// Simule un paiement Mobile Money
  Future<Map<String, dynamic>> _processMobileMoneyPayment(
    double amount,
    String transactionId,
  ) async {
    // Simuler une vérification Mobile Money
    await Future.delayed(Duration(seconds: 1));

    // 90% de chance de succès pour Mobile Money
    final success = math.Random().nextDouble() > 0.1;

    if (success) {
      return {
        'success': true,
        'transactionId': transactionId,
        'method': 'mobile_money',
        'amount': amount,
        'status': 'completed',
        'message': 'Paiement Mobile Money réussi',
      };
    } else {
      return {
        'success': false,
        'error': 'Échec du paiement Mobile Money. Vérifiez votre solde.',
      };
    }
  }

  /// Traite un paiement MTN Mobile Money
  Future<Map<String, dynamic>> processMtnPayment({
    required double amount,
    required String phoneNumber,
    required String description,
  }) async {
    try {
      // Validation du numéro MTN
      if (!isValidMtnNumber(phoneNumber)) {
        return {
          'success': false,
          'error': 'Numéro MTN invalide. Doit commencer par 9 ou 6.',
        };
      }

      // Générer un ID de transaction MTN
      final transactionId = _generateMtnTransactionId();

      // Simuler l'appel à l'API MTN
      await Future.delayed(const Duration(seconds: 2));

      // Générer un code USSD
      final ussdCode = _generateUssdCode(amount);

      // Simuler le succès du paiement (90% de réussite)
      final success = math.Random().nextDouble() > 0.1;

      if (success) {
        return {
          'success': true,
          'transactionId': transactionId,
          'method': 'mtn_mobile_money',
          'amount': amount,
          'phoneNumber': phoneNumber,
          'ussdCode': ussdCode,
          'status': 'pending', // En attente de confirmation USSD
          'message': 'Code USSD généré. Composez-le pour confirmer le paiement.',
        };
      } else {
        return {
          'success': false,
          'error': 'Impossible de traiter le paiement MTN. Réessayez plus tard.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur lors du traitement MTN: $e',
      };
    }
  }

  /// Vérifie le statut d'un paiement MTN
  Future<Map<String, dynamic>> checkMtnPaymentStatus(String transactionId) async {
    try {
      // Simuler la vérification
      await Future.delayed(const Duration(seconds: 1));

      // Simuler différents statuts
      final statuses = ['completed', 'pending', 'failed'];
      final randomStatus = statuses[math.Random().nextInt(statuses.length)];

      return {
        'status': randomStatus,
        'transactionId': transactionId,
        'message': _getMtnStatusMessage(randomStatus),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': 'Erreur lors de la vérification MTN: $e',
      };
    }
  }

  /// Valide un numéro MTN
  bool isValidMtnNumber(String phoneNumber) {
    // Nettoyer le numéro
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Vérifier la longueur
    if (cleanNumber.length != 8) return false;

    // Vérifier les préfixes MTN (9xxxxxxxx ou 6xxxxxxxx)
    return cleanNumber.startsWith('9') || cleanNumber.startsWith('6');
  }

  /// Génère un ID de transaction MTN
  String _generateMtnTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999).toString().padLeft(4, '0');
    return 'MTN_${timestamp}_$random';
  }

  /// Génère un code USSD pour MTN
  String _generateUssdCode(double amount) {
    final amountInt = amount.toStringAsFixed(0);
    return '*133*1*$amountInt#';
  }

  /// Retourne un message selon le statut MTN
  String _getMtnStatusMessage(String status) {
    switch (status) {
      case 'completed':
        return 'Paiement MTN confirmé avec succès';
      case 'pending':
        return 'Paiement MTN en cours de traitement';
      case 'failed':
        return 'Paiement MTN échoué. Vérifiez votre solde.';
      default:
        return 'Statut MTN inconnu';
    }
  }

  /// Obtient les informations MTN
  Map<String, dynamic> getMtnInfo() {
    return {
      'name': 'MTN Mobile Money',
      'description': 'Paiement rapide et sécurisé via MTN Mobile Money',
      'logo': 'mtn_logo',
      'color': const Color(0xFFFFC107),
      'prefixes': ['9', '6'],
      'ussd_base': '*133*1*',
      'supported': true,
    };
  }

  /// Simule un virement bancaire
  Future<Map<String, dynamic>> _processBankTransferPayment(
    double amount,
    String transactionId,
  ) async {
    // Simuler un délai plus long pour les virements
    await Future.delayed(Duration(seconds: 3));
    
    // 95% de chance de succès pour les virements
    final success = math.Random().nextDouble() > 0.05;
    
    if (success) {
      return {
        'success': true,
        'transactionId': transactionId,
        'method': 'bank_transfer',
        'amount': amount,
        'status': 'completed',
        'message': 'Virement bancaire réussi',
      };
    } else {
      return {
        'success': false,
        'error': 'Échec du virement bancaire. Vérifiez vos informations.',
      };
    }
  }

  /// Simule un paiement en espèces
  Future<Map<String, dynamic>> _processCashPayment(
    double amount,
    String transactionId,
  ) async {
    // Simuler la validation du paiement en espèces
    await Future.delayed(Duration(seconds: 1));
    
    // 100% de succès pour les paiements en espèces (simulation)
    return {
      'success': true,
      'transactionId': transactionId,
      'method': 'cash',
      'amount': amount,
      'status': 'completed',
      'message': 'Paiement en espèces validé',
    };
  }

  /// Vérifie le statut d'un paiement
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      // Simuler une vérification
      await Future.delayed(Duration(seconds: 1));
      
      // Simuler différents statuts
      final statuses = ['completed', 'pending', 'failed'];
      final randomStatus = statuses[math.Random().nextInt(statuses.length)];
      
      return {
        'status': randomStatus,
        'transactionId': transactionId,
        'message': _getStatusMessage(randomStatus),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': 'Erreur lors de la vérification: $e',
      };
    }
  }

  /// Génère un ID de transaction unique
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(9999).toString().padLeft(4, '0');
    return 'TXN_${timestamp}_$random';
  }

  /// Retourne un message selon le statut
  String _getStatusMessage(String status) {
    switch (status) {
      case 'completed':
        return 'Paiement confirmé avec succès';
      case 'pending':
        return 'Paiement en cours de traitement';
      case 'failed':
        return 'Paiement échoué';
      default:
        return 'Statut inconnu';
    }
  }

  /// Obtient les méthodes de paiement disponibles
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'id': 'mobile_money',
        'name': 'Mobile Money',
        'description': 'Paiement via Mobile Money (MTN, Orange, Moov)',
        'icon': 'phone_android',
        'enabled': true,
      },
      {
        'id': 'bank_transfer',
        'name': 'Virement bancaire',
        'description': 'Transfert bancaire direct',
        'icon': 'account_balance',
        'enabled': true,
      },
      {
        'id': 'cash',
        'name': 'Paiement en espèces',
        'description': 'Paiement en espèces (points de vente)',
        'icon': 'money',
        'enabled': true,
      },
    ];
  }

  /// Valide les informations de paiement
  bool validatePaymentInfo({
    required String method,
    required double amount,
    Map<String, dynamic>? additionalInfo,
  }) {
    if (amount <= 0) return false;
    if (method.isEmpty) return false;
    
    switch (method) {
      case 'mobile_money':
        return additionalInfo?['phoneNumber'] != null &&
               additionalInfo!['phoneNumber'].toString().length >= 8;
      case 'bank_transfer':
        return additionalInfo?['accountNumber'] != null &&
               additionalInfo!['accountNumber'].toString().length >= 10;
      case 'cash':
        return true; // Pas de validation spéciale pour les espèces
      default:
        return false;
    }
  }
}
