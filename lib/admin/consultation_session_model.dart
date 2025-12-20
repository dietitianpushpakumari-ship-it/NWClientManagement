// lib/models/consultation_session_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationSessionModel {
  final String id;
  final String clientId;
  final String dietitianId;
  final Timestamp sessionDate; // 🎯 Added for easy filtering by date
  final Timestamp startTime;
  final Timestamp? endTime;
  final String status;
  final String? linkedVitalsId;
  final String? linkedDietPlanId;

  ConsultationSessionModel({
    this.id = '',
    required this.clientId,
    required this.dietitianId,
    required this.sessionDate, // 🎯 Initialize this
    required this.startTime,
    this.endTime,
    this.status = 'Ongoing',
    this.linkedVitalsId,
    this.linkedDietPlanId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'dietitianId': dietitianId,
      'sessionDate': sessionDate, // 🎯 Store date for indexing
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'linkedVitalsId': linkedVitalsId,
      'linkedDietPlanId': linkedDietPlanId,
    };
  }

  factory ConsultationSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ConsultationSessionModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      dietitianId: data['dietitianId'] ?? '',
      sessionDate: data['sessionDate'] as Timestamp, // 🎯 Retrieve date
      startTime: data['startTime'] as Timestamp,
      endTime: data['endTime'] as Timestamp?,
      status: data['status'] ?? 'Ongoing',
      linkedVitalsId: data['linkedVitalsId'],
      linkedDietPlanId: data['linkedDietPlanId'],
    );
  }
}