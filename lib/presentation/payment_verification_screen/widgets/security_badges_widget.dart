import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecurityBadgesWidget extends StatelessWidget {
  const SecurityBadgesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sécurité des paiements',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSecurityBadge(
              context,
              icon: Icons.security,
              text: 'SSL\nCrypté',
              color: Theme.of(context).colorScheme.tertiary,
            ),
            _buildSecurityBadge(
              context,
              icon: Icons.verified_user,
              text: 'PCI\nCompliant',
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildSecurityBadge(
              context,
              icon: Icons.lock,
              text: 'Paiement\nSécurisé',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(2.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CustomIconWidget(
                iconName: 'info_outline',
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Vos informations de paiement sont protégées par un cryptage de niveau bancaire. Nous ne stockons jamais vos données de carte.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 15.w,
          height: 15.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: CustomIconWidget(
            iconName: 'security',
            color: color,
            size: 6.w,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}