import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/payment_method_widget.dart';
import './widgets/price_comparison_widget.dart';
import './widgets/security_badges_widget.dart';
import './widgets/subscription_benefits_widget.dart';
import './widgets/subscription_header_widget.dart';
import './widgets/trial_info_widget.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({super.key});

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  String _selectedPlan = 'monthly';
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  bool _hasExistingSubscription = false;
  int _trialDaysRemaining = 7;

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingSubscription();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _checkExistingSubscription() {
    // Simulate checking for existing subscription
    // This would normally check with your payment provider
  }

  Future<void> _processPayment() async {
    if (!_validatePaymentForm()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      if (_selectedPaymentMethod == 'apple_pay' && !kIsWeb) {
        await _processApplePay();
      } else if (_selectedPaymentMethod == 'google_pay' && !kIsWeb) {
        await _processGooglePay();
      } else {
        await _processCreditCard();
      }

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Erreur de paiement: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processApplePay() async {
    // Apple Pay implementation would go here
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processGooglePay() async {
    // Google Pay implementation would go here
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _processCreditCard() async {
    // Credit card processing would go here
    await Future.delayed(const Duration(seconds: 2));
  }

  bool _validatePaymentForm() {
    if (_selectedPaymentMethod == 'card') {
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty ||
          _nameController.text.isEmpty) {
        _showErrorDialog('Veuillez remplir tous les champs de paiement');
        return false;
      }
    }
    return true;
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate restore purchases
      await Future.delayed(const Duration(seconds: 2));

      _showInfoDialog(
        'Restauration terminée',
        'Aucun achat précédent trouvé pour ce compte.',
      );
    } catch (e) {
      _showErrorDialog('Erreur lors de la restauration: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.tertiary,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'Paiement réussi !',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Bienvenue dans DouaneTest Pro Premium',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.testLibraryDashboard,
                (route) => false,
              );
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Erreur',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement Premium'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const CustomIconWidget(iconName: 'close'),
        ),
        actions: [
          TextButton(
            onPressed: _restorePurchases,
            child: Text(
              'Restaurer',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubscriptionHeaderWidget(
              selectedPlan: _selectedPlan,
              onPlanChanged: (plan) {
                setState(() {
                  _selectedPlan = plan;
                });
              },
            ),
            SizedBox(height: 3.h),
            SubscriptionBenefitsWidget(),
            SizedBox(height: 3.h),
            PriceComparisonWidget(),
            SizedBox(height: 3.h),
            if (_trialDaysRemaining > 0)
              TrialInfoWidget(daysRemaining: _trialDaysRemaining),
            if (_trialDaysRemaining > 0) SizedBox(height: 3.h),
            PaymentMethodWidget(
              selectedMethod: _selectedPaymentMethod,
              onMethodChanged: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              cardNumberController: _cardNumberController,
              expiryController: _expiryController,
              cvvController: _cvvController,
              nameController: _nameController,
            ),
            SizedBox(height: 3.h),
            SecurityBadgesWidget(),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          const Text('Traitement...'),
                        ],
                      )
                    : Text(
                        _trialDaysRemaining > 0
                            ? 'Commencer l\'essai gratuit'
                            : _selectedPlan == 'monthly'
                                ? 'S\'abonner - 9,99€/mois'
                                : 'S\'abonner - 99,99€/an',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'En continuant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité. L\'abonnement se renouvelle automatiquement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}