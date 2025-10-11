// lib/models/vitals_model.dart (UPDATED)

import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsModel {
  final String id;
  final String clientId;
  final DateTime date;

  // --- Physical Vitals ---
  final double weightKg;
  final double bodyFatPercentage;
  final Map<String, double> measurements; // e.g., {'waistCm': 80.0, 'chestCm': 100.0}

  // --- Lab Results (NEW) ---
  // Stores complex lab data as key-value pairs (e.g., {'hba1c': '5.7', 'creatinine': '0.9'})
  // We use String for the value to accommodate units or categorical results.
  final Map<String, String> labResults;

  final String? notes;
  final List<String> labReportUrls;

  VitalsModel({
    required this.id,
    required this.clientId,
    required this.date,
    required this.weightKg,
    this.bodyFatPercentage = 0.0,
    this.measurements = const {},
    this.labResults = const {}, // Initialize NEW field
    this.notes,
    this.labReportUrls = const [],
  });

  factory VitalsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VitalsModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble() ?? 0.0,
      measurements: Map<String, double>.from(data['measurements'] ?? {}),
      labResults: Map<String, String>.from(data['labResults'] ?? {}), // Read NEW field
      notes: data['notes'],
      labReportUrls: List<String>.from(data['labReportUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': date,
      'weightKg': weightKg,
      'bodyFatPercentage': bodyFatPercentage,
      'measurements': measurements,
      'labResults': labResults, // Write NEW field
      'notes': notes,
      'labReportUrls': labReportUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}