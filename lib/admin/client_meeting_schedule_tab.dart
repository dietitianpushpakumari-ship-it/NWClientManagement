import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:url_launcher/url_launcher.dart';

// [Keep Extension at bottom]

class ClientMeetingScheduleTab extends ConsumerStatefulWidget {
  final ClientModel client;
  const ClientMeetingScheduleTab({super.key, required this.client});

  @override
  ConsumerState<ClientMeetingScheduleTab> createState() => _ClientMeetingScheduleTabState();
}

class _ClientMeetingScheduleTabState extends ConsumerState<ClientMeetingScheduleTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedMeetingType = 'Video Call';
  final TextEditingController _purposeCtrl = TextEditingController();
  final TextEditingController _linkCtrl = TextEditingController();
  bool _isScheduling = false;

  late Future<List<MeetingModel>> _meetingsFuture;

  @override
  void initState() {
    super.initState();
    _meetingsFuture = ref.watch(meetingServiceProvider).getClientMeetings(widget.client.id);
  }

  void _refresh() => setState(() => _meetingsFuture = ref.watch(meetingServiceProvider).getClientMeetings(widget.client.id));

  Future<void> _schedule() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedTime == null) return;
    setState(() => _isScheduling = true);

    try {
      final dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute);
      await ref.watch(meetingServiceProvider).scheduleMeeting(
          clientId: widget.client.id, startTime: dt, meetingType: _selectedMeetingType, purpose: _purposeCtrl.text.trim(), meetLink: _linkCtrl.text.trim()
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Meeting Scheduled!")));
        _purposeCtrl.clear(); _linkCtrl.clear(); _selectedDate = null; _selectedTime = null;
        _refresh();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Quick Actions Card
          _buildPremiumCard(
              title: "Quick Connect",
              icon: Icons.bolt,
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickBtn(Icons.phone, "Call", Colors.blue, () => launchUrl(Uri(scheme: 'tel', path: widget.client.mobile))),
                  _buildQuickBtn(FontAwesomeIcons.whatsapp, "WhatsApp", Colors.green, () => launchUrl(Uri.parse("https://wa.me/${widget.client.whatsappNumber ?? widget.client.mobile}"))),
                  _buildQuickBtn(FontAwesomeIcons.video, "Meet", Colors.red, () => launchUrl(Uri.parse("https://meet.google.com/new"))),
                ],
              )
          ),
          const SizedBox(height: 20),

          // 2. Schedule Form
          _buildPremiumCard(
              title: "Schedule New Meeting",
              icon: Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(child: _buildPicker("Date", _selectedDate != null ? DateFormat('dd MMM').format(_selectedDate!) : null, Icons.event, () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if (d != null) setState(() => _selectedDate = d);
                      })),
                      const SizedBox(width: 10),
                      Expanded(child: _buildPicker("Time", _selectedTime?.format(context), Icons.access_time, () async {
                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (t != null) setState(() => _selectedTime = t);
                      })),
                    ]),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: _selectedMeetingType,
                      decoration: _inputDec("Type"),
                      items: ['Video Call', 'Voice Call', 'In-Person'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedMeetingType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: _purposeCtrl, decoration: _inputDec("Purpose"), validator: (v) => v!.isEmpty ? "Required" : null),
                    if (_selectedMeetingType == 'Video Call') ...[
                      const SizedBox(height: 12),
                      TextFormField(controller: _linkCtrl, decoration: _inputDec("Meet Link")),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: _isScheduling ? null : _schedule,
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _isScheduling ? const CircularProgressIndicator(color: Colors.white) : const Text("SCHEDULE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ))
                  ],
                ),
              )
          ),
          const SizedBox(height: 24),

          // 3. Timeline
          const Text("Upcoming Meetings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          FutureBuilder<List<MeetingModel>>(
            future: _meetingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final meetings = snapshot.data ?? [];
              final upcoming = meetings.where((m) => m.status == MeetingStatus.scheduled).toList();

              if (upcoming.isEmpty) return const Center(child: Text("No upcoming meetings.", style: TextStyle(color: Colors.grey)));

              return Column(
                children: upcoming.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3))]),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Text(DateFormat('dd').format(m.startTime), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text(DateFormat('MMM').format(m.startTime), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.purpose, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${DateFormat.jm().format(m.startTime)} • ${m.meetingType}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.more_vert, color: Colors.grey), onPressed: () {})
                    ],
                  ),
                )).toList(),
              );
            },
          )
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 16),
          child
        ],
      ),
    );
  }

  Widget _buildQuickBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
      ],
    );
  }

  Widget _buildPicker(String hint, String? value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(children: [Icon(icon, size: 18, color: Colors.grey), const SizedBox(width: 8), Text(value ?? hint, style: TextStyle(color: value == null ? Colors.grey : Colors.black87, fontWeight: FontWeight.w600))]),
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(labelText: label, filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16));
}