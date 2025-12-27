import 'package:cloud_firestore/cloud_firestore.dart';
import 'work_schedule_model.dart';

class DailyOverrideModel {
  final String coachId;
  final DateTime date;
  final DaySchedule schedule;

  DailyOverrideModel({required this.coachId, required this.date, required this.schedule});

  factory DailyOverrideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyOverrideModel(
      coachId: data['coachId'],
      date: (data['date'] as Timestamp).toDate(),
      schedule: DaySchedule.fromMap(data['schedule']),
    );
  }

  Map<String, dynamic> toMap() => {
    'coachId': coachId,
    'date': Timestamp.fromDate(date),
    'schedule': schedule.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static String generateId(String uid, DateTime date) {
    return "${uid}_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}";
  }
}