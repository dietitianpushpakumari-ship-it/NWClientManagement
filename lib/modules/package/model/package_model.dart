// lib/modules/package/model/package_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum PackageCategory {
  basic,
  standard,
  premium,
  custom;

  String get displayName => name[0].toUpperCase() + name.substring(1);
}

class PackageModel {
  final String id;
  final String name;
  final String description;

  // 💰 Pricing & Billing
  final double price;
  final double? originalPrice;
  final bool isTaxInclusive;

  // ⏳ Duration & Scope
  final int durationDays;
  final int consultationCount;
  final int freeSessions;

  // 📋 Features & Filtering
  final List<String> inclusions;       // Stores Names (Snapshot for Display)
  final List<String> inclusionIds;     // 🎯 NEW: Stores Master IDs (For Logic)
  final List<String> programFeatureIds;
  final List<String> targetConditions;

  // 🎨 UI & Status
  final bool isActive;
  final PackageCategory category;
  final String? colorCode;

  PackageModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.isTaxInclusive = true,
    required this.durationDays,
    this.consultationCount = 0,
    this.freeSessions = 0,
    this.inclusions = const [],
    this.inclusionIds = const [], // 🎯 Initialize
    this.programFeatureIds = const [],
    this.targetConditions = const [],
    this.isActive = true,
    this.category = PackageCategory.basic,
    this.colorCode,
  });

  factory PackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final String categoryString = data['category'] ?? 'basic';
    final PackageCategory packageCategory = PackageCategory.values.firstWhere(
          (e) => e.name == categoryString.toLowerCase(),
      orElse: () => PackageCategory.basic,
    );

    return PackageModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      isTaxInclusive: data['isTaxInclusive'] ?? true,
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 0,
      consultationCount: (data['consultationCount'] as num?)?.toInt() ?? 0,
      freeSessions: (data['freeSessions'] as num?)?.toInt() ?? 0,

      inclusions: List<String>.from(data['inclusions'] ?? []),
      inclusionIds: List<String>.from(data['inclusionIds'] ?? []), // 🎯 Load IDs
      programFeatureIds: List<String>.from(data['programFeatureIds'] ?? []),
      targetConditions: List<String>.from(data['targetConditions'] ?? []),

      isActive: data['isActive'] ?? true,
      category: packageCategory,
      colorCode: data['colorCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'isTaxInclusive': isTaxInclusive,
      'durationDays': durationDays,
      'consultationCount': consultationCount,
      'freeSessions': freeSessions,
      'inclusions': inclusions,
      'inclusionIds': inclusionIds, // 🎯 Save IDs
      'programFeatureIds': programFeatureIds,
      'targetConditions': targetConditions,
      'isActive': isActive,
      'category': category.name,
      'colorCode': colorCode,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  int get totalSessions => consultationCount + freeSessions;

  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).round();
  }
}