import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/models/coach_leave_model.dart';
import 'scheduler/scheduler_components.dart';
import 'scheduler/scheduler_sheets.dart';

class FlexibleAvailabilityScreen extends ConsumerStatefulWidget {
  const FlexibleAvailabilityScreen({super.key});

  @override
  ConsumerState<FlexibleAvailabilityScreen> createState() => _FlexibleAvailabilityScreenState();
}

class _FlexibleAvailabilityScreenState extends ConsumerState<FlexibleAvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _allStaff = [];
  bool _isLoadingStaff = true;

  // Controllers
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _headerHorizontalScroll = ScrollController();
  final ScrollController _bodyHorizontalScroll = ScrollController();

  bool _hasScrolledToStart = false;

  @override
  void initState() {
    super.initState();
    _fetchStaff();

    // 🎯 SYNC HORIZONTAL SCROLLING
    _headerHorizontalScroll.addListener(() {
      if (_headerHorizontalScroll.position.pixels !=
          _bodyHorizontalScroll.position.pixels) {
        _bodyHorizontalScroll.jumpTo(_headerHorizontalScroll.position.pixels);
      }
    });
    _bodyHorizontalScroll.addListener(() {
      if (_bodyHorizontalScroll.position.pixels !=
          _headerHorizontalScroll.position.pixels) {
        _headerHorizontalScroll.jumpTo(_bodyHorizontalScroll.position.pixels);
      }
    });
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _headerHorizontalScroll.dispose();
    _bodyHorizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _fetchStaff() async {
    try {
      final snap = await ref.read(firestoreProvider).collection('admins')
          .where('isActive', isEqualTo: true).get();

      var staffList = snap.docs.map((d) =>
      {
        'id': d.id,
        'name': d.data()['name'] ?? 'Unknown',
        'photoUrl': d.data()['photoUrl'] ?? '',
      }).toList();

      setState(() {
        _allStaff = staffList;
        _isLoadingStaff = false;
      });
      _autoScroll();
    } catch (e) {
      setState(() => _isLoadingStaff = false);
    }
  }

  void _autoScroll() {
    if (_hasScrolledToStart) return;
    double target = 8.0;
    if (_selectedDate.year == DateTime
        .now()
        .year && _selectedDate.day == DateTime
        .now()
        .day) {
      target = max(0, TimeOfDay
          .now()
          .hour - 1.0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalScroll.hasClients) {
        _verticalScroll.animateTo(
            target * 90.0, duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut);
        _hasScrolledToStart = true;
      }
    });
  }

  void _refreshSchedule() {
    setState(() {
      _selectedDate = _selectedDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStaff) return const Scaffold(
        backgroundColor: Color(0xFFF8F9FC),
        body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. DATE NAVIGATOR (Top)
                PremiumDateHeader(
                  selectedDate: _selectedDate,
                  onNext: () =>
                      setState(() {
                        _selectedDate =
                            _selectedDate.add(const Duration(days: 1));
                        _hasScrolledToStart = false;
                      }),
                  onPrev: () =>
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(const Duration(days: 1));
                        _hasScrolledToStart = false;
                      }),
                  onPickDate: _pickDate,
                ),

                const Divider(height: 1, color: Color(0xFFE0E0E0)),

                // 2. FIXED HEADER ROW (Staff Names)
                SizedBox(
                  height: 60.0, // Fixed height for names
                  child: Row(
                    children: [
                      // Spacer for Time Column
                      Container(width: 65.0,
                          color: Colors.white,
                          child: const SizedBox()),

                      // Horizontal List of Staff Headers
                      Expanded(
                        child: ListView.builder(
                          controller: _headerHorizontalScroll,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          // Important for sync
                          itemCount: _allStaff.length,
                          itemBuilder: (context, index) {
                            final staff = _allStaff[index];
                            return Container(
                              width: 220.0, // Fixed Width per column
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFAFAFA),
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFE0E0E0), width: 1.5),
                                      right: BorderSide(
                                          color: Color(0xFFE0E0E0), width: 1.5)
                                  )
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white,
                                      backgroundImage: (staff['photoUrl'] != '')
                                          ? NetworkImage(staff['photoUrl'])
                                          : null,
                                      child: (staff['photoUrl'] == '')
                                          ? Text(staff['name'][0],
                                          style: const TextStyle(
                                              color: Color(0xFF1A1D2E),
                                              fontWeight: FontWeight.bold))
                                          : null
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(staff['name'],
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFF1A1D2E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14))),

                                  // Settings Menu
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.settings, size: 20,
                                        color: Color(0xFF4F46E5)),
                                    tooltip: "Schedule Options",
                                    onSelected: (value) async {
                                      if (value == 'base') {
                                        await showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) =>
                                                MasterScheduleEditorSheet(
                                                    uid: staff['id'],
                                                    name: staff['name']));
                                      } else {
                                        await showDialog(context: context,
                                            builder: (_) =>
                                                AvailabilityEditorDialog(
                                                    uid: staff['id'],
                                                    name: staff['name'],
                                                    selectedDate: _selectedDate));
                                      }
                                      _refreshSchedule();
                                    },
                                    itemBuilder: (ctx) =>
                                    const [
                                      PopupMenuItem(value: 'base',
                                          child: Text("Weekly Base Plan")),
                                      PopupMenuItem(value: 'day',
                                          child: Text("Override This Date")),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. SCROLLABLE TIMELINE BODY
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalScroll,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // A. Time Labels (Fixed Left)
                        Container(
                          width: 65.0,
                          decoration: const BoxDecoration(color: Colors.white,
                              border: Border(right: BorderSide(
                                  color: Color(0xFFE0E0E0), width: 1.5))),
                          child: const TimeLabelsColumn(), // Uses component
                        ),

                        // B. Schedule Grid (Horizontal Scroll synced with Header)
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _bodyHorizontalScroll,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              children: _allStaff.map((staff) {
                                return DietitianColumnBodyOnly( // 🎯 NEW COMPONENT (See below)
                                  staff: staff,
                                  date: _selectedDate,
                                  onEmptySlotTap: (id, dt) async {
                                    await showModalBottomSheet(context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            UnifiedActionSheet(
                                            coachId: id,
                                            coachName: staff['name'],
                                            allStaff: _allStaff,
                                            emptySlotTime: dt));
                                    _refreshSchedule();
                                  },
                                  onApptTap: (id, data, aid) async {
                                    await showModalBottomSheet(context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) =>
                                            UnifiedActionSheet(
                                            coachId: id,
                                            coachName: staff['name'],
                                            allStaff: _allStaff,
                                            appointmentData: data,
                                            appointmentId: aid));
                                    _refreshSchedule();
                                  },
                                  onBlockTap: (b) => _showBlockDetails(b),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // FAB
            Positioned(bottom: 30,
                left: 0,
                right: 0,
                child: Center(child: FloatingActionButton.extended(
                    onPressed: _onFabTap,
                    backgroundColor: const Color(0xFF1A1D2E),
                    icon: const Icon(Icons.block, color: Colors.white),
                    label: const Text(
                        "BLOCK SLOT", style: TextStyle(color: Colors.white))))),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2023),
        lastDate: DateTime(2030));
    if (p != null) setState(() {
      _selectedDate = p;
      _hasScrolledToStart = false;
      _autoScroll();
    });
  }

  void _showBlockDetails(CoachLeaveModel b) {
    showModalBottomSheet(context: context,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            BlockDetailsSheet(block: b, onDelete: (blk) async {
              await ref.read(firestoreProvider).collection('coach_leaves').doc(
                  blk.id).delete();
              _refreshSchedule();
            }));
  }

  void _onFabTap() async {
    await showModalBottomSheet(context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            BlockSlotSheet(allStaff: _allStaff, initialDate: _selectedDate));
    _refreshSchedule();
  }
}