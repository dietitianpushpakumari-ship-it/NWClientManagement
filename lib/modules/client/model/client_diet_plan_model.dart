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
  final Map<String, String> suplimentIdsMap;
  final bool isProvisional;
  final bool isFreezed;
  final bool isReadyToDeliver;

  // 🎯 NEW GOAL FIELDS
  final double dailyWaterGoal;       // Liters (e.g., 3.0)
  final double dailySleepGoal;       // Hours (e.g., 7.5)
  final int dailyStepGoal;           // Steps (e.g., 8000)
  final int dailyMindfulnessMinutes; // Minutes (e.g., 15)
  final List<String> assignedHabitIds; // IDs from Habit Master
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? assignedDate; //
  final double? targetWeightKg;
  final String? sessionId;

  const ClientDietPlanModel({
    this.id = '',
    this.clientId = '',
    this.masterPlanId = '',
    this.name = '',
    this.description = '',
    this.guidelineIds = const [],
    this.days = const [],
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
    this.suplimentIdsMap = const {},
    this.isProvisional = false,
    this.isFreezed = false,
    this.isReadyToDeliver = false,
    // 🎯 Defaults
    this.dailyWaterGoal = 3.0,
    this.dailySleepGoal = 7.0,
    this.dailyStepGoal = 5000,
    this.dailyMindfulnessMinutes = 10,
    this.assignedHabitIds = const [],
    this.createdAt,
    this.updatedAt,
    this.assignedDate,
    this.targetWeightKg,
    this.sessionId,
  });

  // For creating an editable copy
  factory ClientDietPlanModel.fromMaster(
      MasterDietPlanModel masterPlan,
      String clientId,
      List<String> guidelineIds,
      ) {
    final now = Timestamp.now(); // 🎯 Get current time as Firestore Timestamp

    return ClientDietPlanModel(
      id: '',
      clientId: clientId,
      masterPlanId: masterPlan.id,
      name: masterPlan.name,
      description: masterPlan.description,
      guidelineIds: guidelineIds,
      days: masterPlan.days,

      // 🎯 Use Timestamp for consistency with your fromMap/toMap logic
      assignedDate: now,
      createdAt: now,
      updatedAt: now,

      isProvisional: true, // New plans from master usually start as drafts
      isActive: true,
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'masterPlanId': masterPlanId,
      'name': name,
      'description': description,
      'guidelineIds': guidelineIds,

      // 🎯 If days is a list of objects with their own toFirestore
      'dayPlan': days.isNotEmpty ? (days.first is Map ? days.first : days.first.toFirestore()) : null,
      'days': days.map((e) => e is Map ? e : e.toFirestore()).toList(),

      // 🎯 FIX: Robust Date Handling
      'assignedDate': assignedDate ?? FieldValue.serverTimestamp(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Ensure creation date is preserved
      'updatedAt': FieldValue.serverTimestamp(),             // Always update system time

      'isActive': isActive,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'isProvisional': isProvisional,
      'isFreezed': isFreezed,
      'isReadyToDeliver': isReadyToDeliver,

      'revisedFromPlanId': revisedFromPlanId,
      'linkedVitalsId': linkedVitalsId,
      'diagnosisIds': diagnosisIds,
      'investigationIds': investigationIds,

      'followUpDays': followUpDays,
      'clinicalNotes': clinicalNotes,
      'complaints': complaints,
      'instructions': instructions,
      'suplimentIdsMap': suplimentIdsMap,

      // 🎯 Goals & Metrics
      'dailyWaterGoal': dailyWaterGoal,
      'dailySleepGoal': dailySleepGoal,
      'dailyStepGoal': dailyStepGoal,
      'targetWeightKg': targetWeightKg, // 🎯 Critical for your progress bars
      'dailyMindfulnessMinutes': dailyMindfulnessMinutes,
      'assignedHabitIds': assignedHabitIds,
      'sessionId':sessionId,
    };
  }
  factory ClientDietPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 🎯 Handle the 'days' list or 'dayPlan' fallback
    List<MasterDayPlanModel> parsedDays = [];
    if (data['days'] != null) {
      parsedDays = (data['days'] as List)
          .map((d) => MasterDayPlanModel.fromMap(d as Map<String, dynamic>, ''))
          .toList();
    } else if (data['dayPlan'] != null) {
      // Fallback if only single dayPlan exists
      parsedDays = [MasterDayPlanModel.fromMap(data['dayPlan'], 'd1')];
    }

    return ClientDietPlanModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      masterPlanId: data['masterPlanId'] ?? '',
      name: data['name'] ?? 'Untitled Plan',
      description: data['description'] ?? '',
      guidelineIds: List<String>.from(data['guidelineIds'] ?? []),
      days: parsedDays,

      // 🎯 FIX: Keep as Timestamp to match model definition
      assignedDate: data['assignedDate'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,

      isActive: data['isActive'] ?? true,
      isArchived: data['isArchived'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isProvisional: data['isProvisional'] ?? false,
      isFreezed: data['isFreezed'] ?? false,
      isReadyToDeliver: data['isReadyToDeliver'] ?? false,

      revisedFromPlanId: data['revisedFromPlanId'],
      diagnosisIds: List<String>.from(data['diagnosisIds'] ?? []),
      linkedVitalsId: data['linkedVitalsId'],
      followUpDays: data['followUpDays'] ?? 0,
      clinicalNotes: data['clinicalNotes'] ?? '',
      complaints: data['complaints'] ?? '',
      instructions: data['instructions'] ?? '',
      investigationIds: List<String>.from(data['investigationIds'] ?? []),
      suplimentIdsMap: Map<String, String>.from(data['suplimentIdsMap'] ?? {}),

      // 🎯 Goals & Metrics
      targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble(),
      dailyWaterGoal: (data['dailyWaterGoal'] as num?)?.toDouble() ?? 3.0,
      dailySleepGoal: (data['dailySleepGoal'] as num?)?.toDouble() ?? 7.0,
      dailyStepGoal: (data['dailyStepGoal'] as num?)?.toInt() ?? 5000,
      dailyMindfulnessMinutes: (data['dailyMindfulnessMinutes'] as num?)?.toInt() ?? 10,
      assignedHabitIds: List<String>.from(data['assignedHabitIds'] ?? []),
      sessionId: data['sessionId']
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'name': name,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedDate': assignedDate ?? FieldValue.serverTimestamp(),
      'suplimentIdsMap': suplimentIdsMap,
      'diagnosisIds': diagnosisIds,
      'guidelineIds': guidelineIds,
      'dailyWaterGoal': dailyWaterGoal,
      'dailyStepGoal': dailyStepGoal,
      'dailySleepGoal': dailySleepGoal,
      'targetWeightKg': targetWeightKg,
      'isProvisional': isProvisional,
      'isDeleted': isDeleted,
      'sessionId':sessionId,
      'days': days.map((day) => day.toFirestore()).toList(), // Ensure your day models also have toMap() if they are objects
    };
  }

  // Helper to create object from Firestore
// Fixed Factory to prevent "Null Receiver" errors
  factory ClientDietPlanModel.fromMap(Map<String, dynamic> map, String id) {
    // 🎯 Parse days safely
    List<MasterDayPlanModel> parsedDays = [];
    if (map['days'] != null && map['days'] is List) {
      parsedDays = (map['days'] as List)
          .map((d) => MasterDayPlanModel.fromMap(d as Map<String, dynamic>, ''))
          .toList();
    }

    return ClientDietPlanModel(
      id: id,
      clientId: map['clientId'] ?? '',
      name: map['name'] ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      assignedDate: map['assignedDate'] as Timestamp?,
      suplimentIdsMap: Map<String, String>.from(map['suplimentIdsMap'] ?? {}),
      diagnosisIds: List<String>.from(map['diagnosisIds'] ?? []),
      guidelineIds: List<String>.from(map['guidelineIds'] ?? []),
      dailyWaterGoal: (map['dailyWaterGoal'] as num?)?.toDouble() ?? 3.0,
      dailyStepGoal: (map['dailyStepGoal'] as num?)?.toInt() ?? 5000,
      dailySleepGoal: (map['dailySleepGoal'] as num?)?.toDouble() ?? 7.0,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble(),
      isProvisional: map['isProvisional'] ?? true,
      days: parsedDays,
      sessionId: map['sessionId']
    );
  }
  // Required for the Duplication feature
  ClientDietPlanModel copyWith({
    String? id,
    String? clientId,
    String? masterPlanId,
    String? name,
    String? description,
    Timestamp? assignedDate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<MasterDayPlanModel>? days,
    Map<String, String>? suplimentIdsMap,
    List<String>? diagnosisIds,
    List<String>? guidelineIds,
    List<String>? investigationIds,
    List<String>? assignedHabitIds,
    double? targetWeightKg,
    double? dailyWaterGoal,
    double? dailySleepGoal,
    int? dailyStepGoal,
    int? dailyMindfulnessMinutes,
    bool? isProvisional,
    bool? isActive,
    bool? isArchived,
    bool? isDeleted,
    bool? isFreezed,
    bool? isReadyToDeliver,
    String? revisedFromPlanId,
    String? linkedVitalsId,
    String? clinicalNotes,
    String? complaints,
    String? instructions,
    int? followUpDays,
    String? sessionId
  }) {
    return ClientDietPlanModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      masterPlanId: masterPlanId ?? this.masterPlanId,
      name: name ?? this.name,
      description: description ?? this.description,
      assignedDate: assignedDate ?? this.assignedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
      suplimentIdsMap: suplimentIdsMap ?? this.suplimentIdsMap,
      diagnosisIds: diagnosisIds ?? this.diagnosisIds,
      guidelineIds: guidelineIds ?? this.guidelineIds,
      investigationIds: investigationIds ?? this.investigationIds,
      assignedHabitIds: assignedHabitIds ?? this.assignedHabitIds,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailySleepGoal: dailySleepGoal ?? this.dailySleepGoal,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyMindfulnessMinutes: dailyMindfulnessMinutes ?? this.dailyMindfulnessMinutes,
      isProvisional: isProvisional ?? this.isProvisional,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      isFreezed: isFreezed ?? this.isFreezed,
      isReadyToDeliver: isReadyToDeliver ?? this.isReadyToDeliver,
      revisedFromPlanId: revisedFromPlanId ?? this.revisedFromPlanId,
      linkedVitalsId: linkedVitalsId ?? this.linkedVitalsId,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      complaints: complaints ?? this.complaints,
      instructions: instructions ?? this.instructions,
      followUpDays: followUpDays ?? this.followUpDays,
      sessionId: sessionId ?? this.sessionId
    );
  }
}