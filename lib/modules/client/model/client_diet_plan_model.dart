import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';


class ClientDietPlanModel {
  final String id;
  final String clientId;
  final String masterPlanId;
  final String name;
  final String description;
  final List<String> guidelineIds;
  final List<MasterDayPlanModel> days;
  final DateTime? assignedDate;
  final bool isActive;
  final bool isArchived;
  final bool isDeleted;
  final String? revisedFromPlanId;
  final List<String> diagnosisIds;
  final String? linkedVitalsId;
  final int? followUpDays;
  final String clinicalNotes;
  final String complaints;
  final String instructions;
  final List<String> investigationIds;
  final List<String> suplimentIds;
  final bool isProvisional;
  final bool isFreezed;
  final bool isReadyToDeliver;

  // 🎯 NEW GOAL FIELDS
  final double dailyWaterGoal;       // Liters (e.g., 3.0)
  final double dailySleepGoal;       // Hours (e.g., 7.5)
  final int dailyStepGoal;           // Steps (e.g., 8000)
  final int dailyMindfulnessMinutes; // Minutes (e.g., 15)
  final List<String> assignedHabitIds; // IDs from Habit Master

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
    this.diagnosisIds = const [],
    this.linkedVitalsId = '',
    this.followUpDays = 0,
    this.clinicalNotes = '',
    this.complaints = '',
    this.instructions = '',
    this.investigationIds = const [],
    this.suplimentIds = const [],
    this.isProvisional = false,
    this.isFreezed = false,
    this.isReadyToDeliver = false,
    // 🎯 Defaults
    this.dailyWaterGoal = 3.0,
    this.dailySleepGoal = 7.0,
    this.dailyStepGoal = 5000,
    this.dailyMindfulnessMinutes = 10,
    this.assignedHabitIds = const [],
  });

  // For creating an editable copy
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

  ClientDietPlanModel copyWith({
    String? id,
    String? clientId,
    String? masterPlanId,
    String? name,
    String? description,
    List<String>? guidelineIds,
    List<MasterDayPlanModel>? days,
    DateTime? assignedDate,
    bool? isActive,
    bool? isArchived,
    bool? isDeleted,
    String? revisedFromPlanId,
    String? linkedVitalsId,
    List<String>? diagnosisIds,
    int? followUpDays,
    String? clinicalNotes,
    String? complaints,
    String? instructions,
    List<String>? investigationIds,
    List<String>? suplimentIds,
    bool? isProvisional,
    bool? isFreezed,
    bool? isReadyToDeliver,
    // 🎯 New Params
    double? dailyWaterGoal,
    double? dailySleepGoal,
    int? dailyStepGoal,
    int? dailyMindfulnessMinutes,
    List<String>? assignedHabitIds,
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
      linkedVitalsId: linkedVitalsId ?? this.linkedVitalsId,
      diagnosisIds: diagnosisIds ?? this.diagnosisIds,
      followUpDays: followUpDays ?? this.followUpDays,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      complaints: complaints ?? this.complaints,
      instructions: instructions ?? this.instructions,
      investigationIds: investigationIds ?? this.investigationIds,
      suplimentIds: suplimentIds ?? this.suplimentIds,
      isProvisional: isProvisional ?? this.isProvisional,
      isFreezed: isFreezed ?? this.isFreezed,
      isReadyToDeliver: isReadyToDeliver ?? this.isReadyToDeliver,
      // 🎯 Copy
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailySleepGoal: dailySleepGoal ?? this.dailySleepGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyMindfulnessMinutes: dailyMindfulnessMinutes ?? this.dailyMindfulnessMinutes,
      assignedHabitIds: assignedHabitIds ?? this.assignedHabitIds,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'masterPlanId': masterPlanId,
      'name': name,
      'description': description,
      'guidelineIds': guidelineIds,
      'dayPlan': days.isNotEmpty ? days.first.toFirestore() : null,
      'assignedDate': Timestamp.fromDate(assignedDate!),
      'isActive': isActive,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'revisedFromPlanId': revisedFromPlanId,
      'updatedAt': FieldValue.serverTimestamp(),
      'linkedVitalsId': linkedVitalsId,
      'diagnosisIds': diagnosisIds,
      'followUpDays': followUpDays,
      'clinicalNotes': clinicalNotes,
      'complaints': complaints,
      'instructions': instructions,
      'investigationIds': investigationIds,
      'suplimentIds': suplimentIds,
      'isProvisional': isProvisional,
      'isFreezed': isFreezed,
      'isReadyToDeliver' : isReadyToDeliver,
      // 🎯 Save
      'dailyWaterGoal': dailyWaterGoal,
      'dailySleepGoal': dailySleepGoal,
      'dailyStepGoal': dailyStepGoal,
      'dailyMindfulnessMinutes': dailyMindfulnessMinutes,
      'assignedHabitIds': assignedHabitIds,
    };
  }

  factory ClientDietPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final dayData = data['dayPlan'] as Map<String, dynamic>?;
    final MasterDayPlanModel? dayPlan = dayData != null ? MasterDayPlanModel.fromMap(data, 'd1') : null;

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
      revisedFromPlanId: data['revisedFromPlanId'],
      diagnosisIds: List<String>.from(data['diagnosisIds'] ?? []),
      linkedVitalsId: data['linkedVitalsId'],
      followUpDays: data['followUpDays'] ?? 0,
      clinicalNotes: data['clinicalNotes'] ?? '',
      complaints: data['complaints'] ?? '',
      instructions: data['instructions'] ?? '',
      investigationIds: List<String>.from(data['investigationIds'] ?? []),
      suplimentIds: List<String>.from(data['suplimentIds'] ?? []),
      isProvisional: data['isProvisional'] ?? false,
      isFreezed: data['isFreezed'] ?? false,
      isReadyToDeliver: data['isReadyToDeliver'] ?? false,
      // 🎯 Load
      dailyWaterGoal: (data['dailyWaterGoal'] as num?)?.toDouble() ?? 3.0,
      dailySleepGoal: (data['dailySleepGoal'] as num?)?.toDouble() ?? 7.0,
      dailyStepGoal: (data['dailyStepGoal'] as num?)?.toInt() ?? 5000,
      dailyMindfulnessMinutes: (data['dailyMindfulnessMinutes'] as num?)?.toInt() ?? 10,
      assignedHabitIds: List<String>.from(data['assignedHabitIds'] ?? []),
    );
  }
}