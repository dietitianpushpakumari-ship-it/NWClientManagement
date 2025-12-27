import 'package:cloud_firestore/cloud_firestore.dart';

class WorkScheduleModel {
  final String coachId;
  final Map<String, DaySchedule> weekDays;

  WorkScheduleModel({required this.coachId, required this.weekDays});

  factory WorkScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final Map<String, DaySchedule> days = {};
    (data['weekDays'] as Map<String, dynamic>? ?? {}).forEach((key, val) {
      days[key] = DaySchedule.fromMap(val);
    });
    return WorkScheduleModel(coachId: doc.id, weekDays: days);
  }

  Map<String, dynamic> toMap() => {
    'weekDays': weekDays.map((key, val) => MapEntry(key, val.toMap())),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class DaySchedule {
  final bool isWorking;
  final List<WorkShift> shifts; // 🎯 CHANGED: Supports multiple shifts

  DaySchedule({this.isWorking = true, required this.shifts});

  // Default factory for new users (9-6)
  factory DaySchedule.defaultSchedule() {
    return DaySchedule(
        isWorking: true,
        shifts: [WorkShift(startHour: 9, startMin: 0, endHour: 18, endMin: 0)]
    );
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    // 🎯 Backward Compatibility: If old format (startHour/endHour) exists, convert to single shift
    List<WorkShift> parsedShifts = [];
    if (map['shifts'] != null) {
      parsedShifts = (map['shifts'] as List).map((s) => WorkShift.fromMap(s)).toList();
    } else if (map['startHour'] != null) {
      parsedShifts.add(WorkShift(
          startHour: map['startHour'], startMin: map['startMin'] ?? 0,
          endHour: map['endHour'], endMin: map['endMin'] ?? 0
      ));
    }

    return DaySchedule(
      isWorking: map['isWorking'] ?? true,
      shifts: parsedShifts.isEmpty ? [] : parsedShifts,
    );
  }

  Map<String, dynamic> toMap() => {
    'isWorking': isWorking,
    'shifts': shifts.map((s) => s.toMap()).toList(),
  };
}

class WorkShift {
  final int startHour, startMin;
  final int endHour, endMin;

  WorkShift({
    required this.startHour, required this.startMin,
    required this.endHour, required this.endMin
  });

  factory WorkShift.fromMap(Map<String, dynamic> map) => WorkShift(
    startHour: map['startHour'] ?? 9, startMin: map['startMin'] ?? 0,
    endHour: map['endHour'] ?? 17, endMin: map['endMin'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'startHour': startHour, 'startMin': startMin,
    'endHour': endHour, 'endMin': endMin,
  };

  // Helper for UI
  String format(context) {
    // Basic formatting, or use TimeOfDay in UI
    return "$startHour:${startMin.toString().padLeft(2,'0')} - $endHour:${endMin.toString().padLeft(2,'0')}";
  }
}