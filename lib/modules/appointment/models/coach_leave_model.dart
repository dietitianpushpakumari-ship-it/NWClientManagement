import 'package:cloud_firestore/cloud_firestore.dart';


class CoachLeaveModel {
  final String id;
  final String coachId;
  final DateTime start;
  final DateTime end;
  final String reason;
  final bool isFullDay; // 🎯 Added back

  CoachLeaveModel({
    required this.id,
    required this.coachId,
    required this.start,
    required this.end,
    required this.reason,
    this.isFullDay = false, // Default false
  });

  factory CoachLeaveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachLeaveModel(
      id: doc.id,
      coachId: data['coachId'] ?? '',
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      reason: data['reason'] ?? 'Unavailable',
      isFullDay: data['isFullDay'] ?? false, // 🎯 Load from DB
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coachId': coachId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'reason': reason,
      'isFullDay': isFullDay, // 🎯 Save to DB
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}