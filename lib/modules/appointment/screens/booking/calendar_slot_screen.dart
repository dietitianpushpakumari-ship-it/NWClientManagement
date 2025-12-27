import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/appointment/models/appointment_models.dart'; // Import your providers

class CalendarSlotScreen extends ConsumerStatefulWidget {
  final ServiceType service;
  const CalendarSlotScreen({super.key, required this.service});

  @override
  ConsumerState<CalendarSlotScreen> createState() => _CalendarSlotScreenState();
}

class _CalendarSlotScreenState extends ConsumerState<CalendarSlotScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCoachId; // null means "Any Available"
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // 1. WATCH THE SERVICE
    final meetingService = ref.watch(meetingServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Select Time Slot")),
      body: Column(
        children: [
          // A. Coach Preference Selector
          _buildCoachSelector(),

          // B. Date Strip (Next 14 Days)
          Container(
            height: 90,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              itemCount: 14,
              itemBuilder: (ctx, i) {
                final date = DateTime.now().add(Duration(days: i));
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 65,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.indigo : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('EEE').format(date).toUpperCase(),
                            style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.grey)),
                        const SizedBox(height: 4),
                        Text("${date.day}",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // C. Slots Grid
          Expanded(
            child: FutureBuilder<List<DateTime>>(
              // 🔄 RE-RUNS LOGIC WHEN DATE/COACH CHANGES
              future: meetingService.getAvailableSlots(
                date: _selectedDate,
                durationMins: widget.service.durationMins,
                specificCoachId: _selectedCoachId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error loading slots: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 50, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text("No available slots on ${DateFormat('MMMd').format(_selectedDate)}",
                            style: const TextStyle(color: Colors.grey)),
                        if(_selectedCoachId != null)
                          TextButton(
                            onPressed: () => setState(() => _selectedCoachId = null),
                            child: const Text("Try 'Any Available' instead"),
                          )
                      ],
                    ),
                  );
                }

                final slots = snapshot.data!;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (ctx, i) {
                    return ElevatedButton(
                      onPressed: _isLoading ? null : () => _confirmBooking(slots[i]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        DateFormat.jm().format(slots[i]),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCoachSelector() {
    // In a real app, use a FutureBuilder to fetch staff names from MeetingService
    // For now, hardcoded example based on your Multi-Tenant need
    return ExpansionTile(
      title: Text(_selectedCoachId == null ? "Any Available Staff (Fastest)" : "Specific Coach Selected"),
      leading: const Icon(Icons.person_search, color: Colors.indigo),
      children: [
        ListTile(
          title: const Text("⚡ Any Available (Recommended)"),
          leading: Radio<String?>(
              value: null,
              groupValue: _selectedCoachId,
              onChanged: (v) => setState(() => _selectedCoachId = v)
          ),
          onTap: () => setState(() => _selectedCoachId = null),
        ),
        // Example of specific selection - fetch this list dynamically!
        ListTile(
          title: const Text("Dr. Sarah Jones"),
          leading: Radio<String?>(
              value: "coach_1",
              groupValue: _selectedCoachId,
              onChanged: (v) => setState(() => _selectedCoachId = v)
          ),
          onTap: () => setState(() => _selectedCoachId = "coach_1"),
        ),
      ],
    );
  }

  // --- LOGIC ---

  Future<void> _confirmBooking(DateTime slotTime) async {
    // 1. Show Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Booking"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service: ${widget.service.name}"),
            const SizedBox(height: 8),
            Text("Time: ${DateFormat('EEE, dd MMM @ h:mm a').format(slotTime)}"),
            const SizedBox(height: 8),
            Text("Cost: ${widget.service.creditCost} Credit(s)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. Execute Booking
    setState(() => _isLoading = true);

    try {
      await ref.read(meetingServiceProvider).bookAppointment(
        service: widget.service,
        startTime: slotTime,
        specificCoachId: _selectedCoachId,
      );

      if (mounted) {
        // Success! Go back to Dashboard
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment Confirmed Successfully!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        // Handle Error (e.g. Insufficient Funds)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception:", "")), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}