import 'package:flutter/material.dart';

// 1. Define the Primary Seed Color for the brand
const Color _wellnessSeedColor = Color(0xFF3949AB); // A calming Indigo

// 2. Define a Secondary/Accent Color (e.g., a vibrant Green/Teal)
const Color _secondaryAccentColor = Color(0xFF26A69A); // A vibrant Teal

class AppTheme {
  // --- Shared Properties ---
  static const String fontFamily = 'Roboto'; // Default M3 font is Roboto

  // --- LIGHT THEME ---
  static ThemeData lightTheme = ThemeData(
    // 1. Mandatory M3 flag
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.light,

    // 2. ColorScheme from Seed (generates Primary, Secondary, etc., harmony)
    colorScheme: ColorScheme.fromSeed(
      seedColor: _wellnessSeedColor,
      primary: _wellnessSeedColor, // Explicitly set Primary to the seed
      secondary: _secondaryAccentColor, // Inject the accent color manually
      // Use a light, soft surface color for the wellness feel
      surface: const Color(0xFFF7F9FC),
    ),

    // 3. Customize Component Theme (Focus on soft shapes)
    cardTheme: CardThemeData( // <--- CORRECTED: Use CardThemeData
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // More rounded/friendly cards
      ),
    ),

    // Customize AppBar for a clean, light look
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFFF7F9FC), // Matches surface
      foregroundColor: Color(0xFF1A237E), // Dark text on light background
    ),

    // Customize Floating Action Button (often used for quick entry/action)
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _secondaryAccentColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0), // Pill shape for friendly look
      ),
    ),

    // Customize buttons for consistent design
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields (for Vitals/Diet entries)
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

  // --- DARK THEME (Optional but highly recommended for M3) ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    brightness: Brightness.dark,

    // Use the same seed color for consistency
    colorScheme: ColorScheme.fromSeed(
      seedColor: _wellnessSeedColor,
      primary: _wellnessSeedColor,
      secondary: _secondaryAccentColor,
      brightness: Brightness.dark, // Crucial to generate dark scheme
    ),

    // Apply similar component themes, automatically adapting to dark colors
    cardTheme: lightTheme.cardTheme,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    floatingActionButtonTheme: lightTheme.floatingActionButtonTheme,
    elevatedButtonTheme: lightTheme.elevatedButtonTheme,
    inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
      fillColor: const Color(0xFF1E1E1E), // Darker input background
    ),
  );
}