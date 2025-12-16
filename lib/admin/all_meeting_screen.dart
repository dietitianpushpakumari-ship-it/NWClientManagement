// file: lib/admin/all_meeting_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/admin_booking_session_screen.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart'; // 🎯 Added import
import 'package:url_launcher/url_launcher.dart';

import 'database_provider.dart';

class AllMeetingsScreen extends ConsumerStatefulWidget {
  const AllMeetingsScreen({super.key});

  @override
  ConsumerState<AllMeetingsScreen> createState() => _AllMeetingsScreenState();
}

class _AllMeetingsScreenState extends ConsumerState<AllMeetingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
                    // 🎯 Added service

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // --- ACTIONS ---
  Future<void> _updateStatus(AppointmentModel appt, AppointmentStatus status) async {
    await   ref.read(firestoreProvider).collection('appointments').doc(appt.id).update({
      'status': status.name
    });
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // 🎯 NEW: Correctly fetch data before navigation
  void _navigateToBooking() async {
    // Show loader if needed or just wait
    final staff = await ref.watch(staffManagementProvider).getAllDietitians();

    // Map to the Dietitian model required by the Booking Screen
    final dietitians = staff.map((s) => Dietitian(
      id: s.id,
      name: s.fullName,
      imageUrl: s.photoUrl,
      specialization: s.designation,
      appointments: [], // Empty init, screen will handle loading if needed
    )).toList();

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => AdminBookSessionScreen(allDietitians: dietitians)
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),

                // TABS
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(25)),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [Tab(text: "Upcoming"), Tab(text: "Requests"), Tab(text: "History")],
                  ),
                ),

                // LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: ref.watch(firestoreProvider).collection('appointments').orderBy('startTime', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final docs = snapshot.data!.docs.map((d) => AppointmentModel.fromFirestore(d)).toList();

                      // Filter Data
                      final upcoming = docs.where((a) => a.status == AppointmentStatus.confirmed && a.startTime.isAfter(DateTime.now())).toList();
                      final requests = docs.where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.pending).toList();
                      final history = docs.where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.cancelled || a.startTime.isBefore(DateTime.now())).toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(upcoming, isActionable: true),
                          _buildList(requests, isRequest: true),
                          _buildList(history, isHistory: true),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // 🎯 FIX: Use the new method
        onPressed: _navigateToBooking,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Book Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
            const SizedBox(width: 16),
            const Text("Appointments", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
          ]),
        ),
      ),
    );
  }

  Widget _buildList(List<AppointmentModel> items, {bool isActionable = false, bool isRequest = false, bool isHistory = false}) {
    if (items.isEmpty) return const Center(child: Text("No appointments found.", style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: isHistory ? Colors.grey.shade100 : Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('d').format(item.startTime), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isHistory ? Colors.grey : Colors.indigo)),
                  Text(DateFormat('MMM').format(item.startTime).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHistory ? Colors.grey : Colors.indigo)),
                ],
              ),
            ),
            title: Text(item.clientName.isEmpty ? "Guest" : item.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("${DateFormat('h:mm a').format(item.startTime)} - ${DateFormat('h:mm a').format(item.endTime)}", style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
                Text(item.topic, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            trailing: isRequest
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _updateStatus(item, AppointmentStatus.confirmed)),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _updateStatus(item, AppointmentStatus.cancelled)),
              ],
            )
                : isActionable
                ? IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _launchCall(item.guestPhone))
                : _buildStatusChip(item.status),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(AppointmentStatus status) {
    Color color = Colors.grey;
    if (status == AppointmentStatus.confirmed) color = Colors.green;
    if (status == AppointmentStatus.cancelled) color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}