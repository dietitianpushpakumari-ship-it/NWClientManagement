import 'package:flutter/material.dart';

// 1. Define the Primary Seed Color (Depth)
// Restful Navy Blue: Remains the deep, professional color.
const Color _wellnessSeedColor = Color(0xFF00DFDB);

// 2. Define colors for the Calming Glass/Shining Effect
const Color _softMistColorPrimary = Color(0xFF00DFDB); // Soft, desaturated Mint Mist
const Color _softMistColorSecondary = Color(0xFFE1F5FE); // Light Pale Blue

class AppTheme {
  // --- Shared Properties ---
  static const String fontFamily = 'Roboto';

  // --- LIGHT THEME ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.light,

    // 2. ColorScheme from Seed
    colorScheme: ColorScheme.fromSeed(
      seedColor: _wellnessSeedColor,
      primary: _wellnessSeedColor,
      secondary: _softMistColorPrimary, // Exposed for glass tint/start
      tertiary: _softMistColorSecondary, // Exposed for soft highlight/end
      surface: const Color(0xFFFBFBFD),
      error: Colors.red.shade700,
    ),

    // 3. Customize Component Theme (Maximized Shine and Elegance)
    cardTheme: CardThemeData().copyWith(
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      // Shadow/Glow effect is now softer, using the soothing secondary color
      shadowColor: _softMistColorPrimary.withOpacity(0.6),
      surfaceTintColor: _wellnessSeedColor.withOpacity(0.1),
    ),

    // Customize AppBar
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 8.0,
      // Background must be transparent for the custom glass effect to show
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white, // Text/icons are white
    ),

    // Customize Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _softMistColorPrimary,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
    ),

    // Customize buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFFD1D9E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _wellnessSeedColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      fillColor: Colors.white,
      filled: true,
    ),
  );

  // --- DARK THEME ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: _wellnessSeedColor,
      primary: _wellnessSeedColor,
      secondary: _softMistColorPrimary,
      tertiary: _softMistColorSecondary,
      brightness: Brightness.dark,
    ),

    cardTheme: lightTheme.cardTheme,
    appBarTheme: lightTheme.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
    ),
    floatingActionButtonTheme: lightTheme.floatingActionButtonTheme,
    elevatedButtonTheme: lightTheme.elevatedButtonTheme,
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF1E1E1E),
    ),
  );
}