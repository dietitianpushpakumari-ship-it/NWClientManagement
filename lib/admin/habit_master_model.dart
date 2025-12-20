import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum HabitCategory { morning, evening, nutrition, mindfulness, movement, other }

class                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         HabitMasterModel {
  final String id;
  final String name; // e.g., "Morning Sunlight"
  final String description; // e.g., "Stand in direct sun for 15 mins"
  final String iconCode; // Store IconData as codePoint or string key
  final HabitCategory category;
  final bool isActive;
  final Map<String, String> titleLocalized;
  final Map<String, String> descriptionLocalized;

  const HabitMasterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCode, // We'll store string keys like 'sunny', 'water'
    required this.category,
    this.isActive = true,
    this.titleLocalized = const {},
    this.descriptionLocalized = const {},
  });

  // Convert String key to IconData for UI
  IconData get iconData {
    switch (iconCode) {
      case 'sunny': return Icons.wb_sunny;
      case 'water': return Icons.water_drop;
      case 'book': return Icons.menu_book;
      case 'walk': return Icons.directions_walk;
      case 'sleep': return Icons.bedtime;
      case 'phone': return Icons.phonelink_erase;
      case 'food': return Icons.restaurant;
      case 'yoga': return Icons.self_improvement;
      default: return Icons.check_circle_outline;
    }
  }

  factory HabitMasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    Map<String, String> localizedNames = {};
    if (data['nameLocalized'] is Map) {
      localizedNames = Map<String, String>.from(data['nameLocalized']);
    }

    Map<String, String> descriptionLocalized = {};
    if (data['descriptionLocalized'] is Map) {
      descriptionLocalized = Map<String, String>.from(data['descriptionLocalized']);
    }

    return HabitMasterModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconCode: data['iconCode'] ?? 'check',
      category: HabitCategory.values.firstWhere(
              (e) => e.name == (data['category'] ?? 'other'),
          orElse: () => HabitCategory.other
      ),
      isActive: data['isActive'] ?? true,
      titleLocalized: localizedNames,
      descriptionLocalized: descriptionLocalized
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':name,
      'description': description,
      'iconCode': iconCode,
      'category': category.name,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'nameLocalized': titleLocalized,
      'descriptionLocalized' : descriptionLocalized
    };
  }
}