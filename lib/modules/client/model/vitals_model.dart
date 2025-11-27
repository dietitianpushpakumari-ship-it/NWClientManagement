import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';

class VitalsModel {
  final String id;
  final String clientId;
  final DateTime date;

  // --- Anthropometrics ---
  final double heightCm;
  final double bmi;
  final double idealBodyWeightKg;
  final double weightKg;
  final double bodyFatPercentage;
  final double? waistCm; // 🎯 NEW: Explicit Field
  final double? hipCm;   // 🎯 NEW: Explicit Field
  final Map<String, double> measurements; // Legacy/Extra measurements

  // --- Cardio & Vitals ---
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? spO2Percentage; // 🎯 NEW: Oxygen Saturation

  // --- Clinical & Lab ---
  final Map<String, String> labResults;
  final String? notes;
  final List<String> labReportUrls;

  // --- History & Profile ---
  final List<String> medicalHistory; // 🎯 NEW: List of conditions
  final String? medicalHistoryDurations;
  final List<String> diagnosis;      // 🎯 NEW: Current diagnosis
  final String? complaints;
  // 🎯 CHANGED: From String to List<PrescribedMedication>
  final List<PrescribedMedication> prescribedMedications;
  final String? foodAllergies;
  final String? restrictedDiet;

  // --- Lifestyle ---
  final String? foodHabit;
  final String? activityType;
  final Map<String, String>? otherLifestyleHabits; // Smoking/Alcohol

  // --- Metadata ---
  final List<String> assignedDietPlanIds;
  final bool isFirstConsultation;
  final String? existingMedication;

  const VitalsModel({
    required this.id,
    required this.clientId,
    required this.date,
    required this.heightCm,
    required this.bmi,
    required this.idealBodyWeightKg,
    required this.weightKg,
    required this.bodyFatPercentage,
    this.waistCm,
    this.hipCm,
    this.measurements = const {},

    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.spO2Percentage,
    this.prescribedMedications = const [],

    this.labResults = const {},
    this.notes,
    this.labReportUrls = const [],

    this.medicalHistory = const [],
    this.medicalHistoryDurations,
    this.diagnosis = const [],
    this.complaints,
    this.existingMedication,
    this.foodAllergies,
    this.restrictedDiet,

    this.foodHabit,
    this.activityType,
    this.otherLifestyleHabits,

    this.assignedDietPlanIds = const [],
    required this.isFirstConsultation,
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VitalsModel.fromMap(doc.id, data);
  }

  factory VitalsModel.fromMap(String id, Map<String, dynamic> map) {
    List<PrescribedMedication> meds = [];
    if (map['prescribedMedications'] != null) {
      meds = (map['prescribedMedications'] as List).map((m) => PrescribedMedication.fromMap(m)).toList();
    }
    return VitalsModel(
      id: id,
      clientId: map['clientId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // Anthro
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0.0,
      bmi: (map['bmi'] as num?)?.toDouble() ?? 0.0,
      idealBodyWeightKg: (map['idealBodyWeightKg'] as num?)?.toDouble() ?? 0.0,
      bodyFatPercentage: (map['bodyFatPercentage'] as num?)?.toDouble() ?? 0.0,
      waistCm: (map['waistCm'] as num?)?.toDouble(),
      hipCm: (map['hipCm'] as num?)?.toDouble(),
      measurements: Map<String, double>.from(map['measurements'] ?? {}),

      // Cardio
      bloodPressureSystolic: (map['bloodPressureSystolic'] as num?)?.toInt(),
      bloodPressureDiastolic: (map['bloodPressureDiastolic'] as num?)?.toInt(),
      heartRate: (map['heartRate'] as num?)?.toInt(),
      spO2Percentage: (map['spO2Percentage'] as num?)?.toDouble(),

      // Clinical
      labResults: Map<String, String>.from(map['labResults']?.map((k, v) => MapEntry(k, v.toString())) ?? {}),
      notes: map['notes'] as String?,
      labReportUrls: List<String>.from(map['labReportUrls'] ?? []),

      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      medicalHistoryDurations: map['medicalHistoryDurations'],
      diagnosis: List<String>.from(map['diagnosis'] ?? []),
      complaints: map['complaints'],
      prescribedMedications: meds,
      existingMedication: map['existingMedication'],
      foodAllergies: map['foodAllergies'],
      restrictedDiet: map['restrictedDiet'],

      // Lifestyle
      foodHabit: map['foodHabit'],
      activityType: map['activityType'],
      otherLifestyleHabits: Map<String, String>.from(map['otherLifestyleHabits'] ?? {}),

      // Metadata
      assignedDietPlanIds: List<String>.from(map['assignedDietPlanIds'] ?? []),
      isFirstConsultation: map['isFirstConsultation'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),

      // Anthro
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'idealBodyWeightKg': idealBodyWeightKg,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCm': waistCm,
      'hipCm': hipCm,
      'measurements': measurements,

      // Cardio
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'spO2Percentage': spO2Percentage,

      // Clinical
      'labResults': labResults,
      'notes': notes,
      'labReportUrls': labReportUrls,
      'medicalHistory': medicalHistory,
      'medicalHistoryDurations': medicalHistoryDurations,
      'diagnosis': diagnosis,
      'complaints': complaints,
      'existingMedication': existingMedication,
      'foodAllergies': foodAllergies,
      'restrictedDiet': restrictedDiet,
      'prescribedMedications': prescribedMedications.map((m) => m.toMap()).toList(),

      // Lifestyle
      'foodHabit': foodHabit,
      'activityType': activityType,
      'otherLifestyleHabits': otherLifestyleHabits,

      // Metadata
      'assignedDietPlanIds': assignedDietPlanIds,
      'isFirstConsultation': isFirstConsultation,
    };
  }
}