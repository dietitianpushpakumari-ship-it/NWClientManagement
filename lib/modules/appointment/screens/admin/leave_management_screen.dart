import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/models/coach_leave_model.dart';

class LeaveManagementScreen extends ConsumerStatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authProvider).currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Holidays & Time Off"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.read(firestoreProvider)
            .collection('coach_leaves')
            .where('coachId', isEqualTo: uid)
            .where('end', isGreaterThan: Timestamp.now()) // Only show future/current leaves
            .orderBy('end')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No upcoming leaves.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text("You are available as per your weekly schedule.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final leave = CoachLeaveModel.fromFirestore(docs[index]);
              return _buildLeaveCard(leave);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLeaveDialog(context),
        label: const Text("Block Calendar"),
        icon: const Icon(Icons.block),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildLeaveCard(CoachLeaveModel leave) {
    final isMultiDay = leave.end.difference(leave.start).inHours > 24;
    final dateStr = isMultiDay
        ? "${DateFormat('MMM dd').format(leave.start)} - ${DateFormat('MMM dd').format(leave.end)}"
        : DateFormat('EEE, MMM dd').format(leave.start);

    final timeStr = leave.isFullDay
        ? "Full Day"
        : "${DateFormat.jm().format(leave.start)} - ${DateFormat.jm().format(leave.end)}";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.event_busy, color: Colors.redAccent),
        ),
        title: Text(leave.reason, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateStr, style: const TextStyle(color: Colors.black87)),
            Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => _deleteLeave(leave.id),
        ),
      ),
    );
  }

  Future<void> _deleteLeave(String leaveId) async {
    await ref.read(firestoreProvider).collection('coach_leaves').doc(leaveId).delete();
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Availability Restored.")));
  }

  // --- ADD DIALOG ---

  void _showAddLeaveDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _AddLeaveSheet(),
    );
  }
}

class _AddLeaveSheet extends ConsumerStatefulWidget {
  const _AddLeaveSheet();

  @override
  ConsumerState<_AddLeaveSheet> createState() => _AddLeaveSheetState();
}

class _AddLeaveSheetState extends ConsumerState<_AddLeaveSheet> {
  final _reasonCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isFullDay = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Block Calendar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: "Reason (e.g. Holiday, Emergency, Lunch)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text("Full Day Block"),
            value: _isFullDay,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _isFullDay = v),
          ),

          Row(
            children: [
              Expanded(
                child: _dateTimePicker("From", _startDate, (dt) {
                  setState(() {
                    _startDate = dt;
                    if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(hours: 1));
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateTimePicker("To", _endDate, (dt) => setState(() => _endDate = dt)),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveBlock,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM BLOCK"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _dateTimePicker(String label, DateTime val, Function(DateTime) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: val, firstDate: DateTime.now(), lastDate: DateTime(2030));
            if (date == null) return;

            TimeOfDay time = TimeOfDay.fromDateTime(val);
            if (!_isFullDay) {
              final t = await showTimePicker(context: context, initialTime: time);
              if (t != null) time = t;
            } else {
              // If Full Day, force start to 00:00 and end to 23:59 based on label logic?
              // Usually handled in save logic, but for UI visual:
              // We keep it hidden or just show date.
            }

            final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            onChange(combined);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: Text(_isFullDay ? DateFormat('MMM dd').format(val) : DateFormat('MMM dd, h:mm a').format(val))),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveBlock() async {
    if (_reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a reason")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = ref.read(authProvider).currentUser!.uid;
      final start = _isFullDay ? DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0) : _startDate;
      final end = _isFullDay ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59) : _endDate;

      final leave = CoachLeaveModel(
        id: '', // Auto-gen
        coachId: uid,
        start: start,
        end: end,
        reason: _reasonCtrl.text,
        isFullDay: _isFullDay,
      );

      // We add this to the `coach_leaves` collection
      // The MeetingService ALREADY listens to this collection to filter slots.
      await ref.read(meetingServiceProvider).blockCalendar(uid, start, end, _reasonCtrl.text);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calendar Blocked Successfully")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}