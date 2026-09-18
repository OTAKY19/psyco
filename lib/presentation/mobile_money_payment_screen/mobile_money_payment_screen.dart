import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';

/// Écran de paiement mobile money
class MobileMoneyPaymentScreen extends StatefulWidget {
  const MobileMoneyPaymentScreen({super.key});

  @override
  State<MobileMoneyPaymentScreen> createState() => _MobileMoneyPaymentScreenState();
}

class _MobileMoneyPaymentScreenState extends State<MobileMoneyPaymentScreen>
    with TickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedPaymentMethod;
  bool _isProcessing = false;
  bool _showInstructions = false;
  List<Map<String, dynamic>> _paymentMethods = [];

  late AnimationController _instructionsAnimationController;
  late Animation<double> _instructionsAnimation;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _instructionsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _instructionsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _instructionsAnimationController, curve: Curves.easeInOut),
    );
  }

  void _loadPaymentMethods() {
    setState(() {
      _paymentMethods = _subscriptionService.getAvailablePaymentMethods();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _instructionsAnimationController.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
      _showInstructions = true;
    });
    _instructionsAnimationController.forward();
    _validateAndFormatPhoneNumber();
  }

  void _validateAndFormatPhoneNumber() {
    if (_selectedPaymentMethod == null || _phoneController.text.isEmpty) return;
    final phoneNumber = _phoneController.text;
    final isValid = _subscriptionService.isValidPhoneNumber(phoneNumber, _selectedPaymentMethod!);
    if (isValid) {
      final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.length >= 8) {
        final formatted = '${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5)}';
        _phoneController.value = _phoneController.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate() || _selectedPaymentMethod == null) {
      _showErrorSnackBar('Veuillez remplir tous les champs correctement');
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      final result = await _subscriptionService.processMobileMoneyPayment(
        amount: SubscriptionService.premiumPrice.toDouble(),
        phoneNumber: phoneNumber,
        paymentMethod: _selectedPaymentMethod!,
        description: 'Paiement Mobile Money',
      );
      if (result['success'] == true && mounted) {
        context.pushReplacement(
          AppRoutes.paymentConfirmation,
          extra: TestResultRouteExtra(paymentResult: result),
        );
      } else {
        _showErrorDialog('Échec du paiement', result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorDialog('Erreur', 'Une erreur est survenue lors du paiement: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text(title, style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
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

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre numéro de téléphone';
    if (_selectedPaymentMethod == null) return 'Veuillez sélectionner une méthode de paiement';
    final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!_subscriptionService.isValidPhoneNumber(phoneNumber, _selectedPaymentMethod!)) {
      final method = _paymentMethods.firstWhere((m) => m['id'] == _selectedPaymentMethod);
      return 'Numéro non valide pour ${method['name']}';
    }
    return null;
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxl),
                      _buildPriceHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildPaymentMethodsSection(),
                      if (_selectedPaymentMethod != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _buildPhoneNumberField(),
                      ],
                      if (_showInstructions && _selectedPaymentMethod != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _buildInstructionsSection(),
                      ],
                      if (_selectedPaymentMethod != null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _buildPaymentButton(),
                      ],
                      const SizedBox(height: AppSpacing.lg),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paiement Mobile Money', style: AppTextStyles.titleMedium),
                Text(
                  'Sélectionnez votre opérateur',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHeader() {
    final price = _subscriptionService.formatPrice(SubscriptionService.premiumPrice);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.ctaLg,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'PsychoTest+ Premium',
            style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            price,
            style: AppTextStyles.displayMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Paiement unique • Accès à vie',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisissez votre opérateur', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
          ),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            final method = _paymentMethods[index];
            final isSelected = _selectedPaymentMethod == method['id'];

            return GestureDetector(
              onTap: method['available'] ? () => _selectPaymentMethod(method['id']) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryContainer : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.cardSm : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(method['color']),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Icon(
                        _getPaymentIcon(method['id']),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      method['name'],
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!method['available']) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text('Bientôt', style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro ${selectedMethod['name']}',
          style: AppTextStyles.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            hintText: _getPhoneHint(_selectedPaymentMethod!),
            prefixIcon: Container(
              width: 56,
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(selectedMethod['color']),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(
                  _getPaymentIcon(_selectedPaymentMethod!),
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: _validatePhoneNumber,
          onChanged: (value) => _validateAndFormatPhoneNumber(),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    final selectedMethod = _paymentMethods.firstWhere(
      (method) => method['id'] == _selectedPaymentMethod,
    );

    return AnimatedBuilder(
      animation: _instructionsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _instructionsAnimation.value,
          child: Opacity(
            opacity: _instructionsAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: Color(selectedMethod['color']).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Instructions', style: AppTextStyles.titleSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    selectedMethod['instructions'],
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '• Assurez-vous d\'avoir suffisamment de solde\n'
                    '• Gardez votre téléphone à proximité\n'
                    '• Vous recevrez une notification de confirmation',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentButton() {
    final price = _subscriptionService.formatPrice(SubscriptionService.premiumPrice);

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
            _isProcessing ? 'Traitement en cours...' : 'Payer $price',
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
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Paiement sécurisé', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '• Toutes les transactions sont cryptées\n'
            '• Aucune information bancaire stockée\n'
            '• Paiement traité par nos partenaires certifiés\n'
            '• Support client disponible 24/7',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String methodId) {
    switch (methodId) {
      case 'orange_money':
        return Icons.phone_android_rounded;
      case 'mtn_money':
        return Icons.mobile_friendly_rounded;
      case 'moov_money':
        return Icons.smartphone_rounded;
      case 'wave':
        return Icons.waves_rounded;
      case 'free_money':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  String _getPhoneHint(String methodId) {
    switch (methodId) {
      case 'orange_money':
        return 'Ex: 07 123 456';
      case 'mtn_money':
        return 'Ex: 90 123 456';
      case 'moov_money':
        return 'Ex: 94 123 456';
      case 'wave':
        return 'Ex: 07 123 456';
      case 'free_money':
        return 'Ex: 04 123 456';
      default:
        return 'Entrez votre numéro';
    }
  }
}
