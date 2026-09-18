import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../services/one_time_purchase_service.dart';

const Color _mtnYellow = Color(0xFFFFC107);
const Color _mtnYellowDark = Color(0xFFFFB300);

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
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isPaymentInitiated = false;
  Map<String, dynamic>? _paymentResult;
  String? _ussdCode;
  String? _transactionId;
  int _step = 1;
  final OneTimePurchaseService _purchaseService = OneTimePurchaseService();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // MTN branding header
                    _buildMtnHeader(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Payment details
                    _buildPaymentDetails(),

                    const SizedBox(height: AppSpacing.xxl),

                    if (!_isPaymentInitiated) ...[
                      _buildStepIndicator(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildPhoneNumberInput(),
                    ] else ...[
                      _buildPaymentProgress(),
                    ],

                    if (_paymentResult != null) ...[
                      const SizedBox(height: AppSpacing.xxl),
                      _buildPaymentResult(),
                    ],

                    SizedBox(height: padding.bottom + AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: _mtnYellow,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.xxl),
          bottomRight: Radius.circular(AppRadii.xxl),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
              onPressed: _handleBack,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement MTN Mobile Money',
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
                Text(
                  'Paiement sécurisé',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMtnHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [
          BoxShadow(
            color: _mtnYellow.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _mtnYellow,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MTN Mobile Money', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Paiement sécurisé et rapide',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildDetailRow('Montant à payer', '${widget.amount.toStringAsFixed(0)} FCFA', isPrice: true),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow('Description', widget.description),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: isPrice
              ? AppTextStyles.titleLarge.copyWith(color: _mtnYellow, fontWeight: FontWeight.w700)
              : AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderLight),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _mtnYellow : AppColors.borderLight,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isActive ? _mtnYellow : AppColors.textMuted,
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
      width: 24,
      color: isActive ? _mtnYellow : AppColors.borderLight,
    );
  }

  Widget _buildPhoneNumberInput() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Numéro MTN Mobile Money', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.md),
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
              prefixStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: _mtnYellow, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_mtnYellow, _mtnYellowDark],
                ),
                borderRadius: BorderRadius.circular(AppRadii.button),
                boxShadow: [
                  BoxShadow(
                    color: _mtnYellow.withValues(alpha: 0.3),
                    blurRadius: 12,
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
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          if (_ussdCode != null) ...[
            Text('Code USSD généré', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: _mtnYellow.withValues(alpha: 0.3), width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _ussdCode!,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: _mtnYellow,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    tooltip: 'Copier le code USSD',
                    onPressed: _copyUssdCode,
                    icon: const Icon(Icons.copy_rounded, color: _mtnYellow, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Composez ce code sur votre téléphone pour valider le paiement',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (_isLoading) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_mtnYellow),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Traitement du paiement...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _attestAndConfirm,
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: _mtnYellow, size: 20),
                label: Text(
                  "J'ai payé sur mon téléphone",
                  style: AppTextStyles.buttonMedium
                      .copyWith(color: _mtnYellow),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _mtnYellow, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _checkPaymentStatus,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _mtnYellow,
                      side: const BorderSide(color: _mtnYellow),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: Text('Vérifier le statut', style: AppTextStyles.buttonMedium.copyWith(color: _mtnYellow)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _mtnYellow,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: ElevatedButton(
                        onPressed: _handlePaymentSuccess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: Text('Confirmer', style: AppTextStyles.buttonMedium.copyWith(color: Colors.white)),
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isSuccess ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isSuccess ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess ? 'Paiement réussi !' : 'Échec du paiement',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isSuccess ? AppColors.successDark : AppColors.errorDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _paymentResult?['message'] ?? 'Une erreur est survenue',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

    setState(() => _step = 2);
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Confirmer le paiement', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Vous allez payer ${widget.amount.toStringAsFixed(0)} FCFA via MTN Mobile Money.",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentContainer,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_rounded, color: _mtnYellow, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '+229 ${_phoneController.text}',
                    style: AppTextStyles.titleSmall.copyWith(color: _mtnYellow),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _step = 1);
            },
            child: Text('Annuler', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initiatePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mtnYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
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
      // Chemin canonique : montant offre unique 3000 FCFA (OneTimePurchaseService).
      final phoneNumber =
          _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      final result = await _purchaseService.initiatePurchase(
        provider: 'mtn',
        phoneNumber: phoneNumber,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _ussdCode = result['ussd_code'] as String?;
          _transactionId = result['transaction_id'] as String?;
          _paymentResult = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Code USSD généré. Composez-le sur votre téléphone.'),
            backgroundColor: _mtnYellow,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm)),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _isPaymentInitiated = false;
          _step = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] as String? ?? 'Erreur')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isPaymentInitiated = false;
        _step = 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  /// Attestation manuelle (pas d'API opérateur) puis vérification.
  void _attestAndConfirm() async {
    if (_transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucune transaction en cours. Recommencez.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _purchaseService.markUserAttested(_transactionId!);
      await _checkPaymentStatus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyUssdCode() {
    if (_ussdCode != null) {
      Clipboard.setData(ClipboardData(text: _ussdCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code USSD copié dans le presse-papiers'),
          backgroundColor: _mtnYellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      );
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucune transaction en cours. Recommencez.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result =
          await _purchaseService.confirmPayment(_transactionId!);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _paymentResult = {
            'success': true,
            'transactionId': result['transaction_id'],
            'method': 'mobile_money',
            'status': 'completed',
            'message': 'Paiement confirmé. Accès premium activé.',
          };
          _isLoading = false;
        });
        widget.onPaymentSuccess?.call(_paymentResult!);
      } else if (result['error_code'] == 'PAYMENT_EXPIRED') {
        await _purchaseService.clearPendingTransaction();
        setState(() {
          _paymentResult = {
            'success': false,
            'message': result['error'],
          };
          _isLoading = false;
          _isPaymentInitiated = false;
          _transactionId = null;
          _ussdCode = null;
          _step = 1;
        });
      } else {
        setState(() {
          _paymentResult = {
            'success': false,
            'message': result['error'] ?? 'Paiement non confirmé',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paymentResult = {
          'success': false,
          'error': 'Erreur lors de la vérification'
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
        SnackBar(
          content: const Text("Veuillez d'abord vérifier le statut du paiement"),
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
        ),
      );
    }
  }

  void _handleBack() {
    if (_isPaymentInitiated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
          title: Text('Annuler le paiement ?', style: AppTextStyles.titleMedium),
          content: Text(
            'Êtes-vous sûr de vouloir annuler le paiement en cours ?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                unawaited(_purchaseService.clearPendingTransaction());
                widget.onPaymentCancel?.call();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
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
