import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IntegrationProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const IntegrationProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 0.6.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1.h),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                width:
                    progress * 100.w * 0.6, // Adjust based on available width
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.h),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 1.h),

        // Step counter and percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Étape ${currentStep + 1} sur $totalSteps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
