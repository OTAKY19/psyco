import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';

/// Écran de confirmation de paiement et d'activation du compte premium
class PaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentResult;

  const PaymentConfirmationScreen({
    super.key,
    this.paymentResult,
  });

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen>
    with TickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();

  late AnimationController _mainAnimationController;
  late AnimationController _successAnimationController;
  late AnimationController _loadingAnimationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  PaymentConfirmationState _currentState = PaymentConfirmationState.verifying;
  String? _errorMessage;
  Map<String, dynamic>? _paymentData;
  Timer? _verificationTimer;
  int _verificationAttempts = 0;
  static const int maxVerificationAttempts = 6;

  @override
  void initState() {
    super.initState();
    _paymentData = widget.paymentResult;
    _initializeAnimations();
    _startPaymentVerification();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: const Interval(0.2, 1.0)),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.linear),
    );

    _mainAnimationController.forward();
    _loadingAnimationController.repeat();
  }

  void _startPaymentVerification() {
    if (_paymentData == null || _paymentData!['transactionId'] == null) {
      setState(() {
        _currentState = PaymentConfirmationState.error;
        _errorMessage = 'Données de paiement manquantes';
      });
      return;
    }
    _verifyPaymentStatus();
  }

  Future<void> _verifyPaymentStatus() async {
    try {
      final transactionId = _paymentData!['transactionId'];
      final statusResult = await _subscriptionService.checkPaymentStatus(transactionId!);

      switch (statusResult['status']) {
        case 'completed':
          await _activatePremiumAccount();
          break;
        case 'failed':
          setState(() {
            _currentState = PaymentConfirmationState.error;
            _errorMessage = 'Le paiement a échoué. Veuillez réessayer.';
          });
          break;
        case 'pending':
        default:
          _scheduleNextVerification();
          break;
      }
    } catch (e) {
      if (_verificationAttempts >= maxVerificationAttempts) {
        setState(() {
          _currentState = PaymentConfirmationState.error;
          _errorMessage = "Délai d'attente dépassé. Contactez le support.";
        });
      } else {
        _scheduleNextVerification();
      }
    }
  }

  void _scheduleNextVerification() {
    _verificationAttempts++;
    if (_verificationAttempts >= maxVerificationAttempts) {
      setState(() {
        _currentState = PaymentConfirmationState.timeout;
        _errorMessage = 'Vérification en cours. Cela peut prendre quelques minutes.';
      });
      return;
    }
    _verificationTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _verifyPaymentStatus();
    });
  }

  Future<void> _activatePremiumAccount() async {
    try {
      final success = await _subscriptionService.activatePremiumAccount(
        transactionId: _paymentData!['transactionId'],
        amount: _paymentData!['amount']?.toDouble() ?? SubscriptionService.premiumPrice,
      );
      if (success) {
        setState(() => _currentState = PaymentConfirmationState.success);
        _loadingAnimationController.stop();
        _successAnimationController.forward();
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            context.go(AppRoutes.testLibraryDashboard);
          }
        });
      } else {
        setState(() {
          _currentState = PaymentConfirmationState.error;
          _errorMessage = "Erreur lors de l'activation du compte";
        });
      }
    } catch (e) {
      setState(() {
        _currentState = PaymentConfirmationState.error;
        _errorMessage = 'Erreur technique: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _mainAnimationController.dispose();
    _successAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _retryVerification() {
    setState(() {
      _currentState = PaymentConfirmationState.verifying;
      _verificationAttempts = 0;
      _errorMessage = null;
    });
    _loadingAnimationController.repeat();
    _verifyPaymentStatus();
  }

  void _goToSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('Contacter le Support', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction ID: ${_paymentData?['transactionId'] ?? 'N/A'}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Contactez-nous:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('📧 support@psychotest.com', style: AppTextStyles.bodyMedium),
            Text('📱 +229 XX XX XX XX', style: AppTextStyles.bodyMedium),
            Text('⏰ Lundi-Vendredi 8h-18h', style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    context.go(AppRoutes.testLibraryDashboard);
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
              child: AnimatedBuilder(
                animation: _mainAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: _buildContent(padding),
                    ),
                  );
                },
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
                Text('Confirmation de Paiement', style: AppTextStyles.titleMedium),
                Text(
                  _getStateSubtitle(),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (_currentState == PaymentConfirmationState.success ||
              _currentState == PaymentConfirmationState.error)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.primary),
                onPressed: _goToHome,
              ),
            ),
        ],
      ),
    );
  }

  String _getStateSubtitle() {
    switch (_currentState) {
      case PaymentConfirmationState.verifying:
        return 'Vérification en cours';
      case PaymentConfirmationState.success:
        return 'Paiement confirmé';
      case PaymentConfirmationState.error:
        return 'Problème détecté';
      case PaymentConfirmationState.timeout:
        return 'Vérification en attente';
    }
  }

  Widget _buildContent(EdgeInsets padding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          _buildMainStateWidget(),
          const SizedBox(height: AppSpacing.xxl),
          if (_paymentData != null) _buildTransactionInfo(),
          const SizedBox(height: AppSpacing.xl),
          _buildActionButtons(),
          const SizedBox(height: AppSpacing.xxl),
          _buildHelpInfo(),
          SizedBox(height: padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMainStateWidget() {
    switch (_currentState) {
      case PaymentConfirmationState.verifying:
        return _buildVerifyingWidget();
      case PaymentConfirmationState.success:
        return _buildSuccessWidget();
      case PaymentConfirmationState.error:
        return _buildErrorWidget();
      case PaymentConfirmationState.timeout:
        return _buildTimeoutWidget();
    }
  }

  Widget _buildVerifyingWidget() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.sync_rounded, size: 56, color: AppColors.primary),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Vérification du paiement...', style: AppTextStyles.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nous vérifions votre paiement mobile money.\nCela peut prendre quelques instants.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tentative ${_verificationAttempts + 1}/$maxVerificationAttempts',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSuccessWidget() {
    return AnimatedBuilder(
      animation: _successAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_successAnimationController.value * 0.2),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successContainer,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Paiement confirmé !',
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Félicitations ! Votre compte Premium a été activé avec succès.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Vous avez maintenant accès à tous les tests premium !',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.errorContainer,
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Problème de paiement',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage ?? 'Une erreur est survenue lors du traitement de votre paiement.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeoutWidget() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentContainer,
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.schedule_rounded, size: 64, color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Vérification en cours',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Votre paiement est en cours de traitement. Vous recevrez une confirmation par SMS.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionInfo() {
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
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Détails de la transaction', style: AppTextStyles.titleMedium),
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
                _buildInfoRow(
                  'Montant',
                  _subscriptionService.formatPrice(
                    _paymentData!['amount']?.toDouble() ?? SubscriptionService.premiumPrice,
                  ),
                ),
                _buildInfoRow('Méthode', _getPaymentMethodName(_paymentData!['paymentMethod'])),
                _buildInfoRow('Téléphone', _paymentData!['phoneNumber'] ?? 'N/A'),
                _buildInfoRow('Transaction', _paymentData!['transactionId'] ?? 'N/A'),
                if (_paymentData!['timestamp'] != null)
                  _buildInfoRow('Date', _formatDateTime(_paymentData!['timestamp'])),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_currentState) {
      case PaymentConfirmationState.verifying:
        return const SizedBox.shrink();
      case PaymentConfirmationState.success:
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
              onPressed: _goToHome,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              label: Text('Continuer', style: AppTextStyles.buttonLarge.copyWith(color: Colors.white)),
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
      case PaymentConfirmationState.error:
        return Column(
          children: [
            SizedBox(
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
                  onPressed: _retryVerification,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  label: Text('Réessayer', style: AppTextStyles.buttonLarge.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _goToSupport,
                icon: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 22),
                label: Text('Contacter le Support', style: AppTextStyles.buttonLarge.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
              ),
            ),
          ],
        );
      case PaymentConfirmationState.timeout:
        return Column(
          children: [
            SizedBox(
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
                  onPressed: _retryVerification,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  label: Text('Vérifier à nouveau', style: AppTextStyles.buttonLarge.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _goToHome,
                icon: const Icon(Icons.home_rounded, color: AppColors.primary, size: 22),
                label: Text("Retour à l'accueil", style: AppTextStyles.buttonLarge.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHelpInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
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
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Besoin d\'aide ?', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '• Si votre paiement a été débité mais le Premium n\'est pas activé, contactez-nous\n'
            '• Gardez votre ID de transaction pour toute assistance\n'
            '• Le support est disponible 24/7 pour vous aider',
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String? methodId) {
    switch (methodId) {
      case 'orange_money':
        return 'Orange Money';
      case 'mtn_money':
        return 'MTN Mobile Money';
      case 'moov_money':
        return 'Moov Money';
      case 'wave':
        return 'Wave';
      case 'free_money':
        return 'Free Money';
      default:
        return methodId ?? 'Mobile Money';
    }
  }

  String _formatDateTime(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}

enum PaymentConfirmationState {
  verifying,
  success,
  error,
  timeout,
}
