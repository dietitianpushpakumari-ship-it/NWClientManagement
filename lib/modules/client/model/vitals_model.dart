//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/modules/medical/models/prescription_model.dart';

class VitalsModel {
  final String id;
  final String clientId;
  final DateTime date;
  final String? sessionId;

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


  // --- History & Profile (UPDATED FIELDS) ---

  final List<String> foodAllergies;
  final String? restrictedDiet;


  // 🎯 CHANGE: GI Details changed to Map<String, String>
  final Map<String, String>? giDetails;

  // 🎯 CHANGE: Water Intake changed to Map<String, String>
  final Map<String, String>? waterIntake;
  final Map<String, double> labResults;
  // 🎯 CHANGE: Caffeine Intake changed to Map<String, String>
  final Map<String, String> medicalHistory;
  final Map<String, String> prescribedMedications;
  final Map<String, String>? caffeineIntake;
  final Map<String, String>? clinicalComplaints; // Complaint: Detail/Severity
  final Map<String, String>? nutritionDiagnoses; // Diagnosis: Etiology/Related Factor
  final Map<String, String>? clinicalNotes;
  final Map<String, String>? clinicalGuidelines;
// 🎯 NEW FIELDS FOR ASSESSMENT
  final List<PrescribedMedicine> medications; // New Rx (List of Objects)
  final List<String> labTestOrders;
  // 🎯 NEW: Behavioral/Status
  final int? stressLevel;
  final String? sleepQuality;
  final String? menstrualStatus;


  // --- Lifestyle ---
  final String? foodHabit;
  final String? activityType;
  final Map<String, String>? otherLifestyleHabits;

  final bool isFirstConsultation;


  const VitalsModel({
    required this.id,
    required this.clientId,
    required this.date,
    required this.heightCm,
     this.bmi = 0,
     this.idealBodyWeightKg =0,
    required this.weightKg,
    required this.bodyFatPercentage,
    this.waistCm,
    this.hipCm,
    this.measurements = const {},
    this.sessionId,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.spO2Percentage,
    this.prescribedMedications = const {},
    this.medications = const [],
    this.labTestOrders = const [],

    this.labResults = const {},

    this.medicalHistory = const {},
    this.foodAllergies = const [],
    this.restrictedDiet,
    this.clinicalGuidelines,
    this.giDetails,
    this.waterIntake,
    this.caffeineIntake,
    this.stressLevel,
    this.sleepQuality,
    this.menstrualStatus,
    this.foodHabit,
    this.activityType,
    this.otherLifestyleHabits,
    required this.isFirstConsultation,
    this.clinicalComplaints,
    this.nutritionDiagnoses,
    this.clinicalNotes,
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VitalsModel.fromMap(doc.id, data);
  }

  factory VitalsModel.fromMap(String id, Map<String, dynamic> map) {


    Map<String, String> castToMap(dynamic data) {
      if (data == null) return {};
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      if (data is List) {
        // Convert old List ['A', 'B'] to New Map {'A': 'Not specified', 'B': 'Not specified'}
        return { for (var item in data) item.toString() : "Not specified" };
      }
      return {};
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
      sessionId: map['sessionId'],
      foodAllergies: List<String>.from(map['foodAllergies'] ?? []),
      restrictedDiet: map['restrictedDiet'],

      // Behavioral
      stressLevel: (map['stressLevel'] as num?)?.toInt(),
      sleepQuality: map['sleepQuality'],
      menstrualStatus: map['menstrualStatus'],

      // Lifestyle
      foodHabit: map['foodHabit'],
      activityType: map['activityType'],
      isFirstConsultation: map['isFirstConsultation'] ?? false,
      medicalHistory: castToMap(map['medicalHistory']), // Fixes the mismatch
      clinicalComplaints: castToMap(map['clinicalComplaints']),
      nutritionDiagnoses: castToMap(map['nutritionDiagnoses']),
      clinicalNotes: castToMap(map['clinicalNotes']),
      clinicalGuidelines: map['clinicalGuidelines'] != null ? Map<String, String>.from(map['clinicalGuidelines']) : null,
      medications: (map['medications'] as List<dynamic>?)
          ?.map((x) => PrescribedMedicine.fromMap(x as Map<String, dynamic>))
          .toList() ?? [],
      labTestOrders: List<String>.from(map['labTests'] ?? []),
      prescribedMedications: Map<String, String>.from(map['prescribedMedications'] ?? {}),
      giDetails: Map<String, String>.from(map['giDetails'] ?? {}),
      caffeineIntake: Map<String, String>.from(map['caffeineIntake'] ?? {}),
      otherLifestyleHabits: Map<String, String>.from(map['otherLifestyleHabits'] ?? {}),
      waterIntake: Map<String, String>.from(map['waterIntake'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
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

      // History & Profile Fields
      'medicalHistory': medicalHistory,
      'foodAllergies': foodAllergies,
      'restrictedDiet': restrictedDiet,
      'prescribedMedications': prescribedMedications,
      'clinicalGuidelines': clinicalGuidelines,

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
      'sessionId': sessionId,
      'isFirstConsultation': isFirstConsultation,
      // 🎯 NEW JSON MAPPING
      'clinicalComplaints': clinicalComplaints,
      'nutritionDiagnoses': nutritionDiagnoses,
      'clinicalNotes': clinicalNotes,

      'medications': medications.map((x) => x.toMap()).toList(),
      'labTests': labTestOrders,
    };
  }
  VitalsModel copyWith({
    String? id,
    String? clientId,
    String? sessionId,
    DateTime? date,
    double? weightKg,
    double? heightCm,
    double? bmi,
    double? bodyFatPercentage,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    int? heartRate,
    int? spo2,
    double? temperature,
    Map<String, String>? clinicalComplaints,
    Map<String, String>? nutritionDiagnoses,
    Map<String, String>? clinicalNotes,
    List<PrescribedMedicine>? medications,
    List<String>? labTestOrders,
    bool? isFirstConsultation,
    Map<String, String>? clinicalGuidelines,
    Map<String, String>? medicalHistory
    // Add other fields if your model has them (e.g., stressLevel, sleepQuality)
  }) {
    return VitalsModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      sessionId: sessionId ?? this.sessionId,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bmi: bmi ?? this.bmi,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      bloodPressureSystolic: bloodPressureSystolic ?? this.bloodPressureSystolic,
      bloodPressureDiastolic: bloodPressureDiastolic ?? this.bloodPressureDiastolic,
      heartRate: heartRate ?? this.heartRate,
      clinicalComplaints: clinicalComplaints ?? this.clinicalComplaints,
      nutritionDiagnoses: nutritionDiagnoses ?? this.nutritionDiagnoses,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      medications: medications ?? this.medications,
      labTestOrders: labTestOrders ?? this.labTestOrders,
      isFirstConsultation: isFirstConsultation ?? this.isFirstConsultation, idealBodyWeightKg: 0,
      clinicalGuidelines: clinicalGuidelines ?? this.clinicalGuidelines,
        medicalHistory: medicalHistory ?? this.medicalHistory
    );
  }
}