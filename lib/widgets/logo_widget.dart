import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

/// Widget pour afficher le logo de l'application
class LogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final bool showText;
  final String? text;
  final TextStyle? textStyle;
  final MainAxisAlignment alignment;
  
  const LogoWidget({
    super.key,
    this.width,
    this.height,
    this.color,
    this.showText = true,
    this.text,
    this.textStyle,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = width ?? 20.w;
    final logoHeight = height ?? logoSize;
    
    return Column(
      mainAxisAlignment: alignment,
      children: [
        // Logo SVG
        SvgPicture.asset(
          'assets/images/logo/psychotest_logo.svg',
          width: logoSize,
          height: logoHeight,
          colorFilter: color != null 
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        ),
        
        // Texte du logo
        if (showText) ...[
          SizedBox(height: 2.h),
          Text(
            text ?? 'PsychoTest+',
            style: textStyle ?? _getDefaultTextStyle(context),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  TextStyle _getDefaultTextStyle(BuildContext context) {
    return AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: AppTheme.lightTheme.colorScheme.primary,
      letterSpacing: -0.5,
    ) ?? const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: Colors.blue,
    );
  }
}

/// Widget pour le logo compact (sans texte)
class CompactLogoWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const CompactLogoWidget({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 12.w;
    
    return SvgPicture.asset(
      'assets/images/logo/psychotest_logo.svg',
      width: logoSize,
      height: logoSize,
      colorFilter: color != null 
        ? ColorFilter.mode(color!, BlendMode.srcIn)
        : null,
    );
  }
}

/// Widget pour le logo avec gradient de texte
class GradientLogoWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool showText;
  final String? text;
  final List<Color>? gradientColors;
  final MainAxisAlignment alignment;
  
  const GradientLogoWidget({
    super.key,
    this.width,
    this.height,
    this.showText = true,
    this.text,
    this.gradientColors,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = width ?? 20.w;
    final logoHeight = height ?? logoSize;
    final colors = gradientColors ?? [
      AppTheme.lightTheme.colorScheme.primary,
      AppTheme.lightTheme.colorScheme.secondary,
    ];
    
    return Column(
      mainAxisAlignment: alignment,
      children: [
        // Logo SVG
        SvgPicture.asset(
          'assets/images/logo/psychotest_logo.svg',
          width: logoSize,
          height: logoHeight,
        ),
        
        // Texte avec gradient
        if (showText) ...[
          SizedBox(height: 2.h),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: colors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              text ?? 'PsychoTest+',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white, // Couleur blanche pour le shader
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
