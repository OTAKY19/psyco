import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class IntegrationOnboardingStepWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final String illustration;
  final bool isCompletion;
  final Map<String, dynamic>? userPreferences;

  const IntegrationOnboardingStepWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustration,
    this.isCompletion = false,
    this.userPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 70.w,
            height: 35.h,
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
                imageUrl: illustration,
                width: 70.w,
                height: 35.h,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          SizedBox(height: 1.5.h),

          // Subtitle
          Text(
            subtitle,
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
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),

          // Show preferences summary if this is completion step
          if (isCompletion && userPreferences != null)
            _buildPreferencesSummary(context),
        ],
      ),
    );
  }

  Widget _buildPreferencesSummary(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Vos préférences configurées :',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          SizedBox(height: 2.h),

          // Preferences list
          ...userPreferences!.entries.map((entry) {
            return _buildPreferenceItem(context, entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(BuildContext context, String key, dynamic value) {
    String displayKey = _getDisplayName(key);
    String displayValue = _getDisplayValue(value);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(
            _getPreferenceIcon(key),
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 2.w),
          Text(
            '$displayKey: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String key) {
    switch (key) {
      case 'notificationsEnabled':
        return 'Notifications';
      case 'studyPreferences':
        return 'Matières';
      case 'weeklyGoal':
        return 'Objectif hebdomadaire';
      default:
        return key;
    }
  }

  String _getDisplayValue(dynamic value) {
    if (value is bool) {
      return value ? 'Activées' : 'Désactivées';
    } else if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.toString();
    } else if (value is int) {
      return '$value tests/semaine';
    }
    return value.toString();
  }

  IconData _getPreferenceIcon(String key) {
    switch (key) {
      case 'notificationsEnabled':
        return Icons.notifications;
      case 'studyPreferences':
        return Icons.subject;
      case 'weeklyGoal':
        return Icons.flag;
      default:
        return Icons.settings;
    }
  }
}