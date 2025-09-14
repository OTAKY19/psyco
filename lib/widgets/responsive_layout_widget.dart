import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Widget pour gérer les layouts responsives et éviter les bottom overflows
class ResponsiveLayoutWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool avoidBottomOverflow;
  final double? minHeight;
  final bool enableKeyboardAvoidance;
  
  const ResponsiveLayoutWidget({
    super.key,
    required this.child,
    this.padding,
    this.avoidBottomOverflow = true,
    this.minHeight,
    this.enableKeyboardAvoidance = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets;
    final keyboardHeight = viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;

    Widget content = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
        maxHeight: avoidBottomOverflow ? availableHeight * 0.95 : double.infinity,
      ),
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: 2.h,
      ),
      child: child,
    );

    if (avoidBottomOverflow) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
  });

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
    super.key,
    required this.percentage,
    this.size = 16.0, // Taille par défaut augmentée
    this.progressColor,
    this.backgroundColor,
    this.strokeWidth = 4.0, // Stroke plus épais
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = percentage >= 100;
    final displayPercentage = percentage.clamp(0.0, 100.0);
    
    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Circle
          CircularProgressIndicator(
            value: displayPercentage / 100,
            backgroundColor: backgroundColor ?? 
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? (isCompleted 
                ? Colors.green 
                : Theme.of(context).colorScheme.primary)
            ),
            strokeWidth: strokeWidth,
          ),
          
          // Percentage Text - Version optimisée pour le centrage
          Positioned.fill(
            child: Center(
              child: Text(
                '${displayPercentage.toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900, // Très gras
                  fontSize: size > 20 ? 16.sp : size > 15 ? 14.sp : 12.sp, // Plus grand
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                  height: 1.0, // Hauteur de ligne normale
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour éviter les overflows de boutons
class ResponsiveButtonWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool wrapContent;
  
  const ResponsiveButtonWidget({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.maxWidth,
    this.wrapContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveMaxWidth = maxWidth ?? screenWidth * 0.9;
    
    Widget button = Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 1.h),
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
        minHeight: 6.h, // Hauteur minimale pour les boutons
      ),
      child: child,
    );
    
    if (wrapContent) {
      return IntrinsicWidth(
        child: button,
      );
    }
    
    return button;
  }
}

/// Widget pour les colonnes de boutons responsive
class ResponsiveButtonRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool wrapContent;
  
  const ResponsiveButtonRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8.0,
    this.wrapContent = true,
  });

  @override
  Widget build(BuildContext context) {
    if (wrapContent) {
      return Wrap(
        spacing: spacing,
        runSpacing: 1.h,
        alignment: WrapAlignment.center,
        children: children.map((child) => 
          ResponsiveButtonWidget(
            child: child,
            wrapContent: true,
          )
        ).toList(),
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) => 
        Expanded(
          child: ResponsiveButtonWidget(
            child: child,
            wrapContent: false,
          ),
        )
      ).toList(),
    );
  }
}
