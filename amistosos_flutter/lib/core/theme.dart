import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tercer Tiempo — Design System 2026.
/// Dirección: Stripe / Linear / Vercel · minimalista · profesional · elegante.
class AppTheme {
  AppTheme._();

  // ─── Color Primario ─────────────────────────────────────────────────────────
  // Emerald refinado — deportivo + sofisticado
  static const Color primary      = Color(0xFF059669); // emerald-600
  static const Color primaryDark  = Color(0xFF047857); // emerald-700
  static const Color primaryLight = Color(0xFFD1FAE5); // emerald-100
  static const Color primaryFaint = Color(0xFFECFDF5); // emerald-50

  // ─── Acento (Amber) ─────────────────────────────────────────────────────────
  static const Color accent      = Color(0xFFF59E0B); // amber-500
  static const Color accentDark  = Color(0xFFD97706); // amber-600
  static const Color accentLight = Color(0xFFFEF9C3); // amber-100

  // ─── Superficies ────────────────────────────────────────────────────────────
  static const Color bg              = Color(0xFFF9FAFB); // gray-50  (limpio, casi blanco)
  static const Color surface         = Color(0xFFFFFFFF);
  static const Color surfaceVariant  = Color(0xFFF3F4F6); // gray-100
  static const Color surfaceElevated = Color(0xFFE5E7EB); // gray-200

  // ─── Texto ──────────────────────────────────────────────────────────────────
  static const Color text     = Color(0xFF111827); // gray-900
  static const Color textSec  = Color(0xFF4B5563); // gray-600
  static const Color textMuted= Color(0xFF9CA3AF); // gray-400

  // ─── Bordes ─────────────────────────────────────────────────────────────────
  static const Color border      = Color(0xFFE5E7EB); // gray-200
  static const Color borderStrong= Color(0xFFD1D5DB); // gray-300

  // ─── Semánticos ─────────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF10B981); // emerald-500
  static const Color successLight = Color(0xFFD1FAE5); // emerald-100
  static const Color warning      = Color(0xFFF59E0B); // amber-500
  static const Color warningLight = Color(0xFFFEF9C3); // amber-100
  static const Color error        = Color(0xFFEF4444); // red-500
  static const Color errorLight   = Color(0xFFFEF2F2); // red-50
  static const Color info         = Color(0xFF3B82F6); // blue-500
  static const Color infoLight    = Color(0xFFEFF6FF); // blue-50

  // ─── Retrocompatibilidad ─────────────────────────────────────────────────
  static const Color black      = text;
  static const Color white      = surface;
  static const Color grayLight  = surfaceVariant;
  static const Color gray100    = surfaceElevated;
  static const Color gray200    = border;
  static const Color gray300    = borderStrong;
  static const Color gray400    = textMuted;
  static const Color gray500    = Color(0xFF6B7280);
  static const Color gray600    = textSec;
  static const Color gray700    = Color(0xFF374151);
  static const Color gray800    = Color(0xFF1F2937);
  static const Color gray900    = text;
  static const Color accentSuccess = success;
  static const Color accentWarning = warning;
  static const Color accentDanger  = error;
  static const Color accentBlue    = info;

  // ─── Sistema de radio ───────────────────────────────────────────────────────
  static const double radiusXs   = 4.0;
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 24.0;
  static const double radiusFull = 999.0;

  // ─── Sistema de spacing ─────────────────────────────────────────────────────
  static const double sp2  = 2.0;
  static const double sp4  = 4.0;
  static const double sp6  = 6.0;
  static const double sp8  = 8.0;
  static const double sp12 = 12.0;
  static const double sp16 = 16.0;
  static const double sp20 = 20.0;
  static const double sp24 = 24.0;
  static const double sp32 = 32.0;
  static const double sp40 = 40.0;
  static const double sp48 = 48.0;
  static const double sp64 = 64.0;

  // ─── Sistema de sombras ─────────────────────────────────────────────────────
  static List<BoxShadow> get shadowXs => [
    BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withAlpha(8),  blurRadius: 2, offset: const Offset(0, 1)),
  ];

  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
    BoxShadow(color: Colors.black.withAlpha(8),  blurRadius: 4,  offset: const Offset(0, 2)),
  ];

  static List<BoxShadow> get shadowLg => [
    BoxShadow(color: Colors.black.withAlpha(14), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withAlpha(8),  blurRadius: 6,  offset: const Offset(0, 3)),
  ];

  static List<BoxShadow> get shadowXl => [
    BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 40, offset: const Offset(0, 16)),
    BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 6)),
  ];

  // Sombra coloreada para botón primary (efecto "glow" sutil)
  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(color: primary.withAlpha(50), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // ─── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base    = ThemeData.light(useMaterial3: true);
    const inputBR = BorderRadius.all(Radius.circular(radiusSm));

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      // Display
      displayLarge:  _ts(36, FontWeight.w800, text, ls: -1.2, h: 1.1),
      displayMedium: _ts(28, FontWeight.w700, text, ls: -0.6, h: 1.15),
      displaySmall:  _ts(22, FontWeight.w700, text, ls: -0.3, h: 1.2),
      // Headline
      headlineLarge:  _ts(20, FontWeight.w700, text,  h: 1.3),
      headlineMedium: _ts(18, FontWeight.w600, text,  h: 1.35),
      headlineSmall:  _ts(16, FontWeight.w600, text,  h: 1.4),
      // Title
      titleLarge:  _ts(18, FontWeight.w700, text),
      titleMedium: _ts(16, FontWeight.w600, text),
      titleSmall:  _ts(14, FontWeight.w600, text),
      // Body
      bodyLarge:  _ts(15, FontWeight.w400, text,   h: 1.6),
      bodyMedium: _ts(14, FontWeight.w400, textSec, h: 1.6),
      bodySmall:  _ts(13, FontWeight.w400, textMuted, h: 1.5),
      // Label
      labelLarge:  _ts(13, FontWeight.w600, text),
      labelMedium: _ts(12, FontWeight.w600, textSec),
      labelSmall:  _ts(11, FontWeight.w600, textMuted, ls: 0.4),
    );

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary:               primary,
        onPrimary:             surface,
        primaryContainer:      primaryLight,
        onPrimaryContainer:    primaryDark,
        secondary:             accent,
        onSecondary:           surface,
        secondaryContainer:    accentLight,
        onSecondaryContainer:  accentDark,
        surface:               surface,
        onSurface:             text,
        surfaceContainerHighest: surfaceVariant,
        error:                 error,
        onError:               surface,
        errorContainer:        errorLight,
        outline:               border,
        outlineVariant:        borderStrong,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,

      // AppBar — limpia, sin elevación visible
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withAlpha(15),
        centerTitle: false,
        titleTextStyle: _ts(17, FontWeight.w700, text),
        iconTheme: const IconThemeData(color: text, size: 20),
      ),

      // Card — sin elevación intrínseca, shadow manual en componentes
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLg)),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button — primary verde + sombra coloreada sutil
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: _ts(13, FontWeight.w600, surface),
          shadowColor: Colors.transparent,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return borderStrong;
            if (s.contains(WidgetState.pressed)) return primaryDark;
            if (s.contains(WidgetState.hovered)) return const Color(0xFF047857);
            return primary;
          }),
          elevation: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return 2;
            return 0;
          }),
          overlayColor: WidgetStateProperty.all(Colors.white.withAlpha(20)),
        ),
      ),

      // Outlined Button — borde fino, hover sutil
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: _ts(13, FontWeight.w600, text),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.focused)) return const BorderSide(color: primary, width: 1.5);
            if (s.contains(WidgetState.hovered)) return const BorderSide(color: borderStrong, width: 1.5);
            return const BorderSide(color: border, width: 1.5);
          }),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return surfaceVariant;
            return surface;
          }),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: _ts(13, FontWeight.w600, primary),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXs)),
        ),
      ),

      // Input — minimalista, focus ring verde
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:            OutlineInputBorder(borderRadius: inputBR, borderSide: const BorderSide(color: border,       width: 1.5)),
        enabledBorder:     OutlineInputBorder(borderRadius: inputBR, borderSide: const BorderSide(color: border,       width: 1.5)),
        focusedBorder:     OutlineInputBorder(borderRadius: inputBR, borderSide: const BorderSide(color: primary,      width: 2.0)),
        errorBorder:       OutlineInputBorder(borderRadius: inputBR, borderSide: const BorderSide(color: error,        width: 1.5)),
        focusedErrorBorder:OutlineInputBorder(borderRadius: inputBR, borderSide: const BorderSide(color: error,        width: 2.0)),
        hintStyle:       GoogleFonts.inter(fontSize: 14, color: textMuted),
        labelStyle:      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
        floatingLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
        errorStyle:      GoogleFonts.inter(fontSize: 12, color: error, fontWeight: FontWeight.w500),
        helperStyle:     GoogleFonts.inter(fontSize: 12, color: textMuted),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 0),

      // ListTile
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // SnackBar — flotante, dark
      snackBarTheme: SnackBarThemeData(
        backgroundColor: gray800,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: surface, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.all(16),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return primary;
          return surface;
        }),
        side: const BorderSide(color: borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Progress
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryLight,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textSec),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusFull)),
        side: const BorderSide(color: border, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Switch
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

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 24,
        shadowColor: Colors.black.withAlpha(30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
        titleTextStyle: _ts(17, FontWeight.w700, text),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSec, height: 1.6),
      ),

      // Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme:   const IconThemeData(color: primary,   size: 22),
        unselectedIconTheme: const IconThemeData(color: textMuted, size: 22),
        selectedLabelTextStyle:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
        unselectedLabelTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
        useIndicator: true,
        indicatorColor: primaryLight,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: gray800,
          borderRadius: BorderRadius.circular(radiusSm),
          boxShadow: shadowMd,
        ),
        textStyle: GoogleFonts.inter(fontSize: 12, color: surface, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        waitDuration: const Duration(milliseconds: 400),
      ),

      // Badge
      badgeTheme: const BadgeThemeData(
        backgroundColor: error,
        textColor: surface,
        smallSize: 8,
        largeSize: 16,
      ),

      // Tab
      tabBarTheme: TabBarThemeData(
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
        labelColor: primary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
      ),
    );
  }

  // Helper privado para TextStyle con Inter
  static TextStyle _ts(double size, FontWeight weight, Color color,
      {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color,
          letterSpacing: ls, height: h);
}

// ─── Extensiones de contexto ──────────────────────────────────────────────────

extension AppThemeExt on BuildContext {
  ThemeData  get theme  => Theme.of(this);
  TextTheme  get tt     => Theme.of(this).textTheme;
  ColorScheme get colors=> Theme.of(this).colorScheme;
  bool get isWide    => MediaQuery.sizeOf(this).width >= 768;
  bool get isDesktop => MediaQuery.sizeOf(this).width >= 1024;
  double get screenW => MediaQuery.sizeOf(this).width;
  double get screenH => MediaQuery.sizeOf(this).height;
}
