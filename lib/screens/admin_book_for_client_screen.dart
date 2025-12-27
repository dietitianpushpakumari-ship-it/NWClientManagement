import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/config/nutricare_services.dart';
import 'package:nutricare_client_management/modules/appointment/models/appointment_models.dart';

class AdminBookForClientScreen extends ConsumerStatefulWidget {
  final String? preSelectedClientId; // Optional: If coming from Client Details
  const AdminBookForClientScreen({super.key, this.preSelectedClientId});

  @override
  ConsumerState<AdminBookForClientScreen> createState() => _AdminBookForClientScreenState();
}

class _AdminBookForClientScreenState extends ConsumerState<AdminBookForClientScreen> {
  // Booking State
  String? _selectedClientId;
  ServiceType _selectedService = NutricareServices.all[1]; // Default to Standard 30min
  DateTime _selectedDate = DateTime.now();
  String? _selectedCoachId; // Null = Any Available

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.preSelectedClientId;
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH AUTH & SERVICE
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Book for Client")),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (user) {
          if (user == null) return const Center(child: Text("Admin not logged in"));

          return Column(
            children: [
              // 1. CLIENT SEARCH (Only show if not pre-selected)
              if (widget.preSelectedClientId == null)
                _buildClientSelector(),

              const Divider(height: 1),

              // 2. CONFIGURATION (Service & Coach)
              _buildConfigSection(),

              const Divider(height: 1),

              // 3. CALENDAR STRIP
              _buildDateStrip(),

              const Divider(height: 1),

              // 4. SLOTS GRID
              Expanded(child: _buildSlotsGrid()),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildClientSelector() {
    // Simple Dropdown for now. For production, use a Search Delegate or Autocomplete
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clients').orderBy('name').limit(20).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final clients = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<String>(
            value: _selectedClientId,
            decoration: const InputDecoration(labelText: "Select Client", border: OutlineInputBorder()),
            items: clients.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: Text("${data['name']} (${data['phone'] ?? 'No Phone'})"),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedClientId = val),
          ),
        );
      },
    );
  }

  Widget _buildConfigSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Service Selector
          Expanded(
            child: DropdownButtonFormField<ServiceType>(
              value: _selectedService,
              decoration: const InputDecoration(labelText: "Service Type", border: OutlineInputBorder()),
              items: NutricareServices.all.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedService = v!),
            ),
          ),
          const SizedBox(width: 12),
          // Coach Selector (Simplified)
          Expanded(
            child: DropdownButtonFormField<String?>(
              value: _selectedCoachId,
              decoration: const InputDecoration(labelText: "Dietitian", border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: null, child: Text("Any Available")),
                // Add specific coaches here if needed fetching from DB
              ],
              onChanged: (v) => setState(() => _selectedCoachId = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (ctx, i) {
          final date = DateTime.now().add(Duration(days: i));
          final isSelected = date.day == _selectedDate.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black54)),
                  Text("${date.day}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsGrid() {
    final meetingService = ref.watch(meetingServiceProvider);

    return FutureBuilder<List<DateTime>>(
      // Re-fetch slots whenever config changes
      future: meetingService.getAvailableSlots(
        date: _selectedDate,
        durationMins: _selectedService.durationMins,
        specificCoachId: _selectedCoachId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No slots available."));

        final slots = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2.5, crossAxisSpacing: 10, mainAxisSpacing: 10
          ),
          itemCount: slots.length,
          itemBuilder: (ctx, i) {
            return ElevatedButton(
              onPressed: () => _confirmBooking(slots[i]),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade50, foregroundColor: Colors.indigo),
              child: Text(DateFormat.jm().format(slots[i])),
            );
          },
        );
      },
    );
  }

  // --- ACTIONS ---

  Future<void> _confirmBooking(DateTime slotTime) async {
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a client first")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Admin Booking"),
        content: Text("Book ${_selectedService.name} for Client?\n\nTime: ${DateFormat.jm().format(slotTime)}\nCost: ${_selectedService.creditCost} Credits will be deducted from CLIENT'S wallet."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Book Now")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(meetingServiceProvider).bookAppointment(
        service: _selectedService,
        startTime: slotTime,
        specificCoachId: _selectedCoachId,
        onBehalfOfClientId: _selectedClientId, // 🎯 CRITICAL: Admin booking for client
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment Booked Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Handle "Insufficient Credits" error here
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.toString().replaceAll('Exception:', '')}"), backgroundColor: Colors.red));
      }
    }
  }
}