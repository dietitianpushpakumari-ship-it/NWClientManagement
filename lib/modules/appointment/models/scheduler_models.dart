import 'package:cloud_firestore/cloud_firestore.dart';
import 'coach_leave_model.dart';
import 'package:flutter/material.dart';

// --- 1. WORK SCHEDULE (WEEKLY PATTERN) ---
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

// --- 2. DAY SCHEDULE (SHIFTS) ---
class DaySchedule {
  final bool isWorking;
  final List<WorkShift> shifts;

  DaySchedule({this.isWorking = true, required this.shifts});

  factory DaySchedule.defaultSchedule() {
    return DaySchedule(isWorking: true, shifts: [WorkShift(startHour: 9, startMin: 0, endHour: 18, endMin: 0)]);
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    List<WorkShift> parsedShifts = [];
    if (map['shifts'] != null) {
      parsedShifts = (map['shifts'] as List).map((s) => WorkShift.fromMap(s)).toList();
    } else if (map['startHour'] != null) {
      // Backward compatibility
      parsedShifts.add(WorkShift(startHour: map['startHour'], startMin: map['startMin'] ?? 0, endHour: map['endHour'], endMin: map['endMin'] ?? 0));
    }
    return DaySchedule(isWorking: map['isWorking'] ?? true, shifts: parsedShifts);
  }

  Map<String, dynamic> toMap() => {'isWorking': isWorking, 'shifts': shifts.map((s) => s.toMap()).toList()};
}

// --- 3. WORK SHIFT (START-END) ---
class WorkShift {
  final int startHour, startMin, endHour, endMin;
  WorkShift({required this.startHour, required this.startMin, required this.endHour, required this.endMin});

  factory WorkShift.fromMap(Map<String, dynamic> map) => WorkShift(
    startHour: map['startHour'] ?? 9, startMin: map['startMin'] ?? 0,
    endHour: map['endHour'] ?? 17, endMin: map['endMin'] ?? 0,
  );

  Map<String, dynamic> toMap() => {'startHour': startHour, 'startMin': startMin, 'endHour': endHour, 'endMin': endMin};
}

// --- 4. DAILY OVERRIDE (EXCEPTIONS) ---
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

  static String generateId(String uid, DateTime date) => "${uid}_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}";
}