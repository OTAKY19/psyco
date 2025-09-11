import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TrialInfoWidget extends StatelessWidget {
  final int daysRemaining;

  const TrialInfoWidget({
    super.key,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'schedule',
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Essai gratuit',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                      ),
                      Text(
                        '$daysRemaining jour${daysRemaining > 1 ? 's' : ''} restant${daysRemaining > 1 ? 's' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(1.5.h),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .tertiary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info_outline',
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Informations sur l\'essai',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Accès complet à toutes les fonctionnalités Premium\n'
                    '• Aucun frais pendant la période d\'essai\n'
                    '• Annulation possible à tout moment\n'
                    '• Facturation automatique après l\'essai',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(1.h),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.tertiary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vous pouvez annuler votre abonnement à tout moment dans les paramètres de votre compte.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}