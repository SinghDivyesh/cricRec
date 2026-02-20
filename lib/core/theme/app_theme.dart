import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────
///  CricRec App Theme
///  Dark mode · Cricket Green accents
/// ─────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Palette ──────────────────────────────────
  static const Color primary        = Color(0xFF2E7D32); // deep cricket green
  static const Color primaryLight   = Color(0xFF4CAF50); // bright green
  static const Color primaryDark    = Color(0xFF1B5E20); // dark green

  static const Color background     = Color(0xFF121212); // near-black
  static const Color surface        = Color(0xFF1E1E1E); // card background
  static const Color surfaceVariant = Color(0xFF2A2A2A); // slightly lighter card

  static const Color onBackground   = Color(0xFFF5F5F5); // primary text
  static const Color onSurface      = Color(0xFFE0E0E0); // secondary text
  static const Color onSurfaceDim   = Color(0xFF9E9E9E); // hint / disabled text

  static const Color error          = Color(0xFFCF6679);
  static const Color warning        = Color(0xFFFFB300);
  static const Color info           = Color(0xFF29B6F6);

  static const Color divider        = Color(0xFF2C2C2C);
  static const Color border         = Color(0xFF333333);

  // ── Semantic colours (used across widgets) ───
  static const Color wicketRed      = Color(0xFFE53935);
  static const Color boundaryFour   = Color(0xFF43A047);
  static const Color boundarySix    = Color(0xFF7B1FA2);
  static const Color extraOrange    = Color(0xFFE65100);

  // ── Typography ───────────────────────────────
  static const TextTheme _textTheme = TextTheme(
    displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.bold,   color: onBackground, letterSpacing: -0.5),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,   color: onBackground),
    displaySmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.bold,   color: onBackground),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,   color: onBackground),
    headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600,   color: onBackground),
    headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: onBackground),
    titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: onBackground),
    titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500,   color: onBackground),
    titleSmall:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500,   color: onSurface),
    bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: onSurface),
    bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: onSurface),
    bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: onSurfaceDim),
    labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600,   color: onBackground, letterSpacing: 0.5),
    labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500,   color: onSurface),
    labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500,   color: onSurfaceDim, letterSpacing: 0.4),
  );

  // ── Main Theme ───────────────────────────────
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary:          primary,
        onPrimary:        Colors.white,
        primaryContainer: primaryDark,
        onPrimaryContainer: primaryLight,
        secondary:        primaryLight,
        onSecondary:      Colors.white,
        surface:          surface,
        onSurface:        onSurface,
        error:            error,
        onError:          Colors.white,
        outline:          border,
        outlineVariant:   divider,
        surfaceContainerHighest: surfaceVariant,
      ),

      scaffoldBackgroundColor: background,
      canvasColor:             surface,
      dividerColor:            divider,
      textTheme:               _textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor:  surface,
        foregroundColor:  onBackground,
        elevation:        0,
        centerTitle:      true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onBackground,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: primaryLight),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:           Colors.transparent,
          statusBarIconBrightness:  Brightness.light,
          systemNavigationBarColor: background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color:        surface,
        elevation:    2,
        shadowColor:  Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:  primary,
          foregroundColor:  Colors.white,
          disabledBackgroundColor: surfaceVariant,
          disabledForegroundColor: onSurfaceDim,
          elevation:        2,
          shadowColor:      Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          disabledForegroundColor: onSurfaceDim,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        surfaceVariant,
        hintStyle:        const TextStyle(color: onSurfaceDim, fontSize: 14),
        labelStyle:       const TextStyle(color: onSurfaceDim, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryLight, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:  surface,
        elevation:        8,
        shadowColor:      Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: onBackground,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14, color: onSurface,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  surfaceVariant,
        contentTextStyle: const TextStyle(color: onBackground, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior:         SnackBarBehavior.floating,
        actionTextColor:  primaryLight,
      ),

      listTileTheme: const ListTileThemeData(
        tileColor:        Colors.transparent,
        iconColor:        primaryLight,
        textColor:        onSurface,
        subtitleTextStyle: TextStyle(color: onSurfaceDim, fontSize: 12),
      ),

      dividerTheme: const DividerThemeData(
        color:     divider,
        thickness: 0.5,
        space:     1,
      ),

      iconTheme: const IconThemeData(color: onSurface, size: 24),
      primaryIconTheme: const IconThemeData(color: primaryLight, size: 24),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      surface,
        selectedItemColor:    primaryLight,
        unselectedItemColor:  onSurfaceDim,
        selectedLabelStyle:   TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation:            8,
        type: BottomNavigationBarType.fixed,
      ),

      chipTheme: ChipThemeData(
        backgroundColor:      surfaceVariant,
        selectedColor:        primaryDark,
        labelStyle:           const TextStyle(color: onSurface, fontSize: 12),
        secondaryLabelStyle:  const TextStyle(color: primaryLight, fontSize: 12),
        side:                 const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:                primaryLight,
        linearTrackColor:     surfaceVariant,
        circularTrackColor:   surfaceVariant,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryLight : onSurfaceDim),
        trackColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryDark : border),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryLight : onSurfaceDim),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       4,
        shape: CircleBorder(),
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor:         primaryLight,
        unselectedLabelColor: onSurfaceDim,
        indicatorColor:     primaryLight,
        labelStyle:   TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color:  surfaceVariant,
        shape:  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        textStyle: const TextStyle(color: onSurface, fontSize: 14),
      ),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary:          primary,
        onPrimary:        Colors.white,
        primaryContainer: Color(0xFFC8E6C9),
        onPrimaryContainer: primaryDark,
        secondary:        primaryLight,
        onSecondary:      Colors.white,
        surface:          Colors.white,
        onSurface:        Color(0xFF1A1A1A),
        error:            Color(0xFFB00020),
        onError:          Colors.white,
        outline:          Color(0xFFDDDDDD),
        outlineVariant:   Color(0xFFEEEEEE),
      ),

      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      dividerColor:            const Color(0xFFE0E0E0),
      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.bold,   color: Color(0xFF1A1A1A)),
        headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700,   color: Color(0xFF1A1A1A)),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,   color: Color(0xFF1A1A1A)),
        titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600,   color: Color(0xFF1A1A1A)),
        titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500,   color: Color(0xFF1A1A1A)),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF333333)),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF333333)),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF757575)),
        labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w600,   color: Color(0xFF1A1A1A)),
        labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w500,   color: Color(0xFF757575)),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor:  Colors.white,
        foregroundColor:  Color(0xFF1A1A1A),
        elevation:        0,
        centerTitle:      true,
        titleTextStyle: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A), letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: primary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor:          Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF5F5F5),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      cardTheme: CardThemeData(
        color:     Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          disabledForegroundColor: const Color(0xFF9E9E9E),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            inherit: false,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   Colors.white,
        hintStyle:   const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        labelStyle:  const TextStyle(color: Color(0xFF757575), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border:          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        enabledBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
        focusedBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 1.5)),
        errorBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFB00020))),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation:       8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle:   const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
        contentTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        actionTextColor: primaryLight,
      ),

      listTileTheme: const ListTileThemeData(
        iconColor:  primary,
        textColor:  Color(0xFF1A1A1A),
        subtitleTextStyle: TextStyle(color: Color(0xFF757575), fontSize: 12),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0), thickness: 0.5, space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor:   Color(0xFFE0E0E0),
        circularTrackColor: Color(0xFFE0E0E0),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0F0),
        selectedColor:   const Color(0xFFC8E6C9),
        labelStyle: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}