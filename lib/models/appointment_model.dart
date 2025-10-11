// lib/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { scheduled, confirmed, cancelled, completed }

class AppointmentModel {
  final String id;
  final String clientId;
  final String coachId; // Use current Admin UID
  final DateTime startTime;
  final DateTime endTime;
  final String topic;
  final AppointmentStatus status;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.coachId,
    required this.startTime,
    required this.endTime,
    required this.topic,
    this.status = AppointmentStatus.scheduled,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      coachId: data['coachId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      topic: data['topic'] ?? '',
      status: AppointmentStatus.values.firstWhere(
              (e) => e.toString() == 'AppointmentStatus.${data['status']}',
          orElse: () => AppointmentStatus.scheduled),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'coachId': coachId,
      'startTime': startTime,
      'endTime': endTime,
      'topic': topic,
      'status': status.toString().split('.').last, // Store as string
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}