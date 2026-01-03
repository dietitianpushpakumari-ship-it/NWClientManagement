import 'package:flutter/material.dart';

/// Categories for Habits
enum HabitCategory {
  morning,
  evening,
  nutrition,
  mindfulness,
  movement,
  other
}

/// Extension to get nice display names and icons for the UI
extension HabitCategoryExt on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.morning: return "Morning Routine";
      case HabitCategory.evening: return "Evening Routine";
      case HabitCategory.nutrition: return "Nutrition & Diet";
      case HabitCategory.mindfulness: return "Mindfulness";
      case HabitCategory.movement: return "Movement & Activity";
      case HabitCategory.other: return "Other";
    }
  }

  IconData get icon {
    switch (this) {
      case HabitCategory.morning: return Icons.wb_sunny_outlined;
      case HabitCategory.evening: return Icons.nights_stay_outlined;
      case HabitCategory.nutrition: return Icons.restaurant_menu;
      case HabitCategory.mindfulness: return Icons.self_improvement;
      case HabitCategory.movement: return Icons.directions_run;
      case HabitCategory.other: return Icons.circle_outlined;
    }
  }
}