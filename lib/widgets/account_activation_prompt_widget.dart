import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/subscription_service.dart';

/// Widget pour suggérer l'activation du compte après un test
class AccountActivationPromptWidget extends StatefulWidget {
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onDismiss;
  final bool showUpgradeButton;
  
  const AccountActivationPromptWidget({
    super.key,
    this.onUpgradePressed,
    this.onDismiss,
    this.showUpgradeButton = true,
  });

  @override
  State<AccountActivationPromptWidget> createState() => _AccountActivationPromptWidgetState();
}

class _AccountActivationPromptWidgetState extends State<AccountActivationPromptWidget>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadSubscriptionInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final info = await _subscriptionService.getSubscriptionInfo();
      setState(() {
        _subscriptionInfo = info;
        _isLoading = false;
      });
      
      // Démarrer l'animation
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isPremium = _subscriptionInfo?['isPremium'] ?? false;
    
    // Ne pas afficher si l'utilisateur est déjà premium
    if (isPremium) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPromptContent(),
          ),
        );
      },
    );
  }

  Widget _buildPromptContent() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône de suggestion
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              size: 12.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          
          SizedBox(height: 3.h),
          
          // Titre
          Text(
            'Débloquez tout le potentiel !',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 2.h),
          
          // Description
          Text(
            'Vous avez utilisé vos 2 tests gratuits. Passez au Premium pour accéder à tous les tests et fonctionnalités avancées !',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 3.h),
          
          // Avantages Premium
          _buildPremiumBenefits(),
          
          SizedBox(height: 3.h),
          
          // Boutons d'action
          Row(
            children: [
              // Bouton Fermer
              OutlinedButton(
                onPressed: widget.onDismiss ?? () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  side: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Plus tard',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Bouton Upgrade
              if (widget.showUpgradeButton)
                ElevatedButton(
                  onPressed: widget.onUpgradePressed ?? _onUpgradePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Passer au Premium',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefits() {
    final benefits = [
      {
        'icon': Icons.all_inclusive,
        'text': 'Accès illimité à tous les tests',
      },
      {
        'icon': Icons.analytics,
        'text': 'Statistiques détaillées',
      },
      {
        'icon': Icons.download,
        'text': 'Téléchargements hors ligne',
      },
      {
        'icon': Icons.priority_high,
        'text': 'Support prioritaire',
      },
    ];

    return Column(
      children: benefits.map((benefit) => Container(
        margin: EdgeInsets.only(bottom: 1.h),
        child: Row(
          children: [
            Icon(
              benefit['icon'] as IconData,
              size: 5.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                benefit['text'] as String,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _onUpgradePressed() {
    Navigator.of(context).pop();
    // Naviguer vers l'écran de paiement
    Navigator.pushNamed(context, AppRoutes.mobileMoneyPayment);
  }
}

/// Fonction utilitaire pour afficher le prompt d'activation
Future<void> showAccountActivationPrompt(
  BuildContext context, {
  VoidCallback? onUpgradePressed,
  VoidCallback? onDismiss,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: AccountActivationPromptWidget(
        onUpgradePressed: onUpgradePressed,
        onDismiss: onDismiss,
      ),
    ),
  );
}
