import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/subscription_service.dart';
import '../../services/payment_service.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final PaymentService _paymentService = PaymentService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  String _selectedPaymentMethod = 'mobile_money';
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé de la commande
              _buildOrderSummary(),
              
              SizedBox(height: 24),
              
              // Méthodes de paiement
              _buildPaymentMethods(),
              
              SizedBox(height: 24),
              
              // Informations de paiement
              _buildPaymentInfo(),
              
              SizedBox(height: 32),
              
              // Bouton de paiement
              _buildPaymentButton(),
              
              SizedBox(height: 16),
              
              // Sécurité
              _buildSecurityInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la commande',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activation de l\'application'),
                Text('${widget.amount.toStringAsFixed(0)} FCFA'),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.amount.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildPaymentMethodCard(
          'mobile_money',
          'Mobile Money',
          'Paiement via Mobile Money (MTN, Orange, Moov)',
          Icons.phone_android,
          Colors.blue,
        ),
        SizedBox(height: 12),
        _buildPaymentMethodCard(
          'bank_transfer',
          'Virement bancaire',
          'Transfert bancaire direct',
          Icons.account_balance,
          Colors.green,
        ),
        SizedBox(height: 12),
        _buildPaymentMethodCard(
          'cash',
          'Paiement en espèces',
          'Paiement en espèces (points de vente)',
          Icons.money,
          Colors.orange,
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
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.grey[800],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de paiement',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildInfoRow('Montant', '${widget.amount.toStringAsFixed(0)} FCFA'),
            _buildInfoRow('Description', widget.description),
            _buildInfoRow('Méthode', _getPaymentMethodLabel()),
            _buildInfoRow('Statut', 'En attente'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _processPayment,
        icon: _isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.payment, size: 24),
        label: Text(
          _isProcessing ? 'Traitement...' : 'Payer maintenant',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Paiement sécurisé et crypté. Vos informations sont protégées.',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.green[800],
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
      _error = null;
    });

    try {
      // Simuler le processus de paiement
      final result = await _paymentService.processPayment(
        amount: widget.amount,
        method: _selectedPaymentMethod,
        description: widget.description,
      );

      if (result['success']) {
        // Activer le compte premium
        final activationSuccess = await _subscriptionService.activatePremiumAccount(
          transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          amount: SubscriptionService.premiumPrice.toDouble(),
        );

        if (activationSuccess) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('Erreur lors de l\'activation du compte');
        }
      } else {
        _showErrorDialog(result['error'] ?? 'Erreur de paiement');
      }
    } catch (e) {
      _showErrorDialog('Erreur: $e');
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
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Paiement réussi !'),
          ],
        ),
        content: Text('Votre compte a été activé avec succès. Vous pouvez maintenant accéder à toutes les fonctionnalités premium.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onPaymentSuccess();
            },
            child: Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur de paiement'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
