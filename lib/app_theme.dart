import 'package:flutter/material.dart';

// 1. Define 20 Premium Theme Options
enum AppThemeType {
  deepTeal,       // Default (Medical/Trust)
  royalBlue,      // Corporate/Professional
  emeraldGreen,   // Nature/Health
  crimsonRed,     // Bold/Energetic
  amethystPurple, // Luxury/Creative
  sunsetOrange,   // Warmth/Energy
  slateGrey,      // Minimal/Modern
  midnightBlue,   // Deep/Serious
  forestGreen,    // Organic/Calm
  cherryBlossom,  // Soft/Playful
  oceanBlue,      // Fresh/Clean
  oliveGarden,    // Earthy/Natural
  goldenHour,     // Vibrant/Optimistic
  lavenderMist,   // Calming/Soft
  chocolateBrown, // Grounded/Rich
  steelBlue,      // Tech/Sleek
  mintFresh,      // Modern/Medical
  berryCrush,     // Vivid/Bold
  charcoalBlack,  // High Contrast/Dark
  copperRust,     // Industrial/Warm
}

class AppTheme {
  static const String fontFamily = 'Roboto';

  // 2. Map Options to Premium Seed Colors
  static final Map<AppThemeType, Color> _themeSeeds = {
    AppThemeType.deepTeal: const Color(0xFF006064),
    AppThemeType.royalBlue: const Color(0xFF1A237E),
    AppThemeType.emeraldGreen: const Color(0xFF1B5E20),
    AppThemeType.crimsonRed: const Color(0xFFB71C1C),
    AppThemeType.amethystPurple: const Color(0xFF4A148C),
    AppThemeType.sunsetOrange: const Color(0xFFE65100),
    AppThemeType.slateGrey: const Color(0xFF37474F),
    AppThemeType.midnightBlue: const Color(0xFF0D47A1),
    AppThemeType.forestGreen: const Color(0xFF2E7D32),
    AppThemeType.cherryBlossom: const Color(0xFF880E4F),
    AppThemeType.oceanBlue: const Color(0xFF0277BD),
    AppThemeType.oliveGarden: const Color(0xFF827717),
    AppThemeType.goldenHour: const Color(0xFFE65100),
    AppThemeType.lavenderMist: const Color(0xFF512DA8),
    AppThemeType.chocolateBrown: const Color(0xFF3E2723),
    AppThemeType.steelBlue: const Color(0xFF455A64),
    AppThemeType.mintFresh: const Color(0xFF00695C),
    AppThemeType.berryCrush: const Color(0xFFA81B60),
    AppThemeType.charcoalBlack: const Color(0xFF212121),
    AppThemeType.copperRust: const Color(0xFFBF360C),
  };

  // 3. Dynamic Theme Generator
  static ThemeData getTheme({
    required AppThemeType type,
    required Brightness brightness,
  }) {
    // Get seed color
    final seedColor = _themeSeeds[type] ?? const Color(0xFF006064);

    // Define consistent surfaces based on brightness
    final isDark = brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF102027) : const Color(0xFFF4F7F6);
    final onSurfaceColor = isDark ? const Color(0xFFECEFF1) : const Color(0xFF263238);

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,

      // A. Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: seedColor,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: isDark ? seedColor.withOpacity(0.7) : seedColor.withOpacity(0.8), // Secondary is a variation of primary
        surface: surfaceColor,
        background: surfaceColor,
        error: const Color(0xFFB00020),
      ),

      // B. Premium Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark ? const Color(0xFF1E2A30) : Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        shadowColor: seedColor.withOpacity(0.08),
      ),

      // C. Premium Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF263238) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: seedColor, fontWeight: FontWeight.bold),
        prefixIconColor: seedColor.withOpacity(0.7),
      ),

      // D. Premium Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: seedColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.5),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seedColor,
          side: BorderSide(color: seedColor.withOpacity(0.5), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // E. FAB & Dialogs
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2A30) : Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // F. Typography
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: seedColor, fontWeight: FontWeight.w900, letterSpacing: -1),
        headlineMedium: TextStyle(color: seedColor, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: onSurfaceColor, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: onSurfaceColor, fontSize: 16),
        bodyMedium: TextStyle(color: onSurfaceColor.withOpacity(0.8), fontSize: 14),
      ),
    );
  }

  // Helper to get default
  static ThemeData get lightTheme => getTheme(type: AppThemeType.deepTeal, brightness: Brightness.light);
  static ThemeData get darkTheme => getTheme(type: AppThemeType.deepTeal, brightness: Brightness.dark);
}