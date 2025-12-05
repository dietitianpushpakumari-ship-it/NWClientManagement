import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/notification_helper.dart'; // Import helper

class SmartBookingReminders extends StatefulWidget {
  final String coachId;
  const SmartBookingReminders({super.key, required this.coachId});

  @override
  State<SmartBookingReminders> createState() => _SmartBookingRemindersState();
}

class _SmartBookingRemindersState extends State<SmartBookingReminders> {
  final MeetingService _service = MeetingService();

  // Helper to trigger system notifications for the list
  void _scheduleSystemNotifications(List<AppointmentModel> appointments) {
    for (var appt in appointments) {
      // Schedule alert 10 mins before
      final reminderTime = appt.startTime.subtract(const Duration(minutes: 10));
      if (reminderTime.isAfter(DateTime.now())) {
      //  NotificationHelper.scheduleMeetingReminder(
        //    appt.id,
          //  appt.clientName,
            //reminderTime
        //);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _service.streamUpcomingReminders(widget.coachId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if empty
        }

        final list = snapshot.data!;
        // Trigger system notifications hook
        WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleSystemNotifications(list));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.deepOrange, size: 18),
                  const SizedBox(width: 8),
                  Text("UPCOMING SESSIONS (${list.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                itemBuilder: (ctx, i) => _buildReminderCard(list[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(AppointmentModel appt) {
    final now = DateTime.now();
    final diff = appt.startTime.difference(now);

    String timeLabel;
    Color statusColor = Colors.blue;
    bool isUrgent = false;

    if (diff.inMinutes < 0) {
      timeLabel = "Happening Now";
      statusColor = Colors.green;
      isUrgent = true;
    } else if (diff.inMinutes < 60) {
      timeLabel = "In ${diff.inMinutes} mins";
      statusColor = Colors.deepOrange;
      isUrgent = true;
    } else {
      timeLabel = DateFormat('h:mm a').format(appt.startTime);
      statusColor = Colors.indigo;
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent ? Border.all(color: statusColor.withOpacity(0.3), width: 2) : null,
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(timeLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              Icon(
                  appt.type == AppointmentType.online ? Icons.videocam : Icons.person_pin_circle,
                  color: Colors.grey, size: 18
              )
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appt.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(appt.topic, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),

          Row(
            children: [
              if (appt.meetLink != null || appt.type == AppointmentType.online)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launch(appt.meetLink ?? "https://meet.google.com/"),
                    icon: const Icon(Icons.video_call, size: 16),
                    label: const Text("Join"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        elevation: 0
                    ),
                  ),
                ),
              if (appt.guestPhone != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _launch("tel:${appt.guestPhone}"),
                  tooltip: "Call Client",
                  style: IconButton.styleFrom(backgroundColor: Colors.green.shade50),
                )
              ]
            ],
          )
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}