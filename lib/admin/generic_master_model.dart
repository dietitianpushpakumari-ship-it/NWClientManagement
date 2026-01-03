import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// A universal model for master data.
/// Replaces: HabitMasterModel, DiseaseMasterModel, ClinicalItemModel, etc.
class GenericMasterModel {
  final String id;
  final String name;                // Primary Name (English)
  final String description;         // Optional description
  final String category;            // Optional grouping (e.g., 'morning' for habits)
  final String iconCode;                // Optional code (e.g., icon key 'sunny', or short code)
  final Map<String, String> nameLocalized; // Localized names
  final bool isActive;
  final bool isDeleted;
  final Map<String, dynamic> metadata; // Any extra data specific to a type

  const GenericMasterModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = '',
    this.iconCode = '',
    this.nameLocalized = const {},
    this.isActive = true,
    this.isDeleted = false,
    this.metadata = const {},
  });

  // --- Helpers for Habits (Mapping code to Icon) ---
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
      case 'meditation': return Icons.spa;
      default: return Icons.check_circle_outline;
    }
  }

  // --- Firestore Factory ---
  factory GenericMasterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Handle map casting safely
    Map<String, String> localized = {};
    if (data['nameLocalized'] is Map) {
      localized = Map<String, String>.from(data['nameLocalized']);
    }

    // Handle Legacy Field Mapping (e.g., 'enName' from DiseaseMaster)
    String primaryName = data['name'] ?? data['enName'] ?? '';

    // Handle Legacy Habit Fields
    String iconCode = data['code'] ?? data['iconCode'] ?? '';

    return GenericMasterModel(
      id: doc.id,
      name: primaryName,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      iconCode: iconCode,
      nameLocalized: localized,
      isActive: data['isActive'] ?? true,
      isDeleted: data['isDeleted'] ?? false,
      metadata: data['metadata'] ?? {},
    );
  }

  // --- To Map ---
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'code': iconCode, // Stores iconCode here
      'nameLocalized': nameLocalized,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  GenericMasterModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? code,
    Map<String, String>? nameLocalized,
    bool? isActive,
    bool? isDeleted,
    Map<String, dynamic>? metadata,
  }) {
    return GenericMasterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      iconCode: code ?? this.iconCode,
      nameLocalized: nameLocalized ?? this.nameLocalized,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      metadata: metadata ?? this.metadata,
    );
  }
}