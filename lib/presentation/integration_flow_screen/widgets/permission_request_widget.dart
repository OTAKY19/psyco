import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class IntegrationPermissionRequestWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final String illustration;
  final Function(bool) onPermissionResult;

  const IntegrationPermissionRequestWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    required this.onPermissionResult,
  });

  @override
  State<IntegrationPermissionRequestWidget> createState() =>
      _IntegrationPermissionRequestWidgetState();
}

class _IntegrationPermissionRequestWidgetState
    extends State<IntegrationPermissionRequestWidget> {
  bool _notificationsRequested = false;
  bool _notificationsGranted = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 60.w,
            height: 30.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.w),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.w),
              child: CustomImageWidget(
                imageUrl: widget.illustration,
                width: 60.w,
                height: 30.h,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Title
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          SizedBox(height: 1.5.h),

          // Subtitle
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
          ),

          SizedBox(height: 3.h),

          // Description
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Text(
              widget.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          SizedBox(height: 4.h),

          // Permission benefits
          _buildBenefitsList(context),

          SizedBox(height: 4.h),

          // Permission buttons
          if (!_notificationsRequested)
            _buildPermissionButtons(context)
          else
            _buildPermissionStatus(context),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.schedule,
        'title': 'Rappels d\'étude personnalisés',
        'description': 'Recevez des notifications adaptées à votre rythme',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Conseils de progression',
        'description': 'Conseils pour améliorer vos performances',
      },
      {
        'icon': Icons.celebration,
        'title': 'Récompenses et achievements',
        'description': 'Célébrez vos succès et objectifs atteints',
      },
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: benefits.map((benefit) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  child: Icon(
                    benefit['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
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
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        benefit['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPermissionButtons(BuildContext context) {
    return Column(
      children: [
        // Allow button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _requestNotificationPermission,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Autoriser les Notifications'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Deny button
        TextButton(
          onPressed: _denyNotificationPermission,
          child: const Text('Plus tard'),
        ),

        SizedBox(height: 1.h),

        // Info text
        Text(
          'Vous pourrez modifier ce choix à tout moment dans les paramètres.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatus(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _notificationsGranted
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: _notificationsGranted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _notificationsGranted ? Icons.check_circle : Icons.info,
            color: _notificationsGranted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              _notificationsGranted
                  ? 'Notifications autorisées ! Vous recevrez des rappels personnalisés.'
                  : 'Notifications désactivées. Vous pouvez les activer plus tard dans les paramètres.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _notificationsGranted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _requestNotificationPermission() {
    setState(() {
      _notificationsRequested = true;
      _notificationsGranted = true;
    });

    widget.onPermissionResult(true);
  }

  void _denyNotificationPermission() {
    setState(() {
      _notificationsRequested = true;
      _notificationsGranted = false;
    });

    widget.onPermissionResult(false);
  }
}