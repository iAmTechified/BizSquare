import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === Exact Brand Colors from Logo Master ===
  static const Color primaryBlue = Color(0xFF0058FF);       // Main brand color (#0058ff)
  static const Color secondaryLime = Color(0xFF5AFF00);     // Second color (#5aff00)
  static const Color accentMagenta = Color(0xFFFF00A6);     // Last / Accent color (#ff00a6)

  // Gradient definitions for BizSquare geometric ribbon & glow
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryBlue, accentMagenta, secondaryLime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueMagentaGradient = LinearGradient(
    colors: [primaryBlue, accentMagenta],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient blueLimeGradient = LinearGradient(
    colors: [primaryBlue, secondaryLime],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic Colors
  static const Color success = Color(0xFF5AFF00);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF0055);

  // Light Mode Tokens
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0B132B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightInputBg = Color(0xFFF1F5F9);

  // Dark Mode Tokens
  static const Color darkBg = Color(0xFF080D1A);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkBorder = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkInputBg = Color(0xFF131D33);

  // Geometry Radius
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;

  // Satoshi Typography Helper with Inter / PlusJakarta fallback
  static TextStyle satoshi({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    try {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'Satoshi',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );
    }
  }

  // === LIGHT THEME ===
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: secondaryLime,
          tertiary: accentMagenta,
          surface: lightSurface,
          onPrimary: Colors.white,
          onSecondary: Color(0xFF080D1A),
          onSurface: lightTextPrimary,
          error: error,
        ),
        scaffoldBackgroundColor: lightBg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: lightTextPrimary,
          displayColor: lightTextPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: lightBg,
          foregroundColor: lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: satoshi(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: lightTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: lightSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: const BorderSide(color: lightBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
          labelStyle: satoshi(color: lightTextSecondary, fontSize: 14),
          hintStyle: satoshi(color: lightTextSecondary, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            textStyle: satoshi(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: lightTextPrimary,
            side: const BorderSide(color: lightBorder),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            textStyle: satoshi(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );

  // === DARK THEME ===
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,
          secondary: secondaryLime,
          tertiary: accentMagenta,
          surface: darkSurface,
          onPrimary: Colors.white,
          onSecondary: Color(0xFF080D1A),
          onSurface: darkTextPrimary,
          error: error,
        ),
        scaffoldBackgroundColor: darkBg,
        textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
          bodyColor: darkTextPrimary,
          displayColor: darkTextPrimary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: satoshi(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: darkTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: const BorderSide(color: darkBorder, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
            borderSide: const BorderSide(color: primaryBlue, width: 1.5),
          ),
          labelStyle: satoshi(color: darkTextSecondary, fontSize: 14),
          hintStyle: satoshi(color: darkTextSecondary, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            textStyle: satoshi(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextPrimary,
            side: const BorderSide(color: darkBorder),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSmall),
            ),
            textStyle: satoshi(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      );
}
