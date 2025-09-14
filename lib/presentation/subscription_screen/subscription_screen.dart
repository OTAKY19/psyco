import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/activation_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ActivationService _activationService = ActivationService();
  final PaymentService _paymentService = PaymentService();

  Map<String, dynamic>? _currentSubscription;
  Map<String, dynamic> _activationStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);

    try {
      _currentSubscription = await _activationService.getCurrentSubscription();
      _activationStatus = await _activationService.getActivationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Abonnement',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut actuel
                  _buildCurrentStatus(),
                  SizedBox(height: 5.w),
                  // Plans disponibles
                  _buildAvailablePlans(),
                  SizedBox(height: 5.w),
                  // Historique des paiements
                  _buildPaymentHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentStatus() {
    final isActivated = _activationStatus['is_activated'] ?? false;
    final remainingDays = _activationStatus['remaining_days'] ?? 0;

    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isActivated ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            isActivated ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActivated ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isActivated ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isActivated ? Icons.check_circle : Icons.cancel,
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
                      isActivated ? 'Abonnement Actif' : 'Abonnement Expiré',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isActivated ? Colors.green : Colors.red,
                      ),
                    ),
                    if (_currentSubscription != null) ...[
                      SizedBox(height: 1.w),
                      Text(
                        _currentSubscription!['name'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isActivated && remainingDays > 0) ...[
            SizedBox(height: 3.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.green,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '$remainingDays jours restants',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    final plans = _activationService.getAvailablePlans();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans Disponibles',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 3.w),
        ...plans.entries.map((entry) {
          final planId = entry.key;
          final plan = entry.value;

          return Container(
            margin: EdgeInsets.only(bottom: 3.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name'] as String,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 1.w),
                Text(
                  '${plan['price']} FCFA',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  'Fonctionnalités complètes et accès premium',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historique des Paiements',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 3.w),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.grey,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Aucun paiement enregistré',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
