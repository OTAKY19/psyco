import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PriceComparisonWidget extends StatelessWidget {
  const PriceComparisonWidget({super.key});

  static const List<Map<String, dynamic>> _features = [
    {
      'title': 'Tests de base',
      'free': true,
      'premium': true,
    },
    {
      'title': 'Tests avancés',
      'free': false,
      'premium': true,
    },
    {
      'title': 'Analyses détaillées',
      'free': false,
      'premium': true,
    },
    {
      'title': 'Mode hors ligne',
      'free': false,
      'premium': true,
    },
    {
      'title': 'Support prioritaire',
      'free': false,
      'premium': true,
    },
    {
      'title': 'Contenu exclusif',
      'free': false,
      'premium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comparaison des formules',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(2.h),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Fonctionnalités',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Gratuit',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Premium',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Features list
                Column(
                  children: _features.map((feature) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              feature['title'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomIconWidget(
                                iconName: feature['free'] as bool
                                    ? 'check_circle'
                                    : 'close',
                                color: feature['free'] as bool
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.error,
                                size: 5.w,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: CustomIconWidget(
                                iconName: feature['premium'] as bool
                                    ? 'check_circle'
                                    : 'close',
                                color: feature['premium'] as bool
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.error,
                                size: 5.w,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 2.h),

                Divider(
                  color: Theme.of(context).colorScheme.outline,
                ),

                SizedBox(height: 1.h),

                // Pricing
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Prix',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Gratuit',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '9,99€',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'par mois',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}