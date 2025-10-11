import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Your App Imports (Ensure these files exist in your project structure)
import '../models/client_model.dart';
import '../models/package_assignment_model.dart';
import '../services/client_service.dart';
import '../services/vitals_service.dart';
import '../services/package_payment_service.dart';

// Your Screen Imports (Ensure paths are correct)
import 'package_assignment_page.dart';
import 'package_status_card.dart';
import 'vitals_history_page.dart';
import 'client_form_screen_old.dart'; // The target screen
import 'payment_ledger_screen.dart';


class ClientDashboardScreen_old extends StatefulWidget {
  final ClientModel client;
  const ClientDashboardScreen_old({super.key, required this.client});

  @override
  State<ClientDashboardScreen_old> createState() => _ClientDashboardScreen_oldState();
}

class _ClientDashboardScreen_oldState extends State<ClientDashboardScreen_old>
    with SingleTickerProviderStateMixin {

  late final ClientService _clientService;
  late final PackagePaymentService _paymentService;

  late TabController _tabController;
  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.info_outline), text: 'Info'),
    Tab(icon: Icon(Icons.history), text: 'Vitals/History'),
    Tab(icon: Icon(Icons.calendar_month), text: 'Schedule'),
  ];

  late ClientModel _currentClientData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _currentClientData = widget.client;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clientService = Provider.of<ClientService>(context, listen: false);
    _paymentService = Provider.of<PackagePaymentService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Core Navigation/Utility Methods ---

  void _navigateToEditClient() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientFormScreen_old(
          // 🎯 THE FIX: Ensure the required argument is passed.
          clientToEdit: _currentClientData,
        ),
      ),
    ).then((updatedClient) {
      if (updatedClient != null && updatedClient is ClientModel) {
        setState(() {
          _currentClientData = updatedClient;
        });
      }
    });
  }

  Future<void> _makeNativeCall(String mobile) async {
    final url = 'tel:$mobile';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer.')),
      );
    }
  }

  Future<void> _openWhatsAppVideo(String mobile) async {
    final uri = Uri.parse('whatsapp://send?phone=$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp is not installed.')),
      );
    }
  }

  // --- BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentClientData.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: _navigateToEditClient,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClientInfoTab(context),
          _buildVitalsHistoryTab(_currentClientData),
          _buildScheduleTab(context),
        ],
      ),
    );
  }

  // --- TAB VIEW BUILDERS ---

  Widget _buildClientInfoTab(BuildContext context) {
    final currentClient = _currentClientData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Details Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.person, 'Name', currentClient.name),
                  _buildDetailRow(Icons.phone, 'Mobile', currentClient.mobile),
                  _buildDetailRow(Icons.email, 'Email', currentClient.email ?? 'N/A'),
                  _buildDetailRow(Icons.cake, 'DOB', DateFormat.yMMMd().format(currentClient.dob)),
                  _buildDetailRow(Icons.label, 'Goal/Tag', currentClient.tag ?? 'Not Set'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Package Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),

          // FIXED LOGIC: StreamBuilder for PackageStatusCard
          _buildPackageStatusSection(currentClient.id),

          const SizedBox(height: 24),

          // Quick Communication Section
          const Text('Quick Communication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () => _makeNativeCall(currentClient.mobile),
                      icon: const Icon(Icons.call),
                      label: const Text('Native Call')
                  )
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () => _openWhatsAppVideo(currentClient.mobile),
                      icon: const Icon(Icons.videocam),
                      label: const Text('WhatsApp Video')
                  )
              ),
            ],
          ),

        ],
      ),
    );
  }

  // --- Package Status Card Builder (Stream Logic) ---
  Widget _buildPackageStatusSection(String clientId) {
    return StreamBuilder<List<PackageAssignmentModel>>(
      stream: _clientService.streamClientAssignments(clientId),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Text('Error loading packages: ${snapshot.error}');
        }

        final assignments = snapshot.data ?? [];

        return PackageStatusCard(
          assignments: assignments,
          onAssignTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PackageAssignmentPage(
                  clientId: clientId,
                  clientName: _currentClientData.name,
                ),
              ),
            ).then((_) => setState(() {}));
          },

          onEditTap: (assignment) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PaymentLedgerScreen(
                  assignment: assignment,
                  clientName: _currentClientData.name,
                  initialCollectedAmount: 0.0, // Placeholder - needs actual service call
                ),
              ),
            );
          },

          onDeleteTap: (assignment) {
            // TODO: Implement delete confirmation and call service method
          },
        );
      },
    );
  }

  // --- Helper Widget ---

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // --- Placeholder Tab Methods ---

  Widget _buildVitalsHistoryTab(ClientModel clientModel) {
    return VitalsHistoryPage(clientId: clientModel.id, clientName: clientModel.name);
  }

  Widget _buildScheduleTab(BuildContext context) {
    return const Center(child: Text('Schedule Tab (Placeholder)'));
  }
}