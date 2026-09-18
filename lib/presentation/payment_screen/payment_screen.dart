import 'package:flutter/material.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../services/subscription_service.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final SubscriptionService _subscriptionService = SubscriptionService();

  String _selectedPaymentMethod = 'mobile_money';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),

                      // Payment summary
                      _buildOrderSummary(),

                      const SizedBox(height: AppSpacing.xxl),

                      // Payment methods
                      _buildPaymentMethods(),

                      const SizedBox(height: AppSpacing.xxl),

                      // Payment info
                      _buildPaymentInfo(),

                      const SizedBox(height: AppSpacing.xxl),

                      // Pay button
                      _buildPaymentButton(),

                      const SizedBox(height: AppSpacing.lg),

                      // Security info
                      _buildSecurityInfo(),

                      SizedBox(height: padding.bottom + AppSpacing.xxl),
                    ],
                  ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.xxl),
          bottomRight: Radius.circular(AppRadii.xxl),
        ),
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paiement sécurisé', style: AppTextStyles.titleMedium),
                Text(
                  'Activation premium',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: const Icon(Icons.shield_rounded, size: 20, color: AppColors.success),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Résumé de la commande', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Activation de l'application", style: AppTextStyles.bodyMedium),
                Text(
                  '${widget.amount.toStringAsFixed(0)} FCFA',
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headlineSmall),
              Text(
                '${widget.amount.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Méthode de paiement', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildPaymentMethodCard(
          'mobile_money',
          'Mobile Money',
          'MTN, Moov Money',
          Icons.phone_android_rounded,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildPaymentMethodCard(
          'bank_transfer',
          'Virement bancaire',
          'Transfert bancaire direct',
          Icons.account_balance_rounded,
          AppColors.accent,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildPaymentMethodCard(
          'cash',
          'Paiement en espèces',
          'Points de vente partenaires',
          Icons.payments_rounded,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.cardSm : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(description, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Détails du paiement', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              children: [
                _buildInfoRow('Montant', '${widget.amount.toStringAsFixed(0)} FCFA'),
                _buildInfoRow('Description', widget.description),
                _buildInfoRow('Méthode', _getPaymentMethodLabel()),
                _buildInfoRow('Statut', 'En attente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppRadii.button),
          boxShadow: AppShadows.ctaLg,
        ),
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _processPayment,
          icon: _isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.payment_rounded, color: Colors.white, size: 22),
          label: Text(
            _isProcessing ? 'Traitement en cours...' : 'Payer maintenant',
            style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Paiement sécurisé et crypté. Vos informations sont protégées.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.successDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel() {
    switch (_selectedPaymentMethod) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'cash':
        return 'Paiement en espèces';
      default:
        return 'Non sélectionné';
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = {
        'success': true,
        'transactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'amount': widget.amount,
        'method': _selectedPaymentMethod,
      };

      if (result['success'] == true) {
        final activationSuccess = await _subscriptionService.activatePremiumAccount(
          transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          amount: SubscriptionService.premiumPrice.toDouble(),
        );

        if (activationSuccess) {
          _showSuccessDialog();
        } else {
          _showErrorDialog("Erreur lors de l'activation du compte");
        }
      } else {
        _showErrorDialog((result['error'] as String?) ?? 'Erreur de paiement');
      }
    } catch (e) {
      _showErrorDialog('Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('Paiement réussi !', style: AppTextStyles.titleMedium),
          ],
        ),
        content: Text(
          'Votre compte a été activé avec succès. Vous pouvez maintenant accéder à toutes les fonctionnalités premium.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaymentSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: Text('Continuer', style: AppTextStyles.buttonMedium.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Erreur de paiement', style: AppTextStyles.titleMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
