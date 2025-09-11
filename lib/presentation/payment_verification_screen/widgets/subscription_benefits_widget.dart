import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SubscriptionBenefitsWidget extends StatelessWidget {
  const SubscriptionBenefitsWidget({super.key});

  static const List<Map<String, dynamic>> _benefits = [
    {
      'icon': Icons.quiz_outlined,
      'title': 'Tests illimités',
      'description': 'Accès complet à tous les tests et quiz',
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Analyses détaillées',
      'description': 'Statistiques avancées de performance',
    },
    {
      'icon': Icons.offline_bolt_outlined,
      'title': 'Mode hors ligne',
      'description': 'Étudiez sans connexion internet',
    },
    {
      'icon': Icons.school_outlined,
      'title': 'Contenu premium',
      'description': 'Cours exclusifs et explications détaillées',
    },
    {
      'icon': Icons.support_agent_outlined,
      'title': 'Support prioritaire',
      'description': 'Assistance dédiée 24/7',
    },
    {
      'icon': Icons.cloud_sync_outlined,
      'title': 'Synchronisation',
      'description': 'Accès sur tous vos appareils',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fonctionnalités Premium',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(2.h),
            child: Column(
              children: _benefits.map((benefit) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Row(
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: _getIconName(benefit['icon']),
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              benefit['title'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              benefit['description'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'check_circle',
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 6.w,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Add this helper method at the end of the class
  String _getIconName(IconData iconData) {
    // Map IconData to string names for CustomIconWidget
    final Map<IconData, String> iconDataToStringMap = {
      Icons.quiz_outlined: 'quiz',
      Icons.analytics_outlined: 'analytics', 
      Icons.offline_bolt_outlined: 'offline_bolt',
      Icons.school_outlined: 'school',
      Icons.support_agent_outlined: 'support_agent',
      Icons.cloud_sync_outlined: 'cloud_sync',
    };
    
    return iconDataToStringMap[iconData] ?? 'help_outline';
  }
}