import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class MtnPaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final Function(Map<String, dynamic>)? onPaymentSuccess;
  final Function()? onPaymentCancel;

  const MtnPaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    this.onPaymentSuccess,
    this.onPaymentCancel,
  });

  @override
  State<MtnPaymentScreen> createState() => _MtnPaymentScreenState();
}

class _MtnPaymentScreenState extends State<MtnPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPaymentInitiated = false;
  Map<String, dynamic>? _paymentResult;
  String? _ussdCode;
  int _step = 1; // 1: Saisie numéro, 2: Confirmation, 3: Traitement

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paiement MTN Mobile Money',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFFFC107), // Couleur MTN
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFC107).withValues(alpha: 0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête MTN
                _buildMtnHeader(),

                SizedBox(height: 4.w),

                // Montant et description
                _buildPaymentDetails(),

                SizedBox(height: 4.w),

                // Étapes du processus
                if (!_isPaymentInitiated) ...[
                  _buildStepIndicator(),
                  SizedBox(height: 4.w),
                  _buildPhoneNumberInput(),
                ] else ...[
                  _buildPaymentProgress(),
                ],

                // Résultat du paiement
                if (_paymentResult != null) ...[
                  SizedBox(height: 4.w),
                  _buildPaymentResult(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMtnHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 8.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MTN Mobile Money',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 1.w),
                Text(
                  'Paiement sécurisé et rapide',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant à payer',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${widget.amount.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFFC107),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'Numéro', _step >= 1),
          _buildStepLine(_step > 1),
          _buildStepCircle(2, 'Confirmation', _step >= 2),
          _buildStepLine(_step > 2),
          _buildStepCircle(3, 'Paiement', _step >= 3),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepNumber, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFFFFC107) : Colors.grey[300],
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isActive ? const Color(0xFFFFC107) : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      width: 4.w,
      color: isActive ? const Color(0xFFFFC107) : Colors.grey[300],
    );
  }

  Widget _buildPhoneNumberInput() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Numéro MTN Mobile Money',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.w),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              hintText: 'Ex: 90000000',
              prefixText: '+229 ',
              prefixStyle: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
            ),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3.w),
          Container(
            width: double.infinity,
            height: 12.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _validateAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgress() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_ussdCode != null) ...[
            Text(
              'Code USSD généré',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2.w),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _ussdCode!,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFC107),
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  IconButton(
                    onPressed: () => _copyUssdCode(),
                    icon: Icon(
                      Icons.copy,
                      color: const Color(0xFFFFC107),
                      size: 6.w,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Composez ce code sur votre téléphone pour valider le paiement',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.w),
          ],

          if (_isLoading) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
            ),
            SizedBox(height: 2.w),
            Text(
              'Traitement du paiement...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checkPaymentStatus,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFC107)),
                      padding: EdgeInsets.symmetric(vertical: 3.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Vérifier le statut',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFFFFC107),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handlePaymentSuccess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      padding: EdgeInsets.symmetric(vertical: 3.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirmer',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentResult() {
    final isSuccess = _paymentResult?['success'] == true;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: Colors.white,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? 'Paiement réussi !' : 'Échec du paiement',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 1.w),
                Text(
                  _paymentResult?['message'] ?? 'Une erreur est survenue',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndProceed() {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre numéro de téléphone')),
      );
      return;
    }

    if (phoneNumber.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro doit contenir 8 chiffres')),
      );
      return;
    }

    if (!phoneNumber.startsWith('9') && !phoneNumber.startsWith('6')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro MTN invalide. Doit commencer par 9 ou 6')),
      );
      return;
    }

    setState(() {
      _step = 2;
    });

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmer le paiement',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous allez payer ${widget.amount.toStringAsFixed(0)} FCFA via MTN Mobile Money.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              'Numéro: +229 ${_phoneController.text}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFFC107),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _step = 1;
              });
            },
            child: Text(
              'Annuler',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initiatePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _isPaymentInitiated = true;
      _step = 3;
    });

    try {
      // Générer un code USSD simulé
      _ussdCode = '*133*1*${widget.amount.toStringAsFixed(0)}#';

      // Simuler l'appel à l'API MTN
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code USSD généré. Composez-le sur votre téléphone.'),
          backgroundColor: const Color(0xFFFFC107),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _copyUssdCode() {
    if (_ussdCode != null) {
      Clipboard.setData(ClipboardData(text: _ussdCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code USSD copié dans le presse-papiers'),
          backgroundColor: Color(0xFFFFC107),
        ),
      );
    }
  }

  void _checkPaymentStatus() async {
    setState(() => _isLoading = true);

    try {
      // Simuler la vérification du statut
      await Future.delayed(const Duration(seconds: 2));

      // Simuler un paiement réussi
      final result = {
        'success': true,
        'transactionId': 'MTN_${DateTime.now().millisecondsSinceEpoch}',
        'method': 'mobile_money',
        'amount': widget.amount,
        'status': 'completed',
        'message': 'Paiement MTN Mobile Money confirmé',
      };

      setState(() {
        _paymentResult = result;
        _isLoading = false;
      });

      // Appeler le callback de succès
      widget.onPaymentSuccess?.call(result);

    } catch (e) {
      setState(() {
        _paymentResult = {
          'success': false,
          'error': 'Erreur lors de la vérification',
        };
        _isLoading = false;
      });
    }
  }

  void _handlePaymentSuccess() {
    if (_paymentResult?['success'] == true) {
      Navigator.of(context).pop(_paymentResult);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord vérifier le statut du paiement'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleBack() {
    if (_isPaymentInitiated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Annuler le paiement ?'),
          content: const Text('Êtes-vous sûr de vouloir annuler le paiement en cours ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onPaymentCancel?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    } else {
      widget.onPaymentCancel?.call();
      Navigator.of(context).pop();
    }
  }
}
