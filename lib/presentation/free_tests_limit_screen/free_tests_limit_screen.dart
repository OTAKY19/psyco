import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Écran affiché quand l'utilisateur a épuisé ses tests gratuits
class FreeTestsLimitScreen extends StatefulWidget {
  const FreeTestsLimitScreen({super.key});

  @override
  State<FreeTestsLimitScreen> createState() => _FreeTestsLimitScreenState();
}

class _FreeTestsLimitScreenState extends State<FreeTestsLimitScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final SubscriptionService _subscriptionService = SubscriptionService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSubscriptionInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0),
      ),
    );

    _animationController.forward();
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToPremium() {
    Navigator.pushNamed(context, AppRoutes.mobileMoneyPayment);
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limite Atteinte'),
        leading: IconButton(
          onPressed: _goBack,
          icon: const CustomIconWidget(iconName: 'arrow_back'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _animationController,
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
          SizedBox(height: 2.h),
          
          // Icône principale
          Container(
            width: 20.h,
            height: 20.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.errorContainer,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.lock_clock_outlined,
              size: 8.h,
              color: Theme.of(context).colorScheme.error,
            ),
          ),

          SizedBox(height: 4.h),

          // Titre principal
          Text(
            'Tests gratuits épuisés',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 2.h),

          // Sous-titre
          Text(
            'Vous avez utilisé vos ${_subscriptionInfo?['freeTestsUsed'] ?? 3} tests gratuits.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          Text(
            'Passez au premium pour continuer à vous entraîner !',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // Statistiques
          _buildStatsCards(),

          SizedBox(height: 4.h),

          // Avantages premium
          _buildPremiumBenefits(),

          SizedBox(height: 4.h),

          // Prix et bouton d'achat
          _buildPricingSection(),

          SizedBox(height: 3.h),

          // Bouton retour
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _goBack,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
              ),
              child: Text(
                'Retour',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final testsUsed = _subscriptionInfo?['freeTestsUsed'] ?? 0;
    final testsTotal = SubscriptionService.maxFreeTests;

    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(2.h),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Votre progression',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tests utilisés',
                  '$testsUsed',
                  Icons.quiz_outlined,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  'Tests restants',
                  '${testsTotal - testsUsed}',
                  Icons.lock_outline,
                  Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: testsUsed / testsTotal,
            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.error,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$testsUsed/$testsTotal tests gratuits utilisés',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(1.5.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(1.5.h),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 3.h,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefits() {
    final benefits = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Tests illimités',
        'description': 'Entraînez-vous autant que vous voulez',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Statistiques avancées',
        'description': 'Suivez vos progrès en détail',
      },
      {
        'icon': Icons.psychology,
        'title': 'Analyses personnalisées',
        'description': 'Recevez des conseils adaptés',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Support prioritaire',
        'description': 'Aide rapide quand vous en avez besoin',
      },
    ];

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
        borderRadius: BorderRadius.circular(2.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 3.h,
              ),
              SizedBox(width: 2.w),
              Text(
                'Avantages Premium',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...benefits.map((benefit) => Padding(
                padding: EdgeInsets.only(bottom: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(1.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        benefit['icon'] as IconData,
                        color: Theme.of(context).colorScheme.primary,
                        size: 2.5.h,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit['title'] as String,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            benefit['description'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    final price = _subscriptionService.formatPrice(SubscriptionService.premiumPrice);
    
    return Container(
      padding: EdgeInsets.all(2.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(2.h),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Prix spécial',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(1.h),
                ),
                child: Text(
                  'LIMITÉ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            price,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Paiement unique • Accès à vie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToPremium,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              icon: Icon(Icons.lock_open_rounded, size: 2.5.h),
              label: Text(
                'Débloquer Premium',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
