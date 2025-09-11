import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Écran de confirmation de paiement et d'activation du compte premium
class PaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentResult;

  const PaymentConfirmationScreen({
    super.key,
    this.paymentResult,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
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
  static const int maxVerificationAttempts = 6; // 60 secondes max

  @override
  void initState() {
    super.initState();
    _paymentData = widget.paymentResult;
    _initializeAnimations();
    _startPaymentVerification();
  }

  void _initializeAnimations() {
    // Animation principale
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de succès
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animation de chargement
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.2, 1.0),
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.linear,
      ),
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
      
      // Vérifier le statut du paiement
      final statusResult = await _subscriptionService.checkPaymentStatus(transactionId);
      
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
          _errorMessage = 'Délai d\'attente dépassé. Contactez le support.';
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
      if (mounted) {
        _verifyPaymentStatus();
      }
    });
  }

  Future<void> _activatePremiumAccount() async {
    try {
      final success = await _subscriptionService.activatePremiumAccount(
        transactionId: _paymentData!['transactionId'],
        paymentMethod: _paymentData!['paymentMethod'],
      );
      
      if (success) {
        setState(() {
          _currentState = PaymentConfirmationState.success;
        });
        _loadingAnimationController.stop();
        _successAnimationController.forward();
        
        // Naviguer vers l'écran principal après 3 secondes
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.testLibraryDashboard,
              (route) => false,
            );
          }
        });
      } else {
        setState(() {
          _currentState = PaymentConfirmationState.error;
          _errorMessage = 'Erreur lors de l\'activation du compte';
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
    // Ici, vous pourriez ouvrir un chat, email ou téléphone de support
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${_paymentData?['transactionId'] ?? 'N/A'}'),
            SizedBox(height: 2.h),
            const Text('Contactez-nous:'),
            const Text('📧 support@douanetest.pro'),
            const Text('📱 +229 XX XX XX XX'),
            const Text('⏰ Lundi-Vendredi 8h-18h'),
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
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.testLibraryDashboard,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de Paiement'),
        automaticallyImplyLeading: false,
        actions: [
          if (_currentState == PaymentConfirmationState.success ||
              _currentState == PaymentConfirmationState.error)
            IconButton(
              onPressed: _goToHome,
              icon: const CustomIconWidget(iconName: 'close'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _mainAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.h),
      child: Column(
        children: [
          SizedBox(height: 4.h),
          
          // État principal
          _buildMainStateWidget(),
          
          SizedBox(height: 4.h),
          
          // Informations de transaction
          if (_paymentData != null) _buildTransactionInfo(),
          
          SizedBox(height: 3.h),
          
          // Boutons d'action
          _buildActionButtons(),
          
          SizedBox(height: 4.h),
          
          // Informations d'aide
          _buildHelpInfo(),
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
                width: 15.h,
                height: 15.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sync,
                  size: 6.h,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 3.h),
        Text(
          'Vérification du paiement...',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Nous vérifions votre paiement mobile money.\nCela peut prendre quelques instants.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        LinearProgressIndicator(
          backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Tentative ${_verificationAttempts + 1}/$maxVerificationAttempts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
                width: 15.h,
                height: 15.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 8.h,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Paiement confirmé !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Félicitations ! Votre compte Premium a été activé avec succès.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(1.5.h),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 4.h,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Vous avez maintenant accès à tous les tests premium !',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
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
          width: 15.h,
          height: 15.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.errorContainer,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.error_outline,
            size: 8.h,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Problème de paiement',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          _errorMessage ?? 'Une erreur est survenue lors du traitement de votre paiement.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeoutWidget() {
    return Column(
      children: [
        Container(
          width: 15.h,
          height: 15.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondaryContainer,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.schedule,
            size: 8.h,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Vérification en cours',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Votre paiement est en cours de traitement. Vous recevrez une confirmation par SMS.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionInfo() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la transaction',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildInfoRow('Montant', _subscriptionService.formatPrice(
            _paymentData!['amount']?.toDouble() ?? SubscriptionService.premiumPrice
          )),
          _buildInfoRow('Méthode', _getPaymentMethodName(_paymentData!['paymentMethod'])),
          _buildInfoRow('Téléphone', _paymentData!['phoneNumber'] ?? 'N/A'),
          _buildInfoRow('Transaction', _paymentData!['transactionId'] ?? 'N/A'),
          if (_paymentData!['timestamp'] != null)
            _buildInfoRow('Date', _formatDateTime(_paymentData!['timestamp'])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
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
          child: ElevatedButton.icon(
            onPressed: _goToHome,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuer'),
          ),
        );
      case PaymentConfirmationState.error:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retryVerification,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToSupport,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                ),
                icon: const Icon(Icons.support_agent),
                label: const Text('Contacter le Support'),
              ),
            ),
          ],
        );
      case PaymentConfirmationState.timeout:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retryVerification,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Vérifier à nouveau'),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _goToHome,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                ),
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildHelpInfo() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 2.5.h,
              ),
              SizedBox(width: 2.w),
              Text(
                'Besoin d\'aide ?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '• Si votre paiement a été débité mais le Premium n\'est pas activé, contactez-nous\n'
            '• Gardez votre ID de transaction pour toute assistance\n'
            '• Le support est disponible 24/7 pour vous aider',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
