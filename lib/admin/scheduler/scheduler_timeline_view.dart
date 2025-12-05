import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_booking_session_screen.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/scheduler/scheduler_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'dietitian_filter_dialog.dart';
import 'booking_sheet.dart';


class SchedulerTimelineView extends StatefulWidget {
  final List<AdminProfileModel> allStaff;
  final List<String> selectedCoachIds;
  final DateTime selectedDay;
  final bool isSuperAdmin;
  final Function(DateTime) onDateChanged;
  final Function(List<String>) onFilterChanged;

  const SchedulerTimelineView({
    super.key,
    required this.allStaff,
    required this.selectedCoachIds,
    required this.selectedDay,
    required this.isSuperAdmin,
    required this.onDateChanged,
    required this.onFilterChanged,
  });

  @override
  State<SchedulerTimelineView> createState() => _SchedulerTimelineViewState();
}

class _SchedulerTimelineViewState extends State<SchedulerTimelineView> {
  final MeetingService _service = MeetingService();
  final List<SlotStatus> _statusFilters = [SlotStatus.available, SlotStatus.booked, SlotStatus.pending_payment, SlotStatus.locked];

  TimeOfDay _genStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _genEnd = const TimeOfDay(hour: 17, minute: 0);
  bool _isGenerating = false;

  // --- ACTIONS ---


  Widget _buildSlotCard(ScheduleBlock block, String coachId) {
    final slot = block.startSlot;

    // 🎯 STATUS CHECKS
    final bool isBooked = slot.status == SlotStatus.booked;
    final bool isPending = slot.status == SlotStatus.pending_payment;
    final bool isOccupied = isBooked || isPending;
    final bool isLocked = slot.status == SlotStatus.locked;

    // 🎯 COLOR CODING
    Color bg = Colors.white;
    Color border = Colors.grey.shade300;
    Color text = Colors.black87;

    if (isBooked) {
      bg = Colors.red.shade50;
      border = Colors.red.shade200;
      text = Colors.red.shade900;
    } else if (isPending) {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade200;
      text = Colors.orange.shade900;
    } else if (isLocked) {
      bg = Colors.grey.shade200;
      text = Colors.grey;
    } else {
      bg = Colors.green.shade50;
      border = Colors.green.shade200;
    }

    double height = (block.totalDurationMinutes / 15) * 45.0;

    return GestureDetector(
      onTap: () => _showSlotDetails(block, coachId),
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${DateFormat('HH:mm').format(slot.startTime)} - ${DateFormat('HH:mm').format(block.endTime)}",
              style: TextStyle(fontSize: 10, color: text.withOpacity(0.7), fontWeight: FontWeight.bold),
            ),
            if (height > 30)
              Text(
                  isOccupied ? (slot.bookedByGuestName ?? "Client") : (isLocked ? "Blocked" : "Free"),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
                  maxLines: 1, overflow: TextOverflow.ellipsis
              ),
            if (isPending && height > 40)
              Text("(Pending Payment)", style: TextStyle(fontSize: 9, color: Colors.orange.shade800)),
          ],
        ),
      ),
    );
  }

  // --- DETAILS SHEET ---
  void _showSlotDetails(ScheduleBlock block, String coachId) {
    final slot = block.startSlot;
    final bool isOccupied = slot.status == SlotStatus.booked || slot.status == SlotStatus.pending_payment;
    final bool isLocked = slot.status == SlotStatus.locked;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isOccupied ? "Appointment Details" : "Slot Actions", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if(isOccupied) Chip(
                  label: Text(slot.status == SlotStatus.booked ? "CONFIRMED" : "PAYMENT PENDING", style: const TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: slot.status == SlotStatus.booked ? Colors.green : Colors.orange,
                )
              ],
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text("${DateFormat.jm().format(slot.startTime)} - ${DateFormat.jm().format(block.endTime)}"),
            ),

            if (isOccupied) ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(slot.bookedByGuestName ?? "Unknown Client"),
              ),
              const Divider(),

              // 🎯 NEW: Change Coach Option
              ListTile(
                leading: const Icon(Icons.switch_account, color: Colors.teal),
                title: const Text("Change Coach"),
                subtitle: const Text("Move to another Dietitian/Admin"),
                onTap: () {
                  Navigator.pop(context);
                  _showCoachReassignDialog(block, coachId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_calendar, color: Colors.indigo),
                title: const Text("Reschedule"),
                subtitle: const Text("Move to new slot (Keep payment)"),
                onTap: () {
                  Navigator.pop(context); // Close details sheet
                  _showReschedulePicker(block, coachId); // Open Safe Picker
                },
              ),
              // 🎯 FIX: Reschedule Logic


              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text("Cancel Appointment"),
                onTap: () {
                  Navigator.pop(context);
                  // Add confirmation here too if desired
                  _deleteBlock(block.allSlotIds, coachId);
                },
              ),
            ] else ...[
              // Free Slot Actions...
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.indigo),
                title: const Text("Book Appointment"),
                onTap: () => _showBookingSheet(block, coachId),
              ),
              ListTile(
                leading: Icon(isLocked ? Icons.lock_open : Icons.block, color: Colors.grey),
                title: Text(isLocked ? "Unblock Slot" : "Block Slot"),
                onTap: () { Navigator.pop(context); _toggleLock(slot.id, !isLocked, coachId); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Slot"),
                onTap: () { Navigator.pop(context); _deleteBlock(block.allSlotIds, coachId); },
              ),
            ]
          ],
        ),
      ),
    );
  }
  Future<void> _showBookingSheet(ScheduleBlock block, String coachId) async {
    // We await the result, though in the current Reschedule flow above,
    // we deleted first. If you prefer "Delete only if rebooked",
    // you would need to change the logic in the onTap above.
    // But typically "Reschedule" implies freeing up the current time first.
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingSheet(slot: block.startSlot, coachId: coachId, initialDurationMinutes: 15),
    );
  }
  void _showCoachReassignDialog(ScheduleBlock block, String currentCoachId) {
    // Filter out current coach
    final availableCoaches = widget.allStaff.where((s) => s.id != currentCoachId).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select New Coach"),
        content: SizedBox(
          width: double.maxFinite,
          child: availableCoaches.isEmpty
              ? const Text("No other coaches available.")
              : ListView.builder(
            shrinkWrap: true,
            itemCount: availableCoaches.length,
            itemBuilder: (context, index) {
              final coach = availableCoaches[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: coach.photoUrl.isNotEmpty ? NetworkImage(coach.photoUrl) : null,
                  child: coach.photoUrl.isEmpty ? Text(coach.firstName[0]) : null,
                ),
                title: Text(coach.fullName),
                subtitle: Text(coach.role.name.toUpperCase()),
                onTap: () async {
                  Navigator.pop(ctx);
                  _processReassign(currentCoachId, coach.id, block);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))
        ],
      ),
    );
  }

  Future<void> _processReassign(String oldCoachId, String newCoachId, ScheduleBlock block) async {
    try {
      await _service.reassignSession(
          oldCoachId: oldCoachId,
          newCoachId: newCoachId,
          date: widget.selectedDay,
          startTime: block.startSlot.startTime,
          endTime: block.endTime
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment moved successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
    }
  }
  Future<void> _showGenerateDialog(String coachId) async {
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Generate Schedule"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select working hours:"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: _genStart); if(t!=null) setDialogState(()=>_genStart=t); }, child: InputDecorator(decoration: const InputDecoration(labelText: "Start"), child: Text(_genStart.format(context))))),
                  const SizedBox(width: 10),
                  Expanded(child: InkWell(onTap: () async { final t = await showTimePicker(context: context, initialTime: _genEnd); if(t!=null) setDialogState(()=>_genEnd=t); }, child: InputDecorator(decoration: const InputDecoration(labelText: "End"), child: Text(_genEnd.format(context))))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () { Navigator.pop(context); _generate(coachId); }, child: const Text("Generate")),
          ],
        ),
      ),
    );
  }

  Future<void> _generate(String coachId) async {
    setState(() => _isGenerating = true);
    try {
      await _service.generateDaySchedule(coachId: coachId, date: widget.selectedDay, start: _genStart, end: _genEnd);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Created!"), backgroundColor: Colors.green));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _deleteBlock(List<String> slotIds, String coachId) async {
    for (var id in slotIds) await _service.deleteSlot(coachId: coachId, date: widget.selectedDay, slotId: id);
  }

  Future<void> _toggleLock(String slotId, bool isLocked, String coachId) async {
    await _service.toggleSlotLock(coachId, widget.selectedDay, slotId, isLocked);
  }



  // --- MERGING LOGIC ---
  List<ScheduleBlock> _mergeSlotsIntoBlocks(List<AppointmentSlot> slots) {
    if (slots.isEmpty) return [];
    final filtered = slots.where((s) => _statusFilters.contains(s.status)).toList();
    if (filtered.isEmpty) return [];
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    List<ScheduleBlock> blocks = [];
    AppointmentSlot? currentStart;
    List<String> currentIds = [];

    for (int i = 0; i < filtered.length; i++) {
      final slot = filtered[i];
      final bool isBooked = slot.status == SlotStatus.booked || slot.status == SlotStatus.pending_payment;
      if (!isBooked) {
        if (currentStart != null) { blocks.add(ScheduleBlock(startSlot: currentStart, totalDurationMinutes: currentIds.length * 15, allSlotIds: List.from(currentIds))); currentStart = null; currentIds = []; }
        blocks.add(ScheduleBlock(startSlot: slot, totalDurationMinutes: 15, allSlotIds: [slot.id]));
        continue;
      }
      if (currentStart == null) { currentStart = slot; currentIds = [slot.id]; }
      else {
        // Check for continuity of booking (same guest, same status)
        final prev = filtered[i - 1];
        if (prev.endTime.isAtSameMomentAs(slot.startTime) && currentStart.bookedByGuestName == slot.bookedByGuestName && currentStart.status == slot.status) {
          currentIds.add(slot.id);
        } else {
          blocks.add(ScheduleBlock(startSlot: currentStart, totalDurationMinutes: currentIds.length * 15, allSlotIds: List.from(currentIds)));
          currentStart = slot; currentIds = [slot.id];
        }
      }
    }
    if (currentStart != null) blocks.add(ScheduleBlock(startSlot: currentStart, totalDurationMinutes: currentIds.length * 15, allSlotIds: List.from(currentIds)));
    return blocks;
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              _buildDateNavigator(),
              const Divider(height: 1),
              if (widget.isSuperAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (ctx) => DietitianFilterDialog(allStaff: widget.allStaff, selectedIds: widget.selectedCoachIds, onApply: widget.onFilterChanged)),
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: Text("Dietitians (${widget.selectedCoachIds.length})"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo, elevation: 0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatusFilterBar()),
                    ],
                  ),
                )
              else
                _buildStatusFilterBar(),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: widget.selectedCoachIds.isEmpty
              ? const Center(child: Text("Select at least one dietitian."))
              : _buildResourceView(),
        ),
      ],
    );
  }

  Widget _buildDateNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => widget.onDateChanged(widget.selectedDay.subtract(const Duration(days: 1)))),
          Column(children: [Text(DateFormat('EEEE').format(widget.selectedDay).toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)), Text(DateFormat('d MMM y').format(widget.selectedDay), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => widget.onDateChanged(widget.selectedDay.add(const Duration(days: 1)))),
        ],
      ),
    );
  }

  Widget _buildStatusFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        _buildStatusChip("Free", SlotStatus.available, Colors.green), const SizedBox(width: 8),
        _buildStatusChip("Booked", SlotStatus.booked, Colors.red), const SizedBox(width: 8),
        _buildStatusChip("Pending", SlotStatus.pending_payment, Colors.orange), const SizedBox(width: 8),
        _buildStatusChip("Blocked", SlotStatus.locked, Colors.grey),
      ]),
    );
  }

  Widget _buildStatusChip(String label, SlotStatus status, Color color) {
    final isSelected = _statusFilters.contains(status);
    return FilterChip(
      label: Text(label), selected: isSelected,
      onSelected: (val) => setState(() => val ? _statusFilters.add(status) : _statusFilters.remove(status)),
      selectedColor: color.withOpacity(0.2), checkmarkColor: color, backgroundColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? color : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget _buildResourceView() {
    return StreamBuilder<List<AppointmentSlot>>(
      stream: _service.streamMasterSchedule(widget.selectedDay, widget.selectedCoachIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final allSlots = snapshot.data ?? [];
        final Map<String, List<AppointmentSlot>> scheduleMap = {for (var id in widget.selectedCoachIds) id: []};
        for (var slot in allSlots) {
          if (scheduleMap.containsKey(slot.coachId)) scheduleMap[slot.coachId]!.add(slot);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.selectedCoachIds.map((coachId) {
                final coach = widget.allStaff.firstWhere((s) => s.id == coachId, orElse: () => widget.allStaff.first);
                return _buildCoachColumn(coach, scheduleMap[coachId] ?? []);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoachColumn(AdminProfileModel coach, List<AppointmentSlot> slots) {
    final blocks = _mergeSlotsIntoBlocks(slots);

    return Container(
      width: 200,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade300))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8), // Adjusted padding
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300))
            ),
            child: Row(
                children: [
                  CircleAvatar(
                      radius: 14,
                      backgroundImage: coach.photoUrl.isNotEmpty ? NetworkImage(coach.photoUrl) : null,
                      child: coach.photoUrl.isEmpty ? Text(coach.firstName[0]) : null
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          coach.firstName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis
                      )
                  ),

                  // 🎯 UPDATED MENU BUTTON
                  // ... inside _buildCoachColumn ...
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'add') _showGenerateDialog(coach.id);
                      if (val == 'clear_range') _showClearRangeDialog(coach.id); // Calls Step 1
                      if (val == 'clear_day') _confirmClearDay(coach.id);        // Calls Confirmation
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                          value: 'add',
                          child: Row(children: [Icon(Icons.add, color: Colors.green), SizedBox(width: 8), Text("Add Slots")])
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                          value: 'clear_range',
                          child: Row(children: [Icon(Icons.date_range, color: Colors.orange), SizedBox(width: 8), Text("Delete Range")])
                      ),
                      const PopupMenuItem(
                          value: 'clear_day',
                          child: Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text("Clear Full Day")])
                      ),
                    ],
                  )
                ]
            ),
          ),

          // SLOT LIST
          Expanded(
            child: blocks.isEmpty
                ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text("No Slots", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                          onPressed: () => _showGenerateDialog(coach.id),
                          child: const Text("Create")
                      )
                    ]
                )
            )
                : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: blocks.length,
                itemBuilder: (ctx, i) => _buildSlotCard(blocks[i], coach.id)
            ),
          ),
        ],
      ),
    );
  }
  // 1. Dialog for Deleting a Range
// --- DELETE ACTIONS WITH CONFIRMATION ---

  // 1. Step 1: Select the Time Range
  void _showClearRangeDialog(String coachId) async {
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 0);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Select Time Range"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose the time range to remove available slots:", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: start);
                            if(t!=null) setDialogState(()=>start=t);
                          },
                          child: InputDecorator(
                              decoration: const InputDecoration(labelText: "From", border: OutlineInputBorder()),
                              child: Text(start.format(context))
                          )
                      )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(context: context, initialTime: end);
                            if(t!=null) setDialogState(()=>end=t);
                          },
                          child: InputDecorator(
                              decoration: const InputDecoration(labelText: "To", border: OutlineInputBorder()),
                              child: Text(end.format(context))
                          )
                      )
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Close selection dialog
                _confirmRangeDeletion(coachId, start, end); // Trigger confirmation
              },
              child: const Text("Proceed to Delete"),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Step 2: Confirm Range Deletion
  void _confirmRangeDeletion(String coachId, TimeOfDay start, TimeOfDay end) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: RichText(
            text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  const TextSpan(text: "Are you sure you want to delete all "),
                  const TextSpan(text: "FREE slots", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  TextSpan(text: " between ${start.format(context)} and ${end.format(context)}?\n\n"),
                  const TextSpan(text: "• Booked appointments will NOT be deleted.\n", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const TextSpan(text: "• This action cannot be undone.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ]
            )
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Delete Slots"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteFreeSlots(coachId: coachId, date: widget.selectedDay, startTime: start, endTime: end);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Range deleted successfully.")));
    }
  }

  // 3. Full Day Clear Confirmation
  void _confirmClearDay(String coachId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear Entire Day?"),
        content: const Text(
          "⚠️ Warning: This will delete ALL free slots for this coach on the selected day.\n\nOnly booked appointments will remain.",
          style: TextStyle(color: Color(0xFF2D3142)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm Clear All"),
          )
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteFreeSlots(coachId: coachId, date: widget.selectedDay);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Day schedule cleared.")));
    }
  }


  // ... inside _SchedulerTimelineViewState ...

  void _showReschedulePicker(ScheduleBlock block, String coachId) async {
    // 1. Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: "SELECT NEW DATE",
    );

    if (pickedDate == null) return;

    // 2. Pick Time
    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(block.startSlot.startTime),
      helpText: "SELECT NEW START TIME",
    );

    if (pickedTime == null) return;

    // 3. Confirm & Execute
    if (!mounted) return;

    final newDateTime = DateTime(
        pickedDate.year, pickedDate.month, pickedDate.day,
        pickedTime.hour, pickedTime.minute
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Reschedule"),
        content: Text("Move appointment to ${DateFormat('dd MMM, hh:mm a').format(newDateTime)}?\n\nDuration: ${block.totalDurationMinutes} mins"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
              onPressed: ()=>Navigator.pop(ctx, true),
              child: const Text("Confirm Move")
          )
        ],
      ),
    );

    if (confirm == true) {
      _processReschedule(coachId, block.startSlot.startTime, newDateTime, block.totalDurationMinutes);
    }
  }

  Future<void> _processReschedule(String coachId, DateTime oldStart, DateTime newStart, int duration) async {
    try {
      await _service.rescheduleSession(
        coachId: coachId,
        oldStartTime: oldStart,
        newStartTime: newStart,
        durationMinutes: duration,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rescheduled successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
    }
  }
}