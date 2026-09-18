import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_routes.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../services/activation_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final ActivationService _activationService = ActivationService();

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          _buildCurrentStatus(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildPlanDetails(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildFeaturesList(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildActionSection(),
                          SizedBox(height: padding.bottom + AppSpacing.xxl),
                        ],
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mon Activation', style: AppTextStyles.titleMedium),
                Text(
                  'Gérez votre abonnement',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final isActivated = _activationStatus['is_activated'] ?? false;
    final remainingDays = _activationStatus['remaining_days'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActivated
              ? [AppColors.successContainer, AppColors.successContainer.withValues(alpha: 0.5)]
              : [AppColors.errorContainer, AppColors.errorContainer.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isActivated
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActivated ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  isActivated ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActivated ? 'Activation Active' : 'Activation Expirée',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isActivated ? AppColors.successDark : AppColors.errorDark,
                      ),
                    ),
                    if (_currentSubscription != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _currentSubscription!['name'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isActivated && remainingDays > 0) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '$remainingDays jours restants',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPlanDetails() {
    final isActivated = _activationStatus['is_activated'] ?? false;

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
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Détails du plan', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildDetailRow('Plan', 'PsychoTest+ Premium'),
          _buildDetailRow('Prix', '3 000 FCFA (~2,3€)'),
          _buildDetailRow('Type', 'Achat unique'),
          _buildDetailRow('Durée', 'Accès à vie'),
          _buildDetailRow('Statut', isActivated ? 'Actif' : 'Inactif'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Accès à toutes les 40 questions par test',
      'Résultats détaillés et analyses complètes',
      'Statistiques de performance avancées',
      'Mode hors-ligne complet',
      'Sauvegarde automatique des progrès',
      'Support technique prioritaire',
      'Mises à jour gratuites à vie',
    ];

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
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Fonctionnalités incluses', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(top: 1, right: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 14),
                  ),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    final isActivated = _activationStatus['is_activated'] ?? false;

    if (isActivated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Votre activation est active. Profitez de toutes les fonctionnalités premium.',
                style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

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
              onPressed: () {
                context.push(AppRoutes.activation);
              },
              icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 22),
              label: Text(
                'Activer PsychoTest+',
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
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '3 000 FCFA • Achat unique • Accès à vie',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
