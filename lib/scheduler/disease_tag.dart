// lib/models/enums.dart

import 'package:flutter/material.dart';

enum ContentType {
  healthyTip('Healthy Tip', Icons.local_florist),
  foodMyth('Food Myth', Icons.question_mark),
  recipe('Recipe', Icons.restaurant);

  final String label;
  final IconData icon;
  const ContentType(this.label, this.icon);

  static ContentType fromName(String name) {
    return values.firstWhere(
          (e) => e.name == name,
      orElse: () => healthyTip,
    );
  }
}

enum DiseaseTag {
  general('General', Colors.blue),
  diabetes('Diabetes', Colors.red),
  htn('Hypertension (HTN)', Colors.purple),
  thyroid('Thyroid Issues', Colors.orange);

  final String label;
  final Color color;
  const DiseaseTag(this.label, this.color);

  static DiseaseTag fromName(String name) {
    return values.firstWhere(
          (e) => e.name == name,
      orElse: () => general,
    );
  }
}

enum ContentFrequency {
  daily('Daily', 1),
  twiceWeekly('Twice Weekly', 3), // e.g., every 3.5 days
  weekly('Weekly', 7),
  biWeekly('Bi-Weekly', 14);

  final String label;
  final int daysInterval;
  const ContentFrequency(this.label, this.daysInterval);

  static ContentFrequency fromName(String name) {
    return values.firstWhere(
          (e) => e.name == name,
      orElse: () => weekly,
    );
  }
}