import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/models/appointment_models.dart';
import 'package:nutricare_client_management/modules/appointment/models/work_schedule_model.dart'; // Compat
import 'package:nutricare_client_management/modules/appointment/models/daily_override_model.dart';
import 'package:nutricare_client_management/modules/appointment/services/meeting_service.dart';
import 'package:nutricare_client_management/admin/scheduler/booking_sheet.dart';

// Constants for styling
const Color kAccentColor = Color(0xFF4F46E5);
const Color kTextDark = Color(0xFF1A1D2E);

// ===========================================================================
// 1. UNIFIED ACTION SHEET (Tap on Slot)
// ===========================================================================
class UnifiedActionSheet extends ConsumerWidget {
  final String coachId;
  final String coachName;
  final Map<String, dynamic>? appointmentData;
  final String? appointmentId;
  final DateTime? emptySlotTime;
  final List<Map<String, dynamic>> allStaff; // For reassigning

  const UnifiedActionSheet({
    super.key, required this.coachId, required this.coachName, required this.allStaff,
    this.appointmentData, this.appointmentId, this.emptySlotTime
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOccupied = appointmentData != null;
    final DateTime displayStart = isOccupied ? (appointmentData!['startTime'] as Timestamp).toDate() : emptySlotTime!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isOccupied ? "Appointment Details" : "Slot Actions", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if(isOccupied) const Chip(label: Text("CONFIRMED", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green)
        ]),
        const SizedBox(height: 20),

        // Time Info
        ListTile(
          leading: const Icon(Icons.access_time),
          title: Text(DateFormat.jm().format(displayStart)),
          subtitle: Text(DateFormat('EEEE, MMM d').format(displayStart)),
        ),

        if (isOccupied) ...[
          // === BOOKED ACTIONS ===
          ListTile(leading: const Icon(Icons.person), title: Text(appointmentData!['clientName'] ?? "Client")),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.switch_account, color: Colors.teal),
              title: const Text("Change Coach"),
              onTap: () { Navigator.pop(context); _showReassignDialog(context, ref); }
          ),
          ListTile(
              leading: const Icon(Icons.edit_calendar, color: Colors.indigo),
              title: const Text("Reschedule"),
              onTap: () { Navigator.pop(context); _reschedule(context, ref); }
          ),
          ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text("Cancel"),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(meetingServiceProvider).cancelAppointment(appointmentId!, "Admin Cancelled");
              }
          ),
        ] else ...[
          // === EMPTY ACTIONS ===
          ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.indigo),
              title: const Text("Book Appointment"),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => BookingSheet(preSelectedDateTime: displayStart, coachId: coachId, initialDurationMinutes: 30));
              }
          ),
          ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text("Block This Slot"),
              onTap: () {
                Navigator.pop(context);
                // 🎯 FIX: Pass 'displayStart' as the target date
                showModalBottomSheet(
                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                    builder: (_) => BlockSlotSheet(
                      allStaff: allStaff,
                      preSelectedCoachId: coachId,
                      preSelectedStart: TimeOfDay.fromDateTime(displayStart),
                      initialDate: displayStart, // <--- PASS DATE HERE
                    )
                );  }
          ),
          ListTile(
              leading: Icon(Icons.edit_calendar, color: Colors.orange.shade800),
              title: const Text("Edit Availability"),
              onTap: () {
                Navigator.pop(context);
                showDialog(context: context, builder: (_) => AvailabilityEditorDialog(uid: coachId, name: coachName, selectedDate: displayStart));
              }
          ),
        ]
      ]),
    );
  }

  void _showReassignDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Reassign to..."),
      content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: allStaff.where((s) => s['id'] != coachId).map((s) => ListTile(
        leading: CircleAvatar(child: Text(s['name'][0])), title: Text(s['name']),
        onTap: () async {
          await ref.read(firestoreProvider).collection('appointments').doc(appointmentId).update({'coachId': s['id']});
          Navigator.pop(ctx);
        },
      )).toList())),
    ));
  }

  void _reschedule(BuildContext context, WidgetRef ref) async {
    final currentStart = (appointmentData!['startTime'] as Timestamp).toDate();
    final d = await showDatePicker(context: context, initialDate: currentStart, firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (d == null) return;
    if(!context.mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(currentStart));
    if (t == null) return;

    final newStart = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    final duration = (appointmentData!['durationMins'] ?? 30) as int;
    await ref.read(firestoreProvider).collection('appointments').doc(appointmentId).update({
      'startTime': Timestamp.fromDate(newStart),
      'endTime': Timestamp.fromDate(newStart.add(Duration(minutes: duration)))
    });
  }
}

// ===========================================================================
// 2. BLOCK SLOT SHEET
// ===========================================================================
// ... existing imports ...

// ===========================================================================
// 2. BLOCK SLOT SHEET (Smart & Recurring)
// ===========================================================================
class BlockSlotSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> allStaff;
  final DateTime initialDate;
  final String? preSelectedCoachId;
  final TimeOfDay? preSelectedStart;

  const BlockSlotSheet({
    super.key, required this.allStaff, required this.initialDate,
    this.preSelectedCoachId, this.preSelectedStart
  });

  @override
  ConsumerState<BlockSlotSheet> createState() => _BlockSlotSheetState();
}

class _BlockSlotSheetState extends ConsumerState<BlockSlotSheet> {
  String? _selectedCoachId;
  final _reasonCtrl = TextEditingController();

  // Time & Date State
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late DateTime _startDate;
  late DateTime _endDate;

  // Options
  bool _isAllDay = false;
  String _recurrence = 'none'; // none, daily, weekly
  int _recurrenceCount = 4; // Repeat for 4 occurrences by default

  final List<String> _quickNotes = ["Lunch Break", "Personal Emergency", "Meeting", "Sick Leave", "Holiday"];

  @override
  void initState() {
    super.initState();
    _selectedCoachId = widget.preSelectedCoachId ?? (widget.allStaff.isNotEmpty ? widget.allStaff.first['id'] : null);

    _startDate = widget.initialDate;
    _endDate = widget.initialDate; // Default to single day

    _startTime = widget.preSelectedStart ?? const TimeOfDay(hour: 12, minute: 0);
    _endTime = TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Block Calendar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 20),

          // 1. Staff Selector
          DropdownButtonFormField<String>(
              value: _selectedCoachId,
              items: widget.allStaff.map((s) => DropdownMenuItem(
                  value: s['id'] as String,
                  child: Text(s['name'] ?? "Admin") // Handle missing names
              )).toList(),
              onChanged: (v)=>setState(()=>_selectedCoachId=v),
              decoration: InputDecoration(
                  labelText: "Staff Member",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              )
          ),
          const SizedBox(height: 16),

          // 2. Reason Input & Quick Notes
          TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(labelText: "Reason", hintText: "e.g., Doctor Appointment", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _quickNotes.map((note) => ActionChip(
              label: Text(note, style: const TextStyle(fontSize: 11)),
              backgroundColor: Colors.grey.shade100,
              onPressed: () => _reasonCtrl.text = note,
            )).toList(),
          ),
          const Divider(height: 30),

          // 3. Date & Time Config
          SwitchListTile(
            title: const Text("All Day Block", style: TextStyle(fontWeight: FontWeight.bold)),
            value: _isAllDay,
            activeColor: Colors.redAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isAllDay = v),
          ),

          // Date Range
          Row(children: [
            Expanded(child: _DateBtn(date: _startDate, label: "Start Date", onChange: (d) => setState(() { _startDate = d; if(_endDate.isBefore(d)) _endDate = d; }))),
            const SizedBox(width: 12),
            Expanded(child: _DateBtn(date: _endDate, label: "End Date", onChange: (d) => setState(() => _endDate = d))),
          ]),
          const SizedBox(height: 12),

          if (!_isAllDay)
            Row(children: [
              Expanded(child: _TimeButton(time: _startTime, label: "From", onChange: (t)=>setState(()=>_startTime=t))),
              const SizedBox(width: 12),
              Expanded(child: _TimeButton(time: _endTime, label: "To", onChange: (t)=>setState(()=>_endTime=t))),
            ]),

          const SizedBox(height: 16),

          // 4. Recurrence
          if (_startDate.isAtSameMomentAs(_endDate)) ...[
            const Text("Repeat:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                _RecurrenceChip(label: "None", val: 'none', current: _recurrence, onSelect: (v)=>setState(()=>_recurrence=v)),
                _RecurrenceChip(label: "Daily (4 days)", val: 'daily', current: _recurrence, onSelect: (v)=>setState(()=>_recurrence=v)),
                _RecurrenceChip(label: "Weekly (4 weeks)", val: 'weekly', current: _recurrence, onSelect: (v)=>setState(()=>_recurrence=v)),
              ],
            )
          ],

          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
              onPressed: _saveBlock,
              style: ElevatedButton.styleFrom(backgroundColor: kTextDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("CONFIRM BLOCK")
          ))
        ]),
      ),
    );
  }

  void _saveBlock() async {
    if (_selectedCoachId == null || _reasonCtrl.text.isEmpty) return;

    final service = ref.read(meetingServiceProvider);

    // Logic for "Date Range" (Continuous block across days)
    if (!_startDate.isAtSameMomentAs(_endDate)) {
      DateTime startFull = DateTime(_startDate.year, _startDate.month, _startDate.day, _isAllDay ? 0 : _startTime.hour, _isAllDay ? 0 : _startTime.minute);
      DateTime endFull = DateTime(_endDate.year, _endDate.month, _endDate.day, _isAllDay ? 23 : _endTime.hour, _isAllDay ? 59 : _endTime.minute);
      await service.blockCalendar(_selectedCoachId!, startFull, endFull, _reasonCtrl.text);
    }
    // Logic for "Recurrence" (Individual blocks repeated)
    else if (_recurrence != 'none') {
      int daysToAdd = _recurrence == 'daily' ? 1 : 7;
      for(int i=0; i<_recurrenceCount; i++) {
        DateTime currentDay = _startDate.add(Duration(days: i * daysToAdd));
        DateTime s = DateTime(currentDay.year, currentDay.month, currentDay.day, _isAllDay ? 0 : _startTime.hour, _isAllDay ? 0 : _startTime.minute);
        DateTime e = DateTime(currentDay.year, currentDay.month, currentDay.day, _isAllDay ? 23 : _endTime.hour, _isAllDay ? 59 : _endTime.minute);
        await service.blockCalendar(_selectedCoachId!, s, e, "${_reasonCtrl.text} (Recurring)");
      }
    }
    // Logic for Single Block
    else {
      DateTime s = DateTime(_startDate.year, _startDate.month, _startDate.day, _isAllDay ? 0 : _startTime.hour, _isAllDay ? 0 : _startTime.minute);
      DateTime e = DateTime(_endDate.year, _endDate.month, _endDate.day, _isAllDay ? 23 : _endTime.hour, _isAllDay ? 59 : _endTime.minute);
      await service.blockCalendar(_selectedCoachId!, s, e, _reasonCtrl.text);
    }

    if(mounted) Navigator.pop(context);
  }
}

// --- Helper Widgets for Block Sheet ---
class _DateBtn extends StatelessWidget {
  final DateTime date; final String label; final Function(DateTime) onChange;
  const _DateBtn({required this.date, required this.label, required this.onChange});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030)); if(d!=null) onChange(d); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(DateFormat('MMM dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  final String label; final String val; final String current; final Function(String) onSelect;
  const _RecurrenceChip({required this.label, required this.val, required this.current, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final isSel = val == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSel,
        onSelected: (v) => onSelect(val),
        selectedColor: kTextDark,
        labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black, fontSize: 12),
        checkmarkColor: Colors.white,
      ),
    );
  }
}

// ===========================================================================
// 3. BLOCK DETAILS SHEET (View/Delete)
// ===========================================================================
class BlockDetailsSheet extends StatelessWidget {
  final CoachLeaveModel block;
  final Function(CoachLeaveModel) onDelete;

  const BlockDetailsSheet({super.key, required this.block, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final duration = block.end.difference(block.start);
    final isLong = duration.inHours > 24;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.block, size: 40, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(block.reason, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
        const SizedBox(height: 8),
        Text(isLong
            ? "${DateFormat('MMM d').format(block.start)} - ${DateFormat('MMM d').format(block.end)}"
            : "${DateFormat.jm().format(block.start)} - ${DateFormat.jm().format(block.end)}",
            style: const TextStyle(fontSize: 16, color: Colors.grey)
        ),
        const SizedBox(height: 24),

        // Actions
        Row(children: [
          Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("Close")
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: () { onDelete(block); Navigator.pop(context); },
            icon: const Icon(Icons.delete_outline),
            label: const Text("Unblock"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          ))
        ])
      ]),
    );
  }
}
// ===========================================================================
// 3. MASTER SCHEDULE EDITOR (Weekly Plan)
// ===========================================================================
class MasterScheduleEditorSheet extends ConsumerStatefulWidget {
  final String uid;
  final String name;

  const MasterScheduleEditorSheet({super.key, required this.uid, required this.name});

  @override
  ConsumerState<MasterScheduleEditorSheet> createState() => _MasterScheduleEditorSheetState();
}

class _MasterScheduleEditorSheetState extends ConsumerState<MasterScheduleEditorSheet> {
  Map<String, DaySchedule> weekMap = {};
  bool isLoading = true;
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await ref.read(firestoreProvider).collection('coach_schedules').doc(widget.uid).get();
    if (doc.exists) weekMap = WorkScheduleModel.fromFirestore(doc).weekDays;
    for (var d in days) { if (!weekMap.containsKey(d)) weekMap[d] = DaySchedule.defaultSchedule(); }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()));

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Weekly Plan: ${widget.name}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
        ]),
        const Divider(),

        // Copy Action
        OutlinedButton.icon(
            icon: const Icon(Icons.copy_all), label: const Text("Smart Copy Pattern"),
            onPressed: () => _showSmartCopyDialog()
        ),

        Expanded(
          child: ListView.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final s = weekMap[day]!;
                return Card(
                  color: s.isWorking ? Colors.white : Colors.grey.shade50,
                  elevation: 0, shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Switch(value: s.isWorking, activeColor: kAccentColor, onChanged: (v) => setState(() => weekMap[day] = DaySchedule(isWorking: v, shifts: s.shifts)))
                      ]),
                      if (s.isWorking) ...[
                        Wrap(spacing: 8, children: s.shifts.asMap().entries.map((e) => Chip(
                          label: Text("${e.value.startHour}:${e.value.startMin.toString().padLeft(2,'0')} - ${e.value.endHour}:${e.value.endMin.toString().padLeft(2,'0')}"),
                          onDeleted: () => setState(() => s.shifts.removeAt(e.key)),
                        )).toList()),
                        TextButton(onPressed: () async {
                          final ns = await _pickShiftTime(context);
                          if(ns!=null) setState(()=>s.shifts.add(ns));
                        }, child: const Text("Add Shift"))
                      ]
                    ]),
                  ),
                );
              }
          ),
        ),
        SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kTextDark, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(firestoreProvider).collection('coach_schedules').doc(widget.uid).set(WorkScheduleModel(coachId: widget.uid, weekDays: weekMap).toMap());
              if(mounted) Navigator.pop(context);
            },
            child: const Text("SAVE PLAN")
        ))
      ]),
    );
  }

  void _showSmartCopyDialog() {
    // (Reuse Smart Copy Logic from previous steps, passed context)
    // For brevity, basic copy Mon->Fri logic here
    final mon = weekMap['Mon']!;
    for(var d in ['Tue','Wed','Thu','Fri']) {
      weekMap[d] = DaySchedule(isWorking: mon.isWorking, shifts: List.from(mon.shifts));
    }
    setState((){});
  }
}

// ===========================================================================
// 4. AVAILABILITY EDITOR DIALOG (Override)
// ===========================================================================
// ... (Keep existing imports and previous classes like UnifiedActionSheet, BlockSlotSheet, MasterScheduleEditorSheet) ...

// ===========================================================================
// 4. AVAILABILITY EDITOR DIALOG (Ultra-Premium Redesign)
// ===========================================================================
class AvailabilityEditorDialog extends ConsumerStatefulWidget {
  final String uid;
  final String name;
  final DateTime selectedDate;

  const AvailabilityEditorDialog({super.key, required this.uid, required this.name, required this.selectedDate});

  @override
  ConsumerState<AvailabilityEditorDialog> createState() => _AvailabilityEditorDialogState();
}

class _AvailabilityEditorDialogState extends ConsumerState<AvailabilityEditorDialog> {
  DaySchedule? current;
  List<WorkShift> editingShifts = [];
  bool isWorking = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 1. Check for existing override
    final oid = DailyOverrideModel.generateId(widget.uid, widget.selectedDate);
    final odoc = await ref.read(firestoreProvider).collection('coach_daily_overrides').doc(oid).get();

    if (odoc.exists) {
      current = DailyOverrideModel.fromFirestore(odoc).schedule;
    } else {
      // 2. Fallback to weekly schedule
      final doc = await ref.read(firestoreProvider).collection('coach_schedules').doc(widget.uid).get();
      if (doc.exists) {
        current = WorkScheduleModel.fromFirestore(doc).weekDays[DateFormat('E').format(widget.selectedDate)];
      }
    }

    // 3. Defaults
    current ??= DaySchedule.defaultSchedule();

    editingShifts = List.from(current!.shifts);
    isWorking = current!.isWorking;

    // If working but empty (edge case), add default
    if (isWorking && editingShifts.isEmpty) {
      editingShifts.add(WorkShift(startHour: 9, startMin: 0, endHour: 17, endMin: 0));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const SizedBox(height: 150, child: Center(child: CircularProgressIndicator())),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Premium Rounding
      backgroundColor: Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kAccentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_calendar, color: kAccentColor),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Edit Availability", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
                    Text(DateFormat('EEEE, MMMM d').format(widget.selectedDate), style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- STATUS CARD (Big Toggle) ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isWorking ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isWorking ? Colors.green.shade200 : Colors.grey.shade200, width: 2),
              ),
              child: Row(
                children: [
                  Icon(isWorking ? Icons.check_circle : Icons.do_not_disturb_on, color: isWorking ? Colors.green : Colors.grey, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isWorking ? "Available" : "Not Working", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWorking ? Colors.green.shade800 : Colors.grey.shade700)),
                        Text(isWorking ? "Staff is taking appointments" : "Marked as off-duty for this day", style: TextStyle(fontSize: 12, color: isWorking ? Colors.green.shade600 : Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isWorking,
                      activeColor: Colors.green,
                      onChanged: (v) => setState(() => isWorking = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- SHIFT EDITOR LIST ---
            if (isWorking) ...[
              const Text("Working Hours", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 12),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250), // Prevent overflow
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...editingShifts.asMap().entries.map((entry) {
                        int index = entry.key;
                        WorkShift shift = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              // Start Time
                              Expanded(
                                child: _PremiumTimePicker(
                                  time: TimeOfDay(hour: shift.startHour, minute: shift.startMin),
                                  label: "START",
                                  onChange: (t) => setState(() => editingShifts[index] = _updateStart(shift, t)),
                                ),
                              ),

                              // Arrow
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),
                              ),

                              // End Time
                              Expanded(
                                child: _PremiumTimePicker(
                                  time: TimeOfDay(hour: shift.endHour, minute: shift.endMin),
                                  label: "END",
                                  onChange: (t) => setState(() => editingShifts[index] = _updateEnd(shift, t)),
                                ),
                              ),

                              // Delete Action
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => setState(() => editingShifts.removeAt(index)),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Add Shift Button
                      if (editingShifts.length < 3) // Reasonable limit
                        TextButton.icon(
                          onPressed: () async {
                            final ns = await _pickShiftTime(context);
                            if (ns != null) setState(() => editingShifts.add(ns));
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: kAccentColor,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            backgroundColor: kAccentColor.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text("Add Another Shift", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Text("No shifts scheduled.\nStaff will appear as 'OFF' for the entire day.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ),

            const SizedBox(height: 32),

            // --- ACTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.grey),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saveOverride,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("SAVE OVERRIDE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveOverride() async {
    final override = DailyOverrideModel(
        coachId: widget.uid,
        date: widget.selectedDate,
        schedule: DaySchedule(isWorking: isWorking, shifts: editingShifts)
    );
    final oid = DailyOverrideModel.generateId(widget.uid, widget.selectedDate);

    await ref.read(firestoreProvider).collection('coach_daily_overrides').doc(oid).set(override.toMap());

    if (mounted) Navigator.pop(context);
  }

  WorkShift _updateStart(WorkShift s, TimeOfDay t) => WorkShift(startHour: t.hour, startMin: t.minute, endHour: s.endHour, endMin: s.endMin);
  WorkShift _updateEnd(WorkShift s, TimeOfDay t) => WorkShift(startHour: s.startHour, startMin: s.startMin, endHour: t.hour, endMin: t.minute);
}

// --- PREMIUM TIME PICKER WIDGET ---
class _PremiumTimePicker extends StatelessWidget {
  final TimeOfDay time;
  final Function(TimeOfDay) onChange;
  final String label;

  const _PremiumTimePicker({required this.time, required this.onChange, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onChange(t);
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextDark)),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// --- HELPER HELPERS ---
class _TimeButton extends StatelessWidget {
  final TimeOfDay time; final Function(TimeOfDay) onChange; final String? label;
  const _TimeButton({required this.time, required this.onChange, this.label});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async { final t = await showTimePicker(context: context, initialTime: time); if(t!=null) onChange(t); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

Future<WorkShift?> _pickShiftTime(BuildContext context) async {
  TimeOfDay s = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay e = const TimeOfDay(hour: 17, minute: 0);
  return await showDialog<WorkShift>(context: context, builder: (ctx) => AlertDialog(
    title: const Text("New Shift"),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: const Text("Start"), trailing: Text(s.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: s); if(t!=null) s=t; }),
      ListTile(title: const Text("End"), trailing: Text(e.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: e); if(t!=null) e=t; }),
    ]),
    actions: [
      TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
      ElevatedButton(onPressed: ()=>Navigator.pop(ctx, WorkShift(startHour: s.hour, startMin: s.minute, endHour: e.hour, endMin: e.minute)), child: const Text("Add"))
    ],
  ));
}

