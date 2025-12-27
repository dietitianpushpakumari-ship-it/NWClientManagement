import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/models/daily_override_model.dart';
import 'package:nutricare_client_management/modules/appointment/models/work_schedule_model.dart';
import 'package:nutricare_client_management/modules/appointment/models/coach_leave_model.dart';
// --- CONSTANTS ---
const double kHourHeight = 90.0;
const double kColWidth = 220.0;
const double kHeaderHeight = 60.0;
const Color kAccentColor = Color(0xFF4F46E5);
const Color kTextDark = Color(0xFF1A1D2E);

// --- 1. PREMIUM HEADER ---
class PremiumDateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onPickDate;

  const PremiumDateHeader({super.key, required this.selectedDate, required this.onNext, required this.onPrev, required this.onPickDate});

  @override
  Widget build(BuildContext context) {
    final bool isToday = selectedDate.year == DateTime.now().year && selectedDate.month == DateTime.now().month && selectedDate.day == DateTime.now().day;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Team Schedule", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          InkWell(
            onTap: onPickDate,
            child: Row(children: [
              Text(isToday ? "Today" : DateFormat('EEE, d MMM').format(selectedDate), style: const TextStyle(color: kTextDark, fontSize: 26, fontWeight: FontWeight.w800)),
              const Icon(Icons.keyboard_arrow_down, size: 26),
            ]),
          ),
        ]),
        Row(children: [IconButton(icon: const Icon(Icons.chevron_left, color: kTextDark), onPressed: onPrev), IconButton(icon: const Icon(Icons.chevron_right, color: kTextDark), onPressed: onNext)])
      ]),
    );
  }
}

// --- 2. TIME LABELS ---
class TimeLabelsColumn extends StatelessWidget {
  const TimeLabelsColumn({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(24, (i) => SizedBox(height: kHourHeight, child: Align(alignment: Alignment.topCenter, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text("${i.toString().padLeft(2, '0')}:00", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)))))));
  }
}

// --- 3. DIETITIAN COLUMN ---
class DietitianColumn extends ConsumerWidget {
  final Map<String, dynamic> staff;
  final DateTime date;
  final Function(String, String) onEditSchedule;
  final Function(String, DateTime) onEmptySlotTap;
  final Function(String, Map<String, dynamic>, String) onApptTap;
  final Function(CoachLeaveModel) onBlockTap;

  const DietitianColumn({
    super.key, required this.staff, required this.date,
    required this.onEditSchedule, required this.onEmptySlotTap, required this.onApptTap, required this.onBlockTap
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: kColWidth,
      decoration: BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1.5))),
      child: Column(
        children: [
          // Header
          Container(
            height: kHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xFFFAFAFA), border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5))),
            child: Row(children: [
              CircleAvatar(radius: 16, backgroundColor: Colors.white, backgroundImage: (staff['photoUrl'] != '') ? NetworkImage(staff['photoUrl']) : null, child: (staff['photoUrl'] == '') ? Text(staff['name'][0], style: const TextStyle(color: kTextDark, fontSize: 14, fontWeight: FontWeight.bold)) : null),
              const SizedBox(width: 10),
              Expanded(child: Text(staff['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(color: kTextDark, fontWeight: FontWeight.bold, fontSize: 14))),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings, size: 20, color: kAccentColor),
                onSelected: (val) => onEditSchedule(val, staff['id']),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'base', child: Text("Weekly Base Plan")),
                  const PopupMenuItem(value: 'day', child: Text("Override This Date")),
                ],
              ),
            ]),
          ),
          // Timeline
          SizedBox(
            height: 24 * kHourHeight,
            child: Stack(children: [
              _buildGridLines(),
              _WorkingHoursLayer(coachId: staff['id'], date: date),
              _TouchLayer(onTap: (h) => onEmptySlotTap(staff['id'], DateTime(date.year, date.month, date.day, h, 0))),
              _BlocksLayer(coachId: staff['id'], date: date, onTap: onBlockTap),
              _AppointmentsLayer(coachId: staff['id'], date: date, onTap: (id, data) => onApptTap(staff['id'], data, id)),
              if (date.day == DateTime.now().day && date.month == DateTime.now().month) _CurrentTimeLine(),
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildGridLines() => Column(children: List.generate(24, (i) => Container(height: kHourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0))))));
}

// --- 4. LAYERS (Logic Hidden here) ---

class _WorkingHoursLayer extends ConsumerWidget {
  final String coachId;
  final DateTime date;
  const _WorkingHoursLayer({required this.coachId, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DaySchedule>(
      future: _fetchSchedule(ref, coachId, date),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox();
        final s = snap.data!;
        if (!s.isWorking || s.shifts.isEmpty) return Container(color: const Color(0xFFF3F4F6), alignment: Alignment.center, child: Text("OFF DUTY", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, letterSpacing: 2)));
        return Stack(children: [
          Positioned.fill(child: Container(color: const Color(0xFFF3F4F6))),
          ...s.shifts.map((shift) {
            final top = (shift.startHour + (shift.startMin / 60.0)) * kHourHeight;
            final h = ((shift.endHour + (shift.endMin / 60.0)) - (shift.startHour + (shift.startMin / 60.0))) * kHourHeight;
            return Positioned(top: top, left: 0, right: 0, height: h, child: Container(decoration: BoxDecoration(color: Colors.white, border: Border.symmetric(horizontal: BorderSide(color: Colors.green.shade300, width: 1))), child: Container(color: Colors.green.withOpacity(0.08))));
          }).toList()
        ]);
      },
    );
  }

  Future<DaySchedule> _fetchSchedule(WidgetRef ref, String uid, DateTime date) async {
    final oid = DailyOverrideModel.generateId(uid, date);
    final odoc = await ref.read(firestoreProvider).collection('coach_daily_overrides').doc(oid).get();
    if (odoc.exists) return DailyOverrideModel.fromFirestore(odoc).schedule;
    final doc = await ref.read(firestoreProvider).collection('coach_schedules').doc(uid).get();
    if (doc.exists) return WorkScheduleModel.fromFirestore(doc).weekDays[DateFormat('E').format(date)] ?? DaySchedule(isWorking: false, shifts: []);
    return DaySchedule.defaultSchedule();
  }
}

class _BlocksLayer extends ConsumerWidget {
  final String coachId; final DateTime date; final Function(CoachLeaveModel) onTap;
  const _BlocksLayer({required this.coachId, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = DateTime(date.year, date.month, date.day);
    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(firestoreProvider).collection('coach_leaves').where('coachId', isEqualTo: coachId).where('end', isGreaterThan: Timestamp.fromDate(start)).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox();
        final blocks = snap.data!.docs.map((d) => CoachLeaveModel.fromFirestore(d)).where((b) => b.start.isBefore(start.add(const Duration(hours: 24)))).toList();
        return Stack(children: blocks.map((b) {
          final top = (b.start.hour + (b.start.minute/60))*kHourHeight;
          final h = (b.end.difference(b.start).inMinutes/60)*kHourHeight;
          return Positioned(top: top+2, left:6, right:6, height: h-4, child: GestureDetector(onTap: ()=>onTap(b), child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: Colors.red.shade400, width: 4))), child: Text("BLOCKED\n${b.reason}", style: TextStyle(fontSize: 10, color: Colors.red.shade900, fontWeight: FontWeight.bold)))));
        }).toList());
      },
    );
  }
}


class DietitianColumnBodyOnly extends ConsumerWidget {
  final Map<String, dynamic> staff;
  final DateTime date;
  final Function(String, DateTime) onEmptySlotTap;
  final Function(String, Map<String, dynamic>, String) onApptTap;
  final Function(CoachLeaveModel) onBlockTap;

  const DietitianColumnBodyOnly({
    super.key, required this.staff, required this.date,
    required this.onEmptySlotTap, required this.onApptTap, required this.onBlockTap
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: kColWidth, // 220.0
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1.5))
      ),
      child: SizedBox(
        height: 24 * kHourHeight,
        child: Stack(children: [
          _buildGridLines(),
          _WorkingHoursLayer(coachId: staff['id'], date: date),
          _TouchLayer(onTap: (h) => onEmptySlotTap(staff['id'], DateTime(date.year, date.month, date.day, h, 0))),
          _BlocksLayer(coachId: staff['id'], date: date, onTap: onBlockTap),
          _AppointmentsLayer(coachId: staff['id'], date: date, onTap: (id, data) => onApptTap(staff['id'], data, id)),
          if (date.day == DateTime.now().day && date.month == DateTime.now().month) _CurrentTimeLine(),
        ]),
      ),
    );
  }

  Widget _buildGridLines() => Column(children: List.generate(24, (i) => Container(height: kHourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0))))));
}

class _AppointmentsLayer extends ConsumerWidget {
  final String coachId; final DateTime date; final Function(String, Map<String, dynamic>) onTap;
  const _AppointmentsLayer({required this.coachId, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = DateTime(date.year, date.month, date.day);
    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(firestoreProvider).collection('appointments').where('coachId', isEqualTo: coachId).where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start)).where('startTime', isLessThan: Timestamp.fromDate(start.add(const Duration(hours: 24)))).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox();
        final appts = snap.data!.docs.where((d) => d['status'] != 'cancelled').toList();
        return Stack(children: appts.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final s = (data['startTime'] as Timestamp).toDate();
          final e = (data['endTime'] as Timestamp).toDate();
          final top = (s.hour + (s.minute/60))*kHourHeight;
          final h = (e.difference(s).inMinutes/60)*kHourHeight;
          return Positioned(top: top+2, left:6, right:6, height: h-4, child: GestureDetector(onTap: ()=>onTap(doc.id, data), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: kAccentColor, width: 4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${DateFormat.jm().format(s)}", style: const TextStyle(fontSize: 10, color: kAccentColor, fontWeight: FontWeight.bold)), Text(data['clientName']??'Client', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextDark), overflow: TextOverflow.ellipsis)]))));
        }).toList());
      },
    );
  }
}

class _TouchLayer extends StatelessWidget {
  final Function(int) onTap;
  const _TouchLayer({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.translucent, onTapUp: (d) => onTap((d.localPosition.dy/kHourHeight).floor())));
  }
}

class _CurrentTimeLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Positioned(top: (now.hour + now.minute/60)*kHourHeight, left: 0, right: 0, child: Container(height: 2, color: Colors.red));
  }
}