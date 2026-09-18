import 'package:flutter/material.dart';

/// Tokens repeints vers le système Stitch « Academic Focus & Distinction »
/// (DESIGN.md) : ivoire académique, vert pin institutionnel, bordeaux
/// cérémonial, Plus Jakarta Sans voix unique. Anti-gamification sobre.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF315E4E);
  static const Color primaryLight = Color(0xFF4A7766);
  static const Color primaryDark = Color(0xFF002117);
  static const Color primaryContainer = Color(0xFFBCEDD8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryLight = Color(0xFF1D1B19);

  static const Color accent = Color(0xFF4A7766);
  static const Color accentLight = Color(0xFFA1D1BD);
  static const Color accentDark = Color(0xFF315E4E);
  static const Color accentContainer = Color(0xFFBCEDD8);

  static const Color success = Color(0xFF315E4E);
  static const Color successLight = Color(0xFF4A7766);
  static const Color successDark = Color(0xFF002117);
  static const Color successContainer = Color(0xFFBCEDD8);

  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFF92400E);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorLight = Color(0xFFFFB1C2);
  static const Color errorDark = Color(0xFF93000A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color danger = Color(0xFF8C4A5B);
  static const Color dangerLight = Color(0xFFFFB1C2);
  static const Color dangerDark = Color(0xFF390819);
  static const Color dangerContainer = Color(0xFFFFD9E0);

  static const Color background = Color(0xFFFEF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF2EDE8);
  static const Color surfaceContainer = Color(0xFFF8F3EE);

  static const Color backgroundDark = Color(0xFF1D1B19);
  static const Color surfaceDark = Color(0xFF32302D);
  static const Color surfaceDimDark = Color(0xFF414944);

  static const Color textPrimary = Color(0xFF1D1B19);
  static const Color textSecondary = Color(0xFF414944);
  static const Color textMuted = Color(0xFF717974);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDDD7D0);
  static const Color borderLight = Color(0xFFECE7E2);
  static const Color borderDark = Color(0xFF414944);
  static const Color borderFocus = Color(0xFF315E4E);

  static const Color shadow = Color(0x141E2623);
  static const Color shadowLight = Color(0x0A1E2623);
  static const Color shadowDark = Color(0x33000000);

  static const Color glass = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x334A7766);
  static const Color glassOverlay = Color(0x0D4A7766);

  // Lettres d'options : échelle pin neutre (Stitch). Pas de vert/rouge
  // par lettre : ces couleurs sont réservées au validé correct/incorrect.
  static const Color quizA = Color(0xFF4A7766);
  static const Color quizB = Color(0xFFA1D1BD);
  static const Color quizC = Color(0xFF717974);
  static const Color quizD = Color(0xFF414944);

  static const Color badgePremium = Color(0xFF315E4E);
  static const Color badgePremiumBg = Color(0xFFBCEDD8);
  static const Color badgeFreeBg = Color(0xFFE7E2DD);

  static const Color admisBg = Color(0xFFBCEDD8);
  static const Color admisFg = Color(0xFF214F3F);
  static const Color echouBg = Color(0xFFFFD9E0);
  static const Color echouFg = Color(0xFF7B3D4D);

  static const Color overlay = Color(0x80000000);
  static const Color divider = Color(0xFFDDD7D0);
  static const Color disabled = Color(0xFFCBC6BF);
  static const Color disabledText = Color(0xFF717974);
}

extension BuildContextColors on BuildContext {
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
