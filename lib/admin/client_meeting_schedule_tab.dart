import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/scheduler/scheduler_timeline_view.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/admin/meeting_service_old.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientMeetingScheduleTab extends ConsumerStatefulWidget {
  final ClientModel client;
  const ClientMeetingScheduleTab({super.key, required this.client});

  @override
  ConsumerState<ClientMeetingScheduleTab> createState() => _ClientMeetingScheduleTabState();
}

class _ClientMeetingScheduleTabState extends ConsumerState<ClientMeetingScheduleTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  List<String> _selectedCoachIds = [];
  List<AdminProfileModel> _allStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchStaffAndInitialize());
  }

  Future<void> _fetchStaffAndInitialize() async {
    try {
      final firestore = ref.read(firestoreProvider);
      final snap = await firestore.collection('admins').where('role', whereIn: ['dietitian', 'clinicAdmin', 'owner', 'admin']).get();
      final staff = snap.docs.map((d) => AdminProfileModel.fromFirestore(d)).toList();
      if (mounted) setState(() { _allStaff = staff; _selectedCoachIds = staff.map((e) => e.id).toList(); _isLoading = false; });
    } catch (e) { if(mounted) setState(() => _isLoading = false); }
  }

  // 🎯 WhatsApp Call Logic
  Future<void> _launchWhatsAppCall() async {
    String phone = widget.client.whatsappNumber ?? widget.client.mobile;
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phone.startsWith('91') && phone.length == 10) phone = '91$phone';

    // Try direct call (Android specific often), fallback to chat
    final Uri callUrl = Uri.parse("whatsapp://call?phone=$phone");
    final Uri chatUrl = Uri.parse("https://wa.me/$phone");

    try {
      if (await canLaunchUrl(callUrl)) {
        await launchUrl(callUrl);
      } else {
        await launchUrl(chatUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // HEADER & QUICK ACTIONS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(widget.client.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              // 🎯 QUICK ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickBtn(Icons.phone, "Call", Colors.blue, () => launchUrl(Uri.parse("tel:${widget.client.mobile}"))),
                  _buildQuickBtn(FontAwesomeIcons.whatsapp, "Chat", Colors.green, () => launchUrl(Uri.parse("https://wa.me/${widget.client.whatsappNumber ?? widget.client.mobile}"))),
                  // 🎯 NEW: WhatsApp Call Button
                  _buildQuickBtn(Icons.video_call, "WA Call", Colors.teal, _launchWhatsAppCall),
                  _buildQuickBtn(Icons.video_camera_front, "Meet", Colors.red, () => launchUrl(Uri.parse("https://meet.google.com/new"))),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.indigo,
                tabs: const [Tab(text: "Scheduler"), Tab(text: "History")],
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Scheduler Timeline
              SchedulerTimelineView(
                allStaff: _allStaff,
                selectedCoachIds: _selectedCoachIds,
                selectedDay: _selectedDate,
                isSuperAdmin: false,
                onDateChanged: (d) => setState(() => _selectedDate = d),
                onFilterChanged: (ids) => setState(() => _selectedCoachIds = ids),
                preSelectedClient: widget.client, // 🎯 Context
              ),

              // TAB 2: History List
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ... (Keep _buildHistoryTab and _buildAppointmentCard from previous response) ...
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.watch(firestoreProvider).collection('appointments')
          .where('clientId', isEqualTo: widget.client.id).orderBy('startTime', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.map((d) => AppointmentModel.fromFirestore(d)).toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_,__) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _buildAppointmentCard(docs[i]),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Text(DateFormat('dd\nMMM').format(appt.startTime), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(appt.topic.isEmpty ? "Session" : appt.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${DateFormat.jm().format(appt.startTime)} - ${DateFormat.jm().format(appt.endTime)}"),
            if (appt.meetLink != null && appt.meetLink!.isNotEmpty)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(appt.meetLink!), mode: LaunchMode.externalApplication),
                child: Text(appt.meetLink!, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              )
          ],
        ),
        trailing: Icon(
          appt.status == AppointmentStatus.cancelled ? Icons.cancel : Icons.check_circle,
          color: appt.status == AppointmentStatus.cancelled ? Colors.red : Colors.green,
        ),
      ),
    );
  }
}