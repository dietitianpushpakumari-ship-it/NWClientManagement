// lib/widgets/CustomGradientAppBar.dart
import 'package:flutter/material.dart';
import 'dart:ui'; // Needed for ImageFilter

/// A reusable custom AppBar replacement that applies the glass blur effect
/// and the elegant styling defined in the application's theme.
class CustomGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomGradientAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
  });

  // The height of the default AppBar is kToolbarHeight (56.0) + the height of the bottom widget.
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use a standard AppBar, but rely on the flexibleSpace property for the glass effect.
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      bottom: bottom,

      // 🎯 Set high elevation directly to maximize the shine effect
      elevation: 30.0,

      // 1. Set background to transparent for the custom layer to be visible
      backgroundColor: Colors.transparent,

      // 2. The Glass Layer (using Stack to apply solid color behind the blur)
      flexibleSpace: Stack(
        children: [
          // 🎯 LAYER 1: Solid Primary Color Base (The background color you requested)
          Container(
            color: colorScheme.primary,
          ),

          // 🎯 LAYER 2: Frosted Blur Layer (Blur + Semi-Transparent White Tint)
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                // Apply a light, semi-transparent white tint over the primary color base
                color: Colors.white.withOpacity(0.11),
              ),
            ),
          ),
        ],
      ),

      // Thicker Text Style applied directly to the title
      titleTextStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: Colors.white,
      ),

      // Ensure text remains white
      foregroundColor: Colors.white,
    );
  }
}