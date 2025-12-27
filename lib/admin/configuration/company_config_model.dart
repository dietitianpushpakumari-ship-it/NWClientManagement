import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyConfigModel {
  // 🎯 Operational Settings (Managed by Tenant Admin)
  final List<String> enabledModules;
  final bool isMaintenanceMode;
  final String? timeZone; // Example of another setting they might own

  // 🎯 Metadata
  final Timestamp? lastUpdated;
  final String? updatedBy;

  CompanyConfigModel({
    this.enabledModules = const [],
    this.isMaintenanceMode = false,
    this.timeZone,
    this.lastUpdated,
    this.updatedBy,
  });

  // 🏭 Factory: Create from Firestore
  factory CompanyConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CompanyConfigModel(
      enabledModules: List<String>.from(data['enabledModules'] ?? []),
      isMaintenanceMode: data['isMaintenanceMode'] ?? false,
      timeZone: data['timeZone'] as String?,
      lastUpdated: data['lastUpdated'] as Timestamp?,
      updatedBy: data['updatedBy'] as String?,
    );
  }

  // 📤 To Map: Prepare for Firestore Update
  Map<String, dynamic> toMap() {
    return {
      'enabledModules': enabledModules,
      'isMaintenanceMode': isMaintenanceMode,
      'timeZone': timeZone,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // 📋 CopyWith: For immutable updates
  CompanyConfigModel copyWith({
    List<String>? enabledModules,
    bool? isMaintenanceMode,
    String? timeZone,
    String? updatedBy,
  }) {
    return CompanyConfigModel(
      enabledModules: enabledModules ?? this.enabledModules,
      isMaintenanceMode: isMaintenanceMode ?? this.isMaintenanceMode,
      timeZone: timeZone ?? this.timeZone,
      lastUpdated: lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}