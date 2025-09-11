import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';
import '../../models/payment_models.dart';
import '../../widgets/custom_icon_widget.dart';

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
      CurvedAnimation(
        parent: _instructionsAnimationController,
        curve: Curves.easeInOut,
      ),
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
    
    // Vérifier et pré-remplir le numéro si possible
    _validateAndFormatPhoneNumber();
  }

  void _validateAndFormatPhoneNumber() {
    if (_selectedPaymentMethod == null || _phoneController.text.isEmpty) return;
    
    final phoneNumber = _phoneController.text;
    final isValid = _subscriptionService.isValidPhoneNumber(phoneNumber, _selectedPaymentMethod!);
    
    if (isValid) {
      // Formater le numéro pour un affichage plus lisible
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
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Nettoyer le numéro de téléphone
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
      
      // Traiter le paiement
      final result = await _subscriptionService.processMobileMoneyPayment(
        phoneNumber: phoneNumber,
        paymentMethod: _selectedPaymentMethod!,
        amount: SubscriptionService.premiumPrice,
      );
      
      if (result['success'] == true) {
        // Paiement réussi, naviguer vers la confirmation
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.paymentConfirmation,
          arguments: result,
        );
      } else {
        _showErrorDialog('Échec du paiement', result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorDialog('Erreur', 'Une erreur est survenue lors du paiement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
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

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    
    if (_selectedPaymentMethod == null) {
      return 'Veuillez sélectionner une méthode de paiement';
    }
    
    final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (!_subscriptionService.isValidPhoneNumber(phoneNumber, _selectedPaymentMethod!)) {
      final method = _paymentMethods.firstWhere((m) => m['id'] == _selectedPaymentMethod);
      return 'Numéro non valide pour ${method['name']}';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Mobile Money'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const CustomIconWidget(iconName: 'arrow_back'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(2.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec prix
              _buildPriceHeader(),
              
              SizedBox(height: 3.h),
              
              // Sélection de la méthode de paiement
              _buildPaymentMethodsSection(),
              
              SizedBox(height: 3.h),
              
              // Champ numéro de téléphone
              if (_selectedPaymentMethod != null) ...[
                _buildPhoneNumberField(),
                SizedBox(height: 2.h),
              ],
              
              // Instructions
              if (_showInstructions && _selectedPaymentMethod != null) ...[
                _buildInstructionsSection(),
                SizedBox(height: 3.h),
              ],
              
              // Bouton de paiement
              if (_selectedPaymentMethod != null) ...[
                _buildPaymentButton(),
                SizedBox(height: 2.h),
              ],
              
              // Informations de sécurité
              _buildSecurityInfo(),
              
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    final price = _subscriptionService.formatPrice(SubscriptionService.premiumPrice);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(2.h),
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium,
            size: 4.h,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 1.h),
          Text(
            'DouaneTest Pro Premium',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            price,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Paiement unique • Accès à vie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez votre méthode de paiement',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.5,
          ),
          itemCount: _paymentMethods.length,
          itemBuilder: (context, index) {
            final method = _paymentMethods[index];
            final isSelected = _selectedPaymentMethod == method['id'];
            
            return GestureDetector(
              onTap: method['available'] ? () => _selectPaymentMethod(method['id']) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(1.5.h),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(1.5.h),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6.h,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Color(method['color']),
                        borderRadius: BorderRadius.circular(1.h),
                      ),
                      child: Icon(
                        _getPaymentIcon(method['id']),
                        color: Colors.white,
                        size: 3.h,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      method['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!method['available']) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        'Bientôt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
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
          'Numéro de téléphone ${selectedMethod['name']}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
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
              width: 12.w,
              alignment: Alignment.center,
              child: Container(
                width: 4.h,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Color(selectedMethod['color']),
                  borderRadius: BorderRadius.circular(0.5.h),
                ),
                child: Icon(
                  _getPaymentIcon(_selectedPaymentMethod!),
                  color: Colors.white,
                  size: 2.h,
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.h),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1.h),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
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
              padding: EdgeInsets.all(2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(1.5.h),
                border: Border.all(
                  color: Color(selectedMethod['color']).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                        size: 2.5.h,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Instructions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    selectedMethod['instructions'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Assurez-vous d\'avoir suffisamment de solde\n'
                    '• Gardez votre téléphone à proximité\n'
                    '• Vous recevrez une notification de confirmation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                    ),
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
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        icon: _isProcessing 
            ? SizedBox(
                width: 2.h,
                height: 2.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Icon(Icons.payment, size: 2.5.h),
        label: Text(
          _isProcessing ? 'Traitement en cours...' : 'Payer $price',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(1.5.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: Theme.of(context).colorScheme.primary,
                size: 2.5.h,
              ),
              SizedBox(width: 2.w),
              Text(
                'Paiement sécurisé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '• Toutes les transactions sont cryptées\n'
            '• Aucune information bancaire stockée\n'
            '• Paiement traité par nos partenaires certifiés\n'
            '• Support client disponible 24/7',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String methodId) {
    switch (methodId) {
      case 'orange_money':
        return Icons.phone_android;
      case 'mtn_money':
        return Icons.mobile_friendly;
      case 'moov_money':
        return Icons.smartphone;
      case 'wave':
        return Icons.waves;
      case 'free_money':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  String _getPhoneHint(String methodId) {
    switch (methodId) {
      case 'orange_money':
        return 'Ex: 07 123 456';
      case 'mtn_money':
        return 'Ex: 06 123 456';
      case 'moov_money':
        return 'Ex: 05 123 456';
      case 'wave':
        return 'Ex: 07 123 456';
      case 'free_money':
        return 'Ex: 04 123 456';
      default:
        return 'Entrez votre numéro';
    }
  }
}
