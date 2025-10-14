// lib/models/client_diet_plan_model.dart (REVISED)

import 'package:cloud_firestore/cloud_firestore.dart';
// 🎯 NOTE: Adjust import paths for your existing models
import 'diet_plan_item_model.dart' show MasterDietPlanModel, MasterDayPlanModel;

class ClientDietPlanModel {
  final String id;
  final String clientId;
  final String masterPlanId;
  final String name;
  final String description;
  final List<String> guidelineIds;
  final List<MasterDayPlanModel> days; // The plan content
  final DateTime? assignedDate;
  final bool isActive;
  final bool isArchived;
  final bool isDeleted;
  final String? revisedFromPlanId;

  const ClientDietPlanModel({
    this.id = '',
    this.clientId = '',
    this.masterPlanId = '',
    this.name = '',
    this.description = '',
    this.guidelineIds = const [],
    this.days = const [],
    this.assignedDate,
    this.isActive = true,
    this.isArchived = false,
    this.isDeleted = false,
    this.revisedFromPlanId,
  });

  // For creating an editable copy during assignment
  factory ClientDietPlanModel.fromMaster(
      MasterDietPlanModel masterPlan,
      String clientId,
      List<String> guidelineIds,
      ) {
    return ClientDietPlanModel(
      id: '',
      clientId: clientId,
      masterPlanId: masterPlan.id,
      name: masterPlan.name,
      description: masterPlan.description,
      guidelineIds: guidelineIds,
      days: masterPlan.days,
      assignedDate: DateTime.now(),
      isActive: true,
    );
  }

  // Used for editing/updating status
  ClientDietPlanModel copyWith({
    String? id, String? clientId, String? masterPlanId, String? name,
    String? description, List<String>? guidelineIds, List<MasterDayPlanModel>? days,
    DateTime? assignedDate, bool? isActive, bool? isArchived, bool? isDeleted,
    String? revisedFromPlanId,
  }) {
    return ClientDietPlanModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      masterPlanId: masterPlanId ?? this.masterPlanId,
      name: name ?? this.name,
      description: description ?? this.description,
      guidelineIds: guidelineIds ?? this.guidelineIds,
      days: days ?? this.days,
      assignedDate: assignedDate ?? this.assignedDate,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      revisedFromPlanId: revisedFromPlanId ?? this.revisedFromPlanId,
    );
  }

  // TO FIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'masterPlanId': masterPlanId,
      'name': name,
      'description': description,
      'guidelineIds': guidelineIds,
      // Embedding the single day plan directly
      'dayPlan': days.isNotEmpty ? days.first.toFirestore() : null,
      'assignedDate': Timestamp.fromDate(assignedDate!),
      'isActive': isActive,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'revisedFromPlanId': revisedFromPlanId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // FROM FIRESTORE
  factory ClientDietPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final dayData = data['dayPlan'] as Map<String, dynamic>?;

    // 🎯 FIX: Correctly call MasterDayPlanModel.fromMap on the embedded 'dayPlan' map
    final MasterDayPlanModel? dayPlan = dayData != null
        ? MasterDayPlanModel.fromMap(data, 'd1')
        : null;

    return ClientDietPlanModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      masterPlanId: data['masterPlanId'] ?? '',
      name: data['name'] ?? 'Untitled Plan',
      description: data['description'] ?? '',
      guidelineIds: List<String>.from(data['guidelineIds'] ?? []),
      days: dayPlan != null ? [dayPlan] : [],
      assignedDate: (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      isArchived: data['isArchived'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      revisedFromPlanId: data['revisedFromPlanId'] as String?,
    );
  }
  ClientDietPlanModel clone() {
    return ClientDietPlanModel(
      id: '', // Crucial: Reset ID for a new Firestore document
      name: 'CLONE of ${this.name}',
      description: this.description,
      clientId: this.clientId,
      isActive: this.isActive,
      // Assuming all nested model lists/objects are immutable, a shallow copy
      // of the lists is sufficient for the structure to be identical but independent.
      days: List.from(this.days.map((day) => day.copyWith(meals: List.from(day.meals)))),
    );
  }

}