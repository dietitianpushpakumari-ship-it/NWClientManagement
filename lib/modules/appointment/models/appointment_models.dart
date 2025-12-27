import 'package:cloud_firestore/cloud_firestore.dart';
export 'coach_leave_model.dart';

// --- SERVICE TYPE (e.g. 15 min Quick, 30 min Standard) ---
class ServiceType {
  final String id;
  final String name;
  final int durationMins;
  final int creditCost;

  ServiceType({required this.id, required this.name, required this.durationMins, required this.creditCost});
}

// --- APPOINTMENT ---
enum AppointmentStatus { scheduled, confirmed, completed, cancelled, no_show }

class AppointmentModel {
  final String id;
  final String clientId;
  final String coachId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String serviceName;
  final bool isCreditBooking;

  AppointmentModel({
    required this.id, required this.clientId, required this.coachId,
    required this.startTime, required this.endTime, required this.status,
    required this.serviceName, required this.isCreditBooking,
  });

  Map<String, dynamic> toMap() => {
    'clientId': clientId, 'coachId': coachId,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'status': status.name,
    'serviceName': serviceName,
    'isCreditBooking': isCreditBooking,
  };

}