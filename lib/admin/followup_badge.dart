import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FollowUpBadge extends StatelessWidget {
  final DateTime? lastConsultationDate;
  final int intervalDays;

  const FollowUpBadge({
    super.key,
    required this.lastConsultationDate,
    required this.intervalDays, // e.g., 7 for weekly, 15 for bi-weekly
  });

  @override
  Widget build(BuildContext context) {
    if (lastConsultationDate == null) {
      return _buildChip("New Client", Colors.blue, Icons.star);
    }

    final now = DateTime.now();
    final nextDueDate = lastConsultationDate!.add(Duration(days: intervalDays));
    final difference = nextDueDate.difference(now).inDays;

    // 1. OVERDUE (Red) - Date has passed
    if (nextDueDate.isBefore(now) && difference < 0) {
      final daysOver = difference.abs();
      return _buildChip(
          "Overdue by $daysOver days",
          Colors.red,
          Icons.warning_amber_rounded
      );
    }

    // 2. WINDOW OPEN (Orange) - Due within 3 days
    if (difference <= 3) {
      return _buildChip(
        "Follow-up Open (Due: ${DateFormat('d MMM').format(nextDueDate)})",
        Colors.orange,
        Icons.access_time_filled,
        isPulsing: true, // Optional: Make it visually distinct
      );
    }

    // 3. ON TRACK (Green) - More than 3 days away
    return _buildChip(
        "Next: ${DateFormat('d MMM').format(nextDueDate)}",
        Colors.teal,
        Icons.check_circle_outline
    );
  }

  Widget _buildChip(String text, Color color, IconData icon, {bool isPulsing = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}