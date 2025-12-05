import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nutricare_client_management/admin/appointment_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/admin/meeting_service.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart'; // Ensure this import exists

class AdminAppointmentDetailsScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const AdminAppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AdminAppointmentDetailsScreen> createState() => _AdminAppointmentDetailsScreenState();
}

class _AdminAppointmentDetailsScreenState extends State<AdminAppointmentDetailsScreen> {
  final MeetingService _service = MeetingService();
  final ClientService _clientService = ClientService();

  final TextEditingController _noteCtrl = TextEditingController();
  late AppointmentModel _appt;
  ClientModel? _clientData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
    _noteCtrl.text = _appt.adminNote ?? "";
    _fetchClientDetails();
  }

  Future<void> _fetchClientDetails() async {
    if (_appt.clientId != null) {
      try {
        final client = await _clientService.getClientById(_appt.clientId!);
        if (mounted) setState(() => _clientData = client);
      } catch (_) {}
    }
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance.collection('appointments').doc(_appt.id).get();
    if (doc.exists && mounted) {
      setState(() {
        _appt = AppointmentModel.fromFirestore(doc);
        _isLoading = false;
      });
    }
  }

  // --- ACTIONS ---

  // 🎯 Handle Redirection based on onboarding status
  void _handleClientRedirection() {
    bool hasPatientId = _clientData?.patientId != null && _clientData!.patientId!.isNotEmpty;

    if (hasPatientId) {
      // Existing Client -> Dashboard
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: _clientData!))
      );
    } else {
      // New/Guest -> Setup Checklist
      // If _clientData is null (Guest), create a temp model to pre-fill the form
      final clientToPass = _clientData ?? ClientModel(
        id: '', // Empty ID signals new creation
        name: _appt.clientName,
        mobile: _appt.guestPhone ?? '',
        email: '',
        gender: 'Female', // Default
        dob: DateTime(1990),
        loginId: _appt.guestPhone ?? '',
        patientId: null,
        clientType: 'new',
        address: '',
      );

      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(initialProfile: clientToPass))
      );
    }
  }

  Future<void> _updateStatus(AppointmentStatus status) async {
    Color actionColor = status == AppointmentStatus.confirmed ? Colors.green : (status == AppointmentStatus.cancelled ? Colors.red : Colors.blue);
    String actionLabel = status.name.toUpperCase();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$actionLabel Appointment?"),
        content: Text("Are you sure you want to mark this appointment as $actionLabel?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: const Text("Yes, Proceed"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _service.updateAppointmentStatus(_appt.id, status);
        await _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status updated to $actionLabel")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePayment() async {
    final amtCtrl = TextEditingController(text: _appt.amountPaid != null && _appt.amountPaid! > 0 ? _appt.amountPaid.toString() : "");
    final refCtrl = TextEditingController(text: _appt.paymentReferenceId ?? "");
    String method = _appt.paymentMethod ?? 'Cash';

    final List<String> paymentOptions = ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Free', 'Credit Note'];

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Record Payment Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: amtCtrl, decoration: const InputDecoration(labelText: "Amount", prefixText: "₹ "), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: paymentOptions.contains(method) ? method : 'Cash',
              items: paymentOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => method = v!,
              decoration: const InputDecoration(labelText: "Method"),
            ),
            const SizedBox(height: 10),
            TextField(controller: refCtrl, decoration: const InputDecoration(labelText: "Reference ID / Note")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);

              final updates = {
                'amount': double.tryParse(amtCtrl.text) ?? 0.0,
                'paymentRef': refCtrl.text,
                'paymentMethod': method,
                'paymentDate': FieldValue.serverTimestamp(),
              };

              await FirebaseFirestore.instance.collection('appointments').doc(_appt.id).update(updates);
              _refresh();
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment recorded.")));
            },
            child: const Text("Save Details"),
          )
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    await _service.updateAppointmentNote(_appt.id, _noteCtrl.text);
    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clinical note saved.")));
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _uploadPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final ref = FirebaseStorage.instance.ref().child('appointment_photos/${_appt.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('appointments').doc(_appt.id).update({
          'sessionPhotos': FieldValue.arrayUnion([url])
        });
        _refresh();
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
      } finally {
        if(mounted) setState(() => _isLoading = false);
      }
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text("Session Details"), backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),

            _buildSectionTitle("Client Info"),
            _buildClientCard(),
            const SizedBox(height: 20),

            _buildSectionTitle("Payment Status"),
            _buildPaymentCard(),
            const SizedBox(height: 20),

            _buildSectionTitle("Session Photos"),
            _buildPhotoGrid(),
            const SizedBox(height: 20),

            _buildSectionTitle("Actions"),
            _buildActionButtons(),
            const SizedBox(height: 20),

            _buildSectionTitle("Clinical Notes"),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]),
              child: TextField(
                controller: _noteCtrl,
                maxLines: 4,
                decoration: const InputDecoration(border: OutlineInputBorder(borderSide: BorderSide.none), hintText: "Enter clinical observations...", contentPadding: EdgeInsets.all(16)),
              ),
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: _saveNote, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("Save Note"))),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }

  Widget _buildHeaderCard() {
    Color color = Colors.orange;
    if (_appt.status == AppointmentStatus.confirmed) color = Colors.green;
    else if (_appt.status == AppointmentStatus.cancelled) color = Colors.red;
    else if (_appt.status == AppointmentStatus.completed) color = Colors.blue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: color, width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEEE, d MMM y').format(_appt.startTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Chip(label: Text(_appt.status.name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)), backgroundColor: color.withOpacity(0.1), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text("${DateFormat.jm().format(_appt.startTime)} - ${DateFormat.jm().format(_appt.endTime)}", style: const TextStyle(fontSize: 15)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.topic, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(_appt.topic, style: const TextStyle(fontSize: 14, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }

  // 🎯 SMART CLIENT CARD with logic fix
  Widget _buildClientCard() {
    // Check if fully onboarded (has Patient ID)
    bool hasPatientId = _clientData?.patientId != null && _clientData!.patientId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.indigo.shade50, child: Text(_appt.clientName.isNotEmpty ? _appt.clientName[0] : "?", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_appt.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                        hasPatientId ? "ID: ${_clientData!.patientId}" : "Status: Not Onboarded",
                        style: TextStyle(fontSize: 12, color: hasPatientId ? Colors.grey.shade600 : Colors.orange.shade700, fontWeight: FontWeight.bold)
                    ),
                    if (_appt.guestPhone != null)
                      Text(_appt.guestPhone!, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),

              // 🎯 LOGIC: If Onboarded -> Dashboard. Else -> Setup Checklist.
              if (hasPatientId)
                IconButton(
                  icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                  tooltip: "Open Dashboard",
                  onPressed: _handleClientRedirection,
                )
              else
                ActionChip(
                  label: const Text("Complete Setup", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: Colors.orange,
                  onPressed: _handleClientRedirection,
                ),
            ],
          ),
          if (_appt.guestPhone != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildContactBtn(Icons.call, "Call", Colors.blue, "tel:${_appt.guestPhone}"),
                _buildContactBtn(FontAwesomeIcons.whatsapp, "WhatsApp", Colors.green, "https://wa.me/${_appt.guestPhone}"),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildContactBtn(IconData icon, String label, Color color, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildPaymentCard() {
    bool isPaid = _appt.paymentDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Recorded Amount", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("₹${_appt.amountPaid?.toStringAsFixed(0) ?? '0'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              if (isPaid)
                const Chip(label: Text("RECORDED", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.green)
              else
                const Chip(label: Text("NOT RECORDED", style: TextStyle(color: Colors.white, fontSize: 10)), backgroundColor: Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          if (isPaid)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Via: ${_appt.paymentMethod ?? 'Unknown'}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(DateFormat('dd MMM').format(_appt.paymentDate!), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _updatePayment,
              icon: const Icon(Icons.payment, size: 18),
              label: Text(isPaid ? "Update Details" : "Record Payment"),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_appt.status == AppointmentStatus.cancelled || _appt.status == AppointmentStatus.completed) {
      return const Center(child: Text("This session is closed.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
    }

    return Column(
      children: [
        if (_appt.status != AppointmentStatus.confirmed)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(AppointmentStatus.confirmed),
              icon: const Icon(Icons.check_circle),
              label: const Text("CONFIRM APPOINTMENT"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 2),
            ),
          ),

        if (_appt.status == AppointmentStatus.confirmed)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(AppointmentStatus.completed),
              icon: const Icon(Icons.done_all),
              label: const Text("MARK AS COMPLETED"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 2),
            ),
          ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _updateStatus(AppointmentStatus.cancelled),
            icon: const Icon(Icons.cancel),
            label: const Text("CANCEL APPOINTMENT"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      children: [
        if (_appt.sessionPhotos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: _appt.sessionPhotos.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => _launchUrl(_appt.sessionPhotos[i]),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_appt.sessionPhotos[i], fit: BoxFit.cover)),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploadPhoto,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text("Upload Photo"),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}