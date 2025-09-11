import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Widget pour gérer les layouts responsives et éviter les bottom overflows
class ResponsiveLayoutWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool avoidBottomOverflow;
  final double? minHeight;
  
  const ResponsiveLayoutWidget({
    Key? key,
    required this.child,
    this.padding,
    this.avoidBottomOverflow = true,
    this.minHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets;
    final availableHeight = screenHeight - viewInsets.bottom;

    Widget content = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
        maxHeight: avoidBottomOverflow ? availableHeight * 0.9 : double.infinity,
      ),
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 2.h,
      ),
      child: child,
    );

    if (avoidBottomOverflow) {
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: content,
      );
    }

    return content;
  }
}

/// Widget pour créer des cartes responsive sans overflow
class ResponsiveCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  
  const ResponsiveCardWidget({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 1.h,
      ),
      constraints: BoxConstraints(
        maxWidth: 100.w,
        minHeight: 8.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: elevation ?? 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Container(
          padding: padding ?? EdgeInsets.all(4.w),
          child: child,
        ),
      ),
    );
  }
}

/// Widget pour les pourcentages bien centrés et lisibles
class ResponsiveProgressWidget extends StatelessWidget {
  final double percentage;
  final double size;
  final Color? progressColor;
  final Color? backgroundColor;
  final double strokeWidth;
  
  const ResponsiveProgressWidget({
    Key? key,
    required this.percentage,
    this.size = 12.0,
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = percentage >= 100;
    final displayPercentage = percentage.clamp(0.0, 100.0);
    
    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        children: [
          // Progress Circle
          CircularProgressIndicator(
            value: displayPercentage / 100,
            backgroundColor: backgroundColor ?? 
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? (isCompleted 
                ? Colors.green 
                : Theme.of(context).primaryColor)
            ),
            strokeWidth: strokeWidth,
          ),
          
          // Percentage Text - Version optimisée
          Center(
            child: Container(
              width: (size * 0.9).w, // Zone plus large
              height: (size * 0.9).w,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.contain, // Utilise tout l'espace disponible
                child: Text(
                  '${displayPercentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800, // Plus gras
                    fontSize: size > 15 ? 14.sp : size > 10 ? 12.sp : 10.sp, // Plus grand
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 0.9, // Compacte verticalement
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
