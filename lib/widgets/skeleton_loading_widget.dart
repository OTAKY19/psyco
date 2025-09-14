import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../theme/app_theme.dart';

class SkeletonLoadingWidget extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoadingWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.lightTheme.colorScheme.surface,
      highlightColor: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.6),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et titre
          Row(
            children: [
              SkeletonLoadingWidget(
                width: 8.w,
                height: 8.w,
                borderRadius: BorderRadius.circular(8),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoadingWidget(
                      width: 40.w,
                      height: 2.5.h,
                    ),
                    SizedBox(height: 1.h),
                    SkeletonLoadingWidget(
                      width: 25.w,
                      height: 2.h,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Description
          SkeletonLoadingWidget(
            width: double.infinity,
            height: 3.h,
          ),
          SizedBox(height: 1.h),
          SkeletonLoadingWidget(
            width: 70.w,
            height: 3.h,
          ),

          SizedBox(height: 2.h),

          // Barre de progression
          SkeletonLoadingWidget(
            width: double.infinity,
            height: 1.h,
            borderRadius: BorderRadius.circular(4),
          ),

          SizedBox(height: 1.5.h),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoadingWidget(
                width: 15.w,
                height: 2.h,
              ),
              SkeletonLoadingWidget(
                width: 20.w,
                height: 2.h,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TestCardSkeleton extends StatelessWidget {
  const TestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône
          SkeletonLoadingWidget(
            width: 12.w,
            height: 12.w,
            borderRadius: BorderRadius.circular(8),
          ),

          SizedBox(width: 3.w),

          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                SkeletonLoadingWidget(
                  width: 50.w,
                  height: 2.5.h,
                ),

                SizedBox(height: 1.h),

                // Description
                SkeletonLoadingWidget(
                  width: double.infinity,
                  height: 2.h,
                ),
                SizedBox(height: 0.5.h),
                SkeletonLoadingWidget(
                  width: 60.w,
                  height: 2.h,
                ),

                SizedBox(height: 1.5.h),

                // Métadonnées
                Row(
                  children: [
                    SkeletonLoadingWidget(
                      width: 15.w,
                      height: 2.h,
                    ),
                    SizedBox(width: 2.w),
                    SkeletonLoadingWidget(
                      width: 12.w,
                      height: 2.h,
                    ),
                    SizedBox(width: 2.w),
                    SkeletonLoadingWidget(
                      width: 18.w,
                      height: 2.h,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsCardSkeleton extends StatelessWidget {
  const StatsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icône
          SkeletonLoadingWidget(
            width: 12.w,
            height: 12.w,
            borderRadius: BorderRadius.circular(25.w),
          ),

          SizedBox(height: 2.h),

          // Valeur
          SkeletonLoadingWidget(
            width: 20.w,
            height: 4.h,
          ),

          SizedBox(height: 1.h),

          // Label
          SkeletonLoadingWidget(
            width: 25.w,
            height: 2.h,
          ),
        ],
      ),
    );
  }
}

class QuestionSkeleton extends StatelessWidget {
  const QuestionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoadingWidget(
                  width: 20.w,
                  height: 2.5.h,
                ),
                SizedBox(height: 2.h),
                SkeletonLoadingWidget(
                  width: double.infinity,
                  height: 3.h,
                ),
                SizedBox(height: 1.h),
                SkeletonLoadingWidget(
                  width: 80.w,
                  height: 3.h,
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Options
          ...List.generate(4, (index) => Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: SkeletonLoadingWidget(
              width: double.infinity,
              height: 12.w,
              borderRadius: BorderRadius.circular(12),
            ),
          )),
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Stack(
      children: [
        child,
        Container(
          color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
          child: Center(
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  if (loadingText != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      loadingText!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
