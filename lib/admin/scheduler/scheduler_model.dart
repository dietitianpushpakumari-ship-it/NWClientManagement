import 'package:nutricare_client_management/admin/appointment_model.dart';

class ScheduleBlock {
  final AppointmentSlot startSlot;
  final int totalDurationMinutes;
  final List<String> allSlotIds;

  ScheduleBlock({
    required this.startSlot,
    required this.totalDurationMinutes,
    required this.allSlotIds,
  });

  DateTime get endTime => startSlot.startTime.add(Duration(minutes: totalDurationMinutes));
}