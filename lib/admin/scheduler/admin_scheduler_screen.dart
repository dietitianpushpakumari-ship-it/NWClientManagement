import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/scheduler/scheduler_list_view.dart';
import 'package:nutricare_client_management/admin/scheduler/scheduler_timeline_view.dart';

import '../labvital/global_service_provider.dart';


class AdminSchedulerScreen extends ConsumerStatefulWidget {
  const AdminSchedulerScreen({super.key});

  @override
  ConsumerState<AdminSchedulerScreen> createState() => _AdminSchedulerScreenState();
}

class _AdminSchedulerScreenState extends ConsumerState<AdminSchedulerScreen> {
  bool _isTimelineView = true;
  DateTime _selectedDay = DateTime.now();
  List<String> _selectedCoachIds = [];
  bool _isInit = true;

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(currentAdminProvider);
    final staffAsync = ref.watch(allStaffStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(_isTimelineView ? "Master Scheduler" : "All Appointments"),
        backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_isTimelineView ? Icons.list_alt : Icons.calendar_view_day, color: Colors.indigo),
            onPressed: () => setState(() => _isTimelineView = !_isTimelineView),
            tooltip: "Switch View",
          ),
          if (_isTimelineView)
            IconButton(
              icon: const Icon(Icons.today, color: Colors.indigo),
              onPressed: () => setState(() => _selectedDay = DateTime.now()),
              tooltip: "Jump to Today",
            ),
        ],
      ),
      body: adminAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (me) {
          if (me == null) return const SizedBox();
          final bool isSuper = me.role == AdminRole.superAdmin;

          // Initialize Selection
          if (_isInit && staffAsync.hasValue) {
            var allStaff = List<AdminProfileModel>.from(staffAsync.value!);
            if (!allStaff.any((s) => s.id == me.id)) allStaff.add(me);
            _selectedCoachIds = isSuper ? allStaff.map((e) => e.id).toList() : [me.id];
            _isInit = false;
          }

          final renderList = staffAsync.value ?? (isSuper ? [] : [me]);
          if (!renderList.any((s) => s.id == me.id)) renderList.add(me);

          return _isTimelineView
              ? SchedulerTimelineView(
            allStaff: renderList,
            selectedCoachIds: _selectedCoachIds,
            selectedDay: _selectedDay,
            isSuperAdmin: isSuper,
            onDateChanged: (d) => setState(() => _selectedDay = d),
            onFilterChanged: (ids) => setState(() => _selectedCoachIds = ids),
          )
              : const SchedulerListView();
        },
      ),
    );
  }
}