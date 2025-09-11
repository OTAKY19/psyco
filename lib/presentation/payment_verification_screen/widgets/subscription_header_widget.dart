import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class SubscriptionHeaderWidget extends StatelessWidget {
  final String selectedPlan;
  final ValueChanged<String> onPlanChanged;

  const SubscriptionHeaderWidget({
    super.key,
    required this.selectedPlan,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.workspace_premium,
          size: 15.w,
          color: Theme.of(context).colorScheme.tertiary,
        ),

        SizedBox(height: 2.h),

        Text(
          'DouaneTest Pro Premium',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 1.h),

        Text(
          'Accédez à tous les tests et fonctionnalités avancées',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 3.h),

        // Plan selection
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPlanOption(
                context,
                id: 'monthly',
                title: 'Mensuel',
                price: '9,99€',
                period: 'par mois',
                isPopular: false,
              ),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
              _buildPlanOption(
                context,
                id: 'yearly',
                title: 'Annuel',
                price: '99,99€',
                period: 'par an',
                originalPrice: '119,88€',
                discount: 'Économisez 17%',
                isPopular: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption(
    BuildContext context, {
    required String id,
    required String title,
    required String price,
    required String period,
    String? originalPrice,
    String? discount,
    required bool isPopular,
  }) {
    final isSelected = selectedPlan == id;

    return InkWell(
      onTap: () => onPlanChanged(id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: id,
              groupValue: selectedPlan,
              onChanged: (value) {
                if (value != null) {
                  onPlanChanged(value);
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (isPopular) ...[
                        SizedBox(width: 2.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'POPULAIRE',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (originalPrice != null) ...[
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Text(
                          originalPrice,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          discount!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
