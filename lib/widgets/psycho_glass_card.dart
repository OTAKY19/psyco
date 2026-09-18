import 'dart:ui';
import 'package:flutter/material.dart';
import '../design/app_colors.dart';
import '../design/app_radii.dart';
import '../design/app_spacing.dart';

class PsychoGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double blurStrength;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showBorder;

  const PsychoGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.blurStrength = 10,
    this.borderRadius = AppRadii.card,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurStrength,
          sigmaY: blurStrength,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.12))
                : null,
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
