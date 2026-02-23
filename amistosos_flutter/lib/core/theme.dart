import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Campo Verde — sistema de diseño moderno para Tercer Tiempo.
/// Inspirado en las mejores apps deportivas: OneFootball, Sofascore, ESPN.
class AppTheme {
  AppTheme._();

  // ─── Paleta principal ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF16A34A);       // green-600
  static const Color primaryDark = Color(0xFF15803D);   // green-700
  static const Color primaryLight = Color(0xFFDCFCE7);  // green-100
  static const Color primaryFaint = Color(0xFFF0FDF4);  // green-50

  static const Color accent = Color(0xFFF59E0B);        // amber-500
  static const Color accentDark = Color(0xFFD97706);    // amber-600
  static const Color accentLight = Color(0xFFFEF9C3);   // amber-100

  // ─── Neutrals ─────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFC); // slate-50
  static const Color surfaceElevated = Color(0xFFF1F5F9); // slate-100
  static const Color bg = Color(0xFFEDF2F7);             // light bg

  static const Color text = Color(0xFF0F172A);           // slate-900
  static const Color textSec = Color(0xFF475569);        // slate-600
  static const Color textMuted = Color(0xFF94A3B8);      // slate-400

  static const Color border = Color(0xFFE2E8F0);         // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1);   // slate-300

  // ─── Semánticos ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ─── Backwards compat (no rompemos código existente) ─────────────────────
  static const Color black = text;
  static const Color white = surface;
  static const Color grayLight = surfaceVariant;
  static const Color gray100 = surfaceElevated;
  static const Color gray200 = border;
  static const Color gray300 = borderStrong;
  static const Color gray400 = textMuted;
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = textSec;
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = text;
  static const Color accentSuccess = success;
  static const Color accentWarning = warning;
  static const Color accentDanger = error;
  static const Color accentBlue = info;

  // ─── Radios ───────────────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  // ─── Sombras ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ─── ThemeData ────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: text, letterSpacing: -1.0, height: 1.1),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.5, height: 1.2),
      displaySmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3, height: 1.2),
      headlineLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: text, height: 1.3),
      headlineMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: text, height: 1.3),
      headlineSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: text, height: 1.4),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: text, height: 1.5),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSec, height: 1.5),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: textMuted, height: 1.4),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSec),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3),
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: text),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: text),
    );

    const inputRadius = BorderRadius.all(Radius.circular(radiusSm));

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: surface,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: accent,
        onSecondary: surface,
        secondaryContainer: accentLight,
        onSecondaryContainer: accentDark,
        surface: surface,
        onSurface: text,
        surfaceContainerHighest: surfaceVariant,
        error: error,
        onError: surface,
        errorContainer: errorLight,
        outline: border,
        outlineVariant: borderStrong,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
        iconTheme: const IconThemeData(color: text, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withOpacity(0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return borderStrong;
            if (s.contains(WidgetState.hovered)) return primaryDark;
            return primary;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.focused)) return const BorderSide(color: primary, width: 1.5);
            if (s.contains(WidgetState.hovered)) return const BorderSide(color: borderStrong, width: 1.5);
            return const BorderSide(color: border, width: 1.5);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXs)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: border, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: border, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: inputRadius, borderSide: const BorderSide(color: error, width: 2)),
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
        floatingLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textMuted),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: error, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: gray800,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: surface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return primary;
          return surface;
        }),
        side: const BorderSide(color: borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryLight,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSec),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return surface;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return primary;
          return border;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: text),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSec, height: 1.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: primary, size: 22),
        unselectedIconTheme: const IconThemeData(color: textMuted, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
        unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
        useIndicator: true,
        indicatorColor: primaryLight,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: gray800, borderRadius: BorderRadius.circular(radiusXs)),
        textStyle: GoogleFonts.inter(fontSize: 12, color: surface, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: error, textColor: surface, smallSize: 8, largeSize: 16),
    );
  }
}

extension AppThemeExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get tt => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isWide => MediaQuery.sizeOf(this).width >= 768;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1024;
}
