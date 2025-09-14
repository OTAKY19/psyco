import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PremiumSubscriptionWidget extends StatelessWidget {
  final bool isPremium;
  final String? currentPlan;
  final String? renewalDate;
  final VoidCallback onUpgradePressed;

  const PremiumSubscriptionWidget({
    super.key,
    required this.isPremium,
    this.currentPlan,
    this.renewalDate,
    required this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.1),
                  AppTheme.lightTheme.colorScheme.tertiary
                      .withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPremium ? null : AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isPremium
            ? Border.all(
                color: AppTheme.lightTheme.colorScheme.tertiary
                    .withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isPremium
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: isPremium ? 'star' : 'workspace_premium',
                  color: isPremium
                      ? Colors.white
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? 'Abonnement Premium' : 'Passer au Premium',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPremium
                            ? AppTheme.lightTheme.colorScheme.tertiary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    if (isPremium && currentPlan != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        currentPlan!,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (isPremium) ...[
            _buildPremiumInfo(),
          ] else ...[
            _buildUpgradeInfo(),
          ],
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.tertiary,
                foregroundColor: isPremium
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    : Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isPremium ? 'Gérer l\'abonnement' : 'Débloquer Premium',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPremium
                      ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Text(
              'Accès illimité à tous les tests',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Text(
              'Analyses détaillées des performances',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (renewalDate != null) ...[
          SizedBox(height: 1.h),
          Text(
            'Renouvellement: $renewalDate',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpgradeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Débloquez toutes les fonctionnalités:',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'star_outline',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                '110+ tests psychotechniques',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'star_outline',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Mode simulation avec questions aléatoires',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: 'star_outline',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Accès hors ligne et certificats',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
