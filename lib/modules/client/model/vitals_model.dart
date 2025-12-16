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
  final double? waistCm;
  final double? hipCm;
  final Map<String, double> measurements;

  // --- Cardio & Vitals ---
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? spO2Percentage;

  // --- Clinical & Lab ---
  final Map<String, double> labResults;
  final String? notes;
  final List<String> labReportUrls;

  // --- History & Profile (UPDATED FIELDS) ---
  final Map<String, String> medicalHistory;
  final List<String> diagnosis;
  final String? complaints;
  final List<PrescribedMedication> prescribedMedications;
  final List<String> foodAllergies;
  final String? restrictedDiet;
  final String? existingMedication;

  // 🎯 CHANGE: GI Details changed to Map<String, String>
  final Map<String, String>? giDetails;

  // 🎯 CHANGE: Water Intake changed to Map<String, String>
  final Map<String, String>? waterIntake;

  // 🎯 CHANGE: Caffeine Intake changed to Map<String, String>
  final Map<String, String>? caffeineIntake;
  final Map<String, String>? clinicalComplaints; // Complaint: Detail/Severity
  final Map<String, String>? nutritionDiagnoses; // Diagnosis: Etiology/Related Factor
  final Map<String, String>? clinicalNotes;

  // 🎯 NEW: Behavioral/Status
  final int? stressLevel;
  final String? sleepQuality;
  final String? menstrualStatus;


  // --- Lifestyle ---
  final String? foodHabit;
  final String? activityType;
  final Map<String, String>? otherLifestyleHabits;

  // --- Metadata ---
  final List<String> assignedDietPlanIds;
  final bool isFirstConsultation;


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

    this.medicalHistory = const {},
    this.diagnosis = const [],
    this.complaints,
    this.existingMedication,
    this.foodAllergies = const [],
    this.restrictedDiet,

    // 🎯 INITIALIZATION UPDATED
    this.giDetails,
    this.waterIntake,
    this.caffeineIntake,

    this.stressLevel,
    this.sleepQuality,
    this.menstrualStatus,

    // Lifestyle
    this.foodHabit,
    this.activityType,
    this.otherLifestyleHabits,

    this.assignedDietPlanIds = const [],
    required this.isFirstConsultation,
    // 🎯 NEW PARAMETERS
    this.clinicalComplaints,
    this.nutritionDiagnoses,
    this.clinicalNotes,
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
      labResults: Map<String, double>.from(
        (map['labResults'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      notes: map['notes'] as String?,
      labReportUrls: List<String>.from(map['labReportUrls'] ?? []),

      // History & Profile Fields
      medicalHistory: Map<String, String>.from(map['medicalHistory'] ?? {}),
      diagnosis: List<String>.from(map['diagnosis'] ?? []),
      complaints: map['complaints'],
      prescribedMedications: meds,
      existingMedication: map['existingMedication'],
      foodAllergies: List<String>.from(map['foodAllergies'] ?? []),
      restrictedDiet: map['restrictedDiet'],

      // 🎯 UPDATED FROM MAP
      giDetails: Map<String, String>.from(map['giDetails'] ?? {}),
      waterIntake: Map<String, String>.from(map['waterIntake'] ?? {}),
      caffeineIntake: Map<String, String>.from(map['caffeineIntake'] ?? {}),

      // Behavioral
      stressLevel: (map['stressLevel'] as num?)?.toInt(),
      sleepQuality: map['sleepQuality'],
      menstrualStatus: map['menstrualStatus'],

      // Lifestyle
      foodHabit: map['foodHabit'],
      activityType: map['activityType'],
      otherLifestyleHabits: Map<String, String>.from(map['otherLifestyleHabits'] ?? {}),

      // Metadata
      assignedDietPlanIds: List<String>.from(map['assignedDietPlanIds'] ?? []),
      isFirstConsultation: map['isFirstConsultation'] ?? false,
      // 🎯 NEW JSON MAPPING (Casting to Map<String, String>)
      clinicalComplaints: (map['clinicalComplaints'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      nutritionDiagnoses: (map['nutritionDiagnoses'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      clinicalNotes: (map['clinicalNotes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
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

      // History & Profile Fields
      'medicalHistory': medicalHistory,
      'diagnosis': diagnosis,
      'complaints': complaints,
      'existingMedication': existingMedication,
      'foodAllergies': foodAllergies,
      'restrictedDiet': restrictedDiet,
      'prescribedMedications': prescribedMedications.map((m) => m.toMap()).toList(),

      // 🎯 UPDATED TO MAP
      'giDetails': giDetails,
      'waterIntake': waterIntake,
      'caffeineIntake': caffeineIntake,

      // Behavioral
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
      'menstrualStatus': menstrualStatus,

      // Lifestyle
      'foodHabit': foodHabit,
      'activityType': activityType,
      'otherLifestyleHabits': otherLifestyleHabits,

      // Metadata
      'assignedDietPlanIds': assignedDietPlanIds,
      'isFirstConsultation': isFirstConsultation,
      // 🎯 NEW JSON MAPPING
      'clinicalComplaints': clinicalComplaints,
      'nutritionDiagnoses': nutritionDiagnoses,
      'clinicalNotes': clinicalNotes,
    };
  }
}