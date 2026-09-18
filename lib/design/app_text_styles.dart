import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
    bool display = false,
  }) {
    // Voix unique Stitch : Plus Jakarta Sans partout (D3/A).
    // Le flag display est conservé pour compatibilité d'appel.
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final TextStyle displayLarge = _base(
    display: true,
    size: 32,
    weight: FontWeight.w800,
    height: 1.06,
  );

  static final TextStyle displayMedium = _base(
    display: true,
    size: 28,
    weight: FontWeight.w800,
    height: 1.08,
  );

  static final TextStyle headlineLarge = _base(
    display: true,
    size: 24,
    weight: FontWeight.w700,
    height: 1.33,
  );

  static final TextStyle headlineMedium = _base(
    display: true,
    size: 20,
    weight: FontWeight.w600,
    height: 1.4,
  );

  static final TextStyle headlineSmall = _base(
    display: true,
    size: 18,
    weight: FontWeight.w600,
    height: 1.3,
  );

  static final TextStyle titleLarge = _base(
    display: true,
    size: 22,
    weight: FontWeight.w700,
    height: 1.16,
  );

  static final TextStyle titleMedium = _base(
    display: true,
    size: 16,
    weight: FontWeight.w600,
    height: 1.25,
  );

  static final TextStyle titleSmall = _base(
    display: true,
    size: 14,
    weight: FontWeight.w600,
    height: 1.25,
  );

  static final TextStyle bodyLarge = _base(
    size: 16,
    weight: FontWeight.w400,
    height: 1.5,
  );

  static final TextStyle bodyMedium = _base(
    size: 14,
    weight: FontWeight.w400,
    height: 1.4,
  );

  static final TextStyle bodySmall = _base(
    size: 12,
    weight: FontWeight.w400,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static final TextStyle labelLarge = _base(
    size: 14,
    weight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
  );

  static final TextStyle labelMedium = _base(
    size: 12,
    weight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.4,
  );

  static final TextStyle labelSmall = _base(
    size: 10,
    weight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textSecondary,
    letterSpacing: 0.9,
  );

  static final TextStyle buttonLarge = _base(
    display: true,
    size: 16,
    weight: FontWeight.w600,
    height: 1.25,
  );

  static final TextStyle buttonMedium = _base(
    display: true,
    size: 14,
    weight: FontWeight.w600,
    height: 1.25,
  );

  static final TextStyle buttonSmall = _base(
    display: true,
    size: 12,
    weight: FontWeight.w600,
    height: 1.25,
  );

  static final TextStyle quizQuestion = _base(
    size: 18,
    weight: FontWeight.w500,
    height: 1.35,
  );

  static final TextStyle quizOption = _base(
    size: 16,
    weight: FontWeight.w400,
    height: 1.3,
  );

  static final TextStyle caption = _base(
    size: 11,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
  );

  static final TextStyle overline = _base(
    size: 10,
    weight: FontWeight.w800,
    color: AppColors.textSecondary,
    height: 1.2,
    letterSpacing: 1.5,
  );

  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}

extension BuildContextTextStyles on BuildContext {
  AppTextStylesHelper get txt => const AppTextStylesHelper();
}

class AppTextStylesHelper {
  const AppTextStylesHelper();

  TextStyle get displayLarge => AppTextStyles.displayLarge;
  TextStyle get displayMedium => AppTextStyles.displayMedium;
  TextStyle get headlineLarge => AppTextStyles.headlineLarge;
  TextStyle get headlineMedium => AppTextStyles.headlineMedium;
  TextStyle get headlineSmall => AppTextStyles.headlineSmall;
  TextStyle get titleLarge => AppTextStyles.titleLarge;
  TextStyle get titleMedium => AppTextStyles.titleMedium;
  TextStyle get titleSmall => AppTextStyles.titleSmall;
  TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  TextStyle get bodyMedium => AppTextStyles.bodyMedium;
  TextStyle get bodySmall => AppTextStyles.bodySmall;
  TextStyle get labelLarge => AppTextStyles.labelLarge;
  TextStyle get labelMedium => AppTextStyles.labelMedium;
  TextStyle get labelSmall => AppTextStyles.labelSmall;
  TextStyle get buttonLarge => AppTextStyles.buttonLarge;
  TextStyle get buttonMedium => AppTextStyles.buttonMedium;
  TextStyle get buttonSmall => AppTextStyles.buttonSmall;
  TextStyle get quizQuestion => AppTextStyles.quizQuestion;
  TextStyle get quizOption => AppTextStyles.quizOption;
  TextStyle get caption => AppTextStyles.caption;
  TextStyle get overline => AppTextStyles.overline;
}
