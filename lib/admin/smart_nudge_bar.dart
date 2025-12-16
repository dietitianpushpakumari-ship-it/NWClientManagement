import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/admin_appointment_detail_screen.dart';

class SmartNudgeBar extends StatelessWidget {
  final String coachId;
  final Ref ref;
  const SmartNudgeBar({super.key, required this.coachId, required this.ref});

  @override
  Widget build(BuildContext context) {


    return StreamBuilder<List<AppointmentModel>>(
      stream: ref.watch(meetingServiceProvider).streamNudgeAppointments(coachId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final allAppts = snapshot.data!;
        final nudges = _generateNudges(allAppts);

        if (nudges.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Text("SMART UPDATES (${nudges.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: nudges.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _buildNudgeCard(context, nudges[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  List<AppointmentModel> _generateNudges(List<AppointmentModel> list) {
    final now = DateTime.now();
    final nudges = <AppointmentModel>[];

    // 1. Overdue (Confirmed but in past)
    nudges.addAll(list.where((a) =>
    a.status == AppointmentStatus.confirmed && a.startTime.isBefore(now)
    ));

    // 2. Payment Pending (Any time)
    nudges.addAll(list.where((a) =>
    a.status == AppointmentStatus.payment_pending
    ));

    // 3. Verification Pending (Any time)
    nudges.addAll(list.where((a) =>
    a.status == AppointmentStatus.verification_pending
    ));

    // 4. Approaching (Confirmed & Next 2 Hours)
    nudges.addAll(list.where((a) =>
    a.status == AppointmentStatus.confirmed &&
        a.startTime.isAfter(now) &&
        a.startTime.isBefore(now.add(const Duration(hours: 2)))
    ));

    // Sort by urgency (Past -> Future)
    nudges.sort((a, b) => a.startTime.compareTo(b.startTime));

    return nudges;
  }

  Widget _buildNudgeCard(BuildContext context, AppointmentModel appt) {
    final now = DateTime.now();

    // Determine Nudge Type
    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (appt.status == AppointmentStatus.payment_pending) {
      title = "Payment Due";
      subtitle = "₹${appt.amountPaid?.toStringAsFixed(0) ?? '?'} Pending";
      color = Colors.orange;
      icon = Icons.currency_rupee;
    } else if (appt.status == AppointmentStatus.verification_pending) {
      title = "Confirm Payment";
      subtitle = "Verify Ref: ${appt.paymentReferenceId ?? 'N/A'}";
      color = Colors.blue;
      icon = Icons.fact_check;
    } else if (appt.startTime.isBefore(now)) {
      title = "Action Overdue";
      subtitle = "Mark Complete?";
      color = Colors.red;
      icon = Icons.history;
    } else {
      // Upcoming
      final minDiff = appt.startTime.difference(now).inMinutes;
      title = "Upcoming";
      subtitle = "Starts in $minDiff min";
      color = Colors.green;
      icon = Icons.timer;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAppointmentDetailsScreen(appointment: appt))),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(appt.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400)
          ],
        ),
      ),
    );
  }
}