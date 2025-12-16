import 'package:firebase_auth/firebase_auth.dart'; // 🎯 AUTH IMPORT
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookingSheet extends ConsumerStatefulWidget {
  final AppointmentSlot slot;
  final String coachId;
  final int initialDurationMinutes;

  const BookingSheet({super.key, required this.slot, required this.coachId, required this.initialDurationMinutes});

  @override
  ConsumerState<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<BookingSheet> {

  //final ClientService _clientService = ClientService();
  final _formKey = GlobalKey<FormState>();

  bool _isGuest = false;
  ClientModel? _selectedClient;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isBooking = false;
  late int _selectedDuration;
  final List<int> _durationOptions = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDurationMinutes;
  }

  void _showClientPicker() async {
    final selected = await showModalBottomSheet<ClientModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ClientPickerSheet(),
    );
    if (selected != null) {
      setState(() {
        _selectedClient = selected;
        _nameController.text = selected.name;
        _phoneController.text = selected.mobile;
      });
    }
  }

  Future<void> _book() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isGuest && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a client")));
      return;
    }

    setState(() => _isBooking = true);

    try {
      // ... (Existing Auth Logic) ...
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminUid = currentUser?.uid ?? 'unknown_admin';
      final adminName = currentUser?.displayName ?? currentUser?.email ?? 'Admin';

      await ref.read(meetingServiceProvider).bookSession(
        clientId: _isGuest ? null : _selectedClient!.id,
        clientName: _isGuest ? _nameController.text : _selectedClient!.name,
        guestPhone: _phoneController.text,
        coachId: widget.coachId,
        startTime: widget.slot.startTime,
        durationMinutes: _selectedDuration,
        topic: _topicController.text,
        useFreeSession: false,
        isAdminBooking: true,
        performedByUid: adminUid,
        performedByName: adminName,
      );

      if (mounted) {
        // 🎯 FIX: Return 'true' to indicate success
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Confirmed!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Book Slot: ${DateFormat.jm().format(widget.slot.startTime)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Duration:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: _durationOptions.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text("$d min"),
                  selected: _selectedDuration == d,
                  onSelected: (v) => setState(() => _selectedDuration = d),
                  selectedColor: Colors.indigo.shade100,
                  labelStyle: TextStyle(color: _selectedDuration == d ? Colors.indigo : Colors.black),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTypeBtn("Existing Client", !_isGuest, () => setState(() => _isGuest = false))),
                const SizedBox(width: 10),
                Expanded(child: _buildTypeBtn("New Guest", _isGuest, () => setState(() => _isGuest = true))),
              ],
            ),
            const SizedBox(height: 20),
            if (!_isGuest)
              GestureDetector(
                onTap: _showClientPicker,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Select Client", border: OutlineInputBorder(), prefixIcon: Icon(Icons.search), suffixIcon: Icon(Icons.arrow_drop_down)),
                    validator: (v) => _selectedClient == null ? "Select a client" : null,
                  ),
                ),
              )
            else
              Column(children: [
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Guest Name", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Req" : null),
                const SizedBox(height: 10),
                TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: "Mobile", border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "Req" : null),
              ]),
            const SizedBox(height: 10),
            TextFormField(controller: _topicController, decoration: const InputDecoration(labelText: "Purpose / Topic", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Req" : null),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _book,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM BOOKING"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBtn(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isSelected ? Colors.indigo : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ClientPickerSheet extends ConsumerStatefulWidget {
  const ClientPickerSheet({super.key});
  @override
  ConsumerState<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends ConsumerState<ClientPickerSheet> {

  List<ClientModel> _allClients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    final clientService = ref.read(clientServiceProvider);
    final clients = await clientService.getAllClients();
    if(mounted) setState(() { _allClients = clients; _filteredClients = clients; _isLoading = false; });
  }

  void _filter(String q) {
    setState(() => _filteredClients = _allClients.where((c) => c.name.toLowerCase().contains(q.toLowerCase()) || c.mobile.contains(q)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "Search Client...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
              itemCount: _filteredClients.length,
              separatorBuilder: (_,__) => const Divider(),
              itemBuilder: (context, index) {
                final client = _filteredClients[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(client.name[0])),
                  title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(client.mobile),
                  onTap: () => Navigator.pop(context, client),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}