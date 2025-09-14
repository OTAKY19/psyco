import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../services/subscription_service.dart';
import '../core/app_export.dart';

/// Widget pour afficher les limitations de tests et le statut premium
class TestLimitationsWidget extends StatefulWidget {
  final VoidCallback? onUpgradePressed;
  final bool showUpgradeButton;
  
  const TestLimitationsWidget({
    super.key,
    this.onUpgradePressed,
    this.showUpgradeButton = true,
  });

  @override
  State<TestLimitationsWidget> createState() => _TestLimitationsWidgetState();
}

class _TestLimitationsWidgetState extends State<TestLimitationsWidget> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final info = await _subscriptionService.getSubscriptionInfo();
      setState(() {
        _subscriptionInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(2.h),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final isPremium = _subscriptionInfo?['isPremium'] ?? false;
    
    if (isPremium) {
      return _buildPremiumWidget();
    } else {
      return _buildFreeUserWidget();
    }
  }

  Widget _buildPremiumWidget() {
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(1.5.h),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 2.5.h,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Actif',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Tests illimités • Accès complet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha:0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 3.h,
          ),
        ],
      ),
    );
  }

  Widget _buildFreeUserWidget() {
    final freeTestsRemaining = _subscriptionInfo?['freeTestsRemaining'] ?? 0;
    final freeTestsUsed = _subscriptionInfo?['freeTestsUsed'] ?? 0;
    final totalFreeTests = SubscriptionService.maxFreeTests;

    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(1.5.h),
        border: Border.all(
          color: freeTestsRemaining > 0 
              ? Theme.of(context).colorScheme.primary.withValues(alpha:0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha:0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha:0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(1.h),
                decoration: BoxDecoration(
                  color: freeTestsRemaining > 0 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha:0.1)
                      : Theme.of(context).colorScheme.error.withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  freeTestsRemaining > 0 ? Icons.quiz_outlined : Icons.lock_outline,
                  color: freeTestsRemaining > 0 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  size: 2.5.h,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      freeTestsRemaining > 0 
                          ? 'Tests gratuits restants'
                          : 'Tests gratuits épuisés',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: freeTestsRemaining > 0 
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Text(
                      '$freeTestsUsed/$totalFreeTests utilisés',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: freeTestsRemaining > 0 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(1.h),
                ),
                child: Text(
                  freeTestsRemaining.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 1.5.h),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(0.5.h),
            child: LinearProgressIndicator(
              value: freeTestsUsed / totalFreeTests,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha:0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                freeTestsRemaining > 0 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
              minHeight: 0.8.h,
            ),
          ),
          
          if (widget.showUpgradeButton) ...[
            SizedBox(height: 2.h),
            
            // Bouton d'upgrade
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onUpgradePressed ?? _defaultUpgradeAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: freeTestsRemaining > 0 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.2.h),
                ),
                icon: Icon(
                  freeTestsRemaining > 0 ? Icons.upgrade : Icons.lock_open,
                  size: 2.h,
                ),
                label: Text(
                  freeTestsRemaining > 0 
                      ? 'Passer au Premium'
                      : 'Débloquer Maintenant',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _defaultUpgradeAction() {
    final freeTestsRemaining = _subscriptionInfo?['freeTestsRemaining'] ?? 0;
    
    if (freeTestsRemaining <= 0) {
      // Si plus de tests gratuits, aller directement à l'écran de limite
      Navigator.pushNamed(context, AppRoutes.freeTestsLimit);
    } else {
      // Sinon, aller à l'écran de paiement
      Navigator.pushNamed(context, AppRoutes.mobileMoneyPayment);
    }
  }
}

/// Version compacte du widget pour utilisation dans les en-têtes
class CompactTestLimitationsWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactTestLimitationsWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: SubscriptionService().getSubscriptionInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final subscriptionInfo = snapshot.data!;
        final isPremium = subscriptionInfo['isPremium'] ?? false;
        
        if (isPremium) {
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.tertiaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(2.h),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.primary,
                    size: 2.h,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Premium',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          final freeTestsRemaining = subscriptionInfo['freeTestsRemaining'] ?? 0;
          
          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: freeTestsRemaining > 0 
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context).colorScheme.errorContainer.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(2.h),
                border: Border.all(
                  color: freeTestsRemaining > 0 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha:0.3)
                      : Theme.of(context).colorScheme.error.withValues(alpha:0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    freeTestsRemaining > 0 ? Icons.quiz_outlined : Icons.lock_outline,
                    color: freeTestsRemaining > 0 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    size: 2.h,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$freeTestsRemaining gratuit${freeTestsRemaining > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: freeTestsRemaining > 0 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
