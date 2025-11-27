import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/schedule_meeting_utils.dart';

class AdminSchedulerScreen extends StatefulWidget {
  const AdminSchedulerScreen({super.key});

  @override
  State<AdminSchedulerScreen> createState() => _AdminSchedulerScreenState();
}

class _AdminSchedulerScreenState extends State<AdminSchedulerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Scheduler")),
      body: Column(
        children: [
          // Date Picker Strip
          _buildDateHeader(),

          // Appointments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('client_meetings')
                  .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(_selectedDate)))
                  .where('startTime', isLessThan: Timestamp.fromDate(_endOfDay(_selectedDate)))
                  .orderBy('startTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No appointments today."));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final meeting = MeetingModel.fromFirestore(docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                    return _buildAppointmentCard(meeting);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookingDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentCard(MeetingModel meeting) {
    final isCompleted = meeting.status == MeetingStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompleted ? Colors.grey.shade100 : Colors.white,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? Colors.grey : Colors.blue,
          child: Text(DateFormat('HH:mm').format(meeting.startTime), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(meeting.purpose, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Client ID: ${meeting.clientId} | ${meeting.status.name}"),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Clinical Notes / Follow-up Advice:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: meeting.clinicalNotes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Enter notes here...",
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (val) {
                    // Auto-save notes
                    FirebaseFirestore.instance.collection('client_meetings').doc(meeting.id).update({'clinicalNotes': val});
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showBookingDialog(existingMeeting: meeting),
                      child: const Text("Reschedule"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        FirebaseFirestore.instance.collection('client_meetings').doc(meeting.id).update({'status': 'completed'});
                      },
                      child: const Text("Mark Complete"),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
          Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)))),
        ],
      ),
    );
  }

  void _showBookingDialog({MeetingModel? existingMeeting}) {
    // ... (Reuse the booking dialog logic we discussed earlier)
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
}