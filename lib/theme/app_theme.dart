import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/app_colors.dart';
import '../design/app_radii.dart';
import '../design/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.accentContainer,
      onSecondaryContainer: AppColors.accentDark,
      tertiary: AppColors.primaryLight,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.primaryContainer,
      onTertiaryContainer: AppColors.primary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
      shadow: AppColors.shadow,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryLight,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    dividerColor: AppColors.divider,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      shadowColor: AppColors.shadowLight,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.fab)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        shadowColor: AppColors.shadow,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonMedium,
      ),
    ),

    textTheme: AppTextStyles.textTheme,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.3);
        }
        return AppColors.textMuted.withValues(alpha: 0.3);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.onPrimary),
      side: const BorderSide(color: AppColors.border, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.textSecondary;
      }),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.border,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.2),
      valueIndicatorColor: AppColors.primary,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      textStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      ),
      elevation: 4,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.modal)),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.modalTop),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.border,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.accentLight,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.accentDark,
      onSecondaryContainer: AppColors.accentLight,
      tertiary: AppColors.primaryLight,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.primaryDark,
      onTertiaryContainer: AppColors.primaryLight,
      error: AppColors.errorLight,
      onError: AppColors.textPrimary,
      errorContainer: AppColors.errorDark,
      onErrorContainer: AppColors.errorLight,
      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
      onSurfaceVariant: AppColors.textMuted,
      outline: AppColors.borderDark,
      outlineVariant: Color(0xFF2A2E3A),
      shadow: AppColors.shadowDark,
      scrim: AppColors.overlay,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primaryDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.surfaceDark,
    dividerColor: AppColors.borderDark,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.shadowDark,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.fab)),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonLarge.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonLarge.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
        ),
        textStyle: AppTextStyles.buttonMedium.copyWith(
          color: AppColors.primaryLight,
        ),
      ),
    ),

    textTheme: AppTextStyles.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDimDark,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.borderDark, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.borderDark, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.errorLight, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted.withValues(alpha: 0.7),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
        return AppColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryLight.withValues(alpha: 0.3);
        }
        return AppColors.textMuted.withValues(alpha: 0.3);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.textPrimary),
      side: const BorderSide(color: AppColors.borderDark, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primaryLight;
        return AppColors.textMuted;
      }),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
      linearTrackColor: AppColors.borderDark,
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primaryLight,
      inactiveTrackColor: AppColors.borderDark,
      thumbColor: AppColors.primaryLight,
      overlayColor: AppColors.primaryLight.withValues(alpha: 0.2),
      valueIndicatorColor: AppColors.primaryLight,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: AppColors.borderDark),
      ),
      textStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: AppColors.accentLight,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.input)),
      ),
      elevation: 4,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.modal)),
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.modalTop),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.borderDark,
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),
  );
}
