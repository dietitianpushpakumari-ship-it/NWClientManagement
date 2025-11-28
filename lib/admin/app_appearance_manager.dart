import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/app_theme.dart';
import 'package:nutricare_client_management/main.dart'; // For ThemeManager

class AppAppearanceScreen extends StatelessWidget {
  const AppAppearanceScreen({super.key});

  // Map to display colors in the grid (matching AppTheme)
  static final Map<AppThemeType, Color> _themePreviewColors = {
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
    AppThemeType.goldenHour: const Color(0xFFF57F17),
    AppThemeType.lavenderMist: const Color(0xFF512DA8),
    AppThemeType.chocolateBrown: const Color(0xFF3E2723),
    AppThemeType.steelBlue: const Color(0xFF455A64),
    AppThemeType.mintFresh: const Color(0xFF00695C),
    AppThemeType.berryCrush: const Color(0xFFA81B60),
    AppThemeType.charcoalBlack: const Color(0xFF212121),
    AppThemeType.copperRust: const Color(0xFFBF360C),
  };

  String _formatName(String name) {
    // Convert "deepTeal" to "Deep Teal"
    return name.replaceFirstMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').capitalize();
  }

  @override
  Widget build(BuildContext context) {
    // Access the ThemeManager
    final themeManager = Provider.of<ThemeManager>(context);
    final currentTheme = themeManager.currentTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Glow (Dynamic color based on selection)
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _themePreviewColors[currentTheme]!.withOpacity(0.2),
                    blurRadius: 80,
                    spreadRadius: 30,
                  )
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Custom Header
                _buildHeader(context),

                // 3. Theme Grid
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    children: [
                      _buildSectionTitle("Select Accent Color"),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: AppThemeType.values.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 0.7, // Taller to fit text
                        ),
                        itemBuilder: (context, index) {
                          final type = AppThemeType.values[index];
                          final color = _themePreviewColors[type] ?? Colors.grey;
                          final isSelected = type == currentTheme;

                          return GestureDetector(
                            onTap: () => themeManager.setTheme(type),
                            child: Column(
                              children: [
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: isSelected ? 12 : 4,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 3)
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Center(child: Icon(Icons.check, color: Colors.white))
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatName(type.name),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 40),
                      _buildSectionTitle("Display Mode"),
                      const SizedBox(height: 16),
                      _buildModeSelector(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("App Appearance", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    Text("Customize look & feel", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.palette_outlined, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildModeSelector(BuildContext context) {
    // Placeholder for future ThemeMode (System/Light/Dark)
    // Currently just visual since main.dart is forced to System.
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          _buildModeOption(context, "Light", Icons.wb_sunny_rounded, true),
          _buildModeOption(context, "Dark", Icons.nights_stay_rounded, false),
          _buildModeOption(context, "System", Icons.settings_brightness_rounded, false),
        ],
      ),
    );
  }

  Widget _buildModeOption(BuildContext context, String label, IconData icon, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Theme.of(context).primaryColor : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}