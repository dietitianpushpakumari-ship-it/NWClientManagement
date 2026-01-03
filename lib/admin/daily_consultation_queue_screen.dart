import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 🎯 Screens & Models
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/consultation_gateway_screen.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';

// 🎯 Helpers
import 'package:nutricare_client_management/helper/auth_service.dart';

class DailyConsultationQueueScreen extends ConsumerStatefulWidget {
  const DailyConsultationQueueScreen({super.key});

  @override
  ConsumerState<DailyConsultationQueueScreen> createState() => _DailyConsultationQueueScreenState();
}

class _DailyConsultationQueueScreenState extends ConsumerState<DailyConsultationQueueScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Access Denied")));

    final sessionService = ref.watch(consultationServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Live Ops Board", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1A1A1A))),
            Text(DateFormat('EEEE, d MMMM').format(_selectedDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
              onPressed: _pickDate,
            ),
          ),
        ],
      ),

      // 🎯 ACTION BUTTON: Add Patient to Queue
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Patient", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: StreamBuilder<List<ConsultationSessionModel>>(
        stream: sessionService.streamSessionsForDate(
          dietitianId: user.uid,
          date: _selectedDate,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.coffee_rounded, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text("All clear for ${DateFormat('MMM d').format(_selectedDate)}",
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Extra bottom padding for FAB
            itemCount: sessions.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _ConsultationQueueCard(session: sessions[index]);
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 🎯 ACTIONS
  // ===========================================================================

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add to Queue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),

            // Option 1: Existing Patient (Search -> Gateway)
            _buildOptionTile(
              icon: Icons.person_search_rounded, color: Colors.blue,
              title: "Existing Patient", subtitle: "Search history and start session",
              onTap: () { Navigator.pop(context); _showClientSearch(); },
            ),
            const SizedBox(height: 16),

            // Option 2: New Registration (Direct to Checklist)
            _buildOptionTile(
              icon: Icons.person_add_alt_1_rounded, color: Colors.teal,
              title: "New Registration", subtitle: "Create profile and start initial visit",
              onTap: () { Navigator.pop(context); _registerNewPatient(); },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12))])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showClientSearch() {
    showSearch(context: context, delegate: ClientSearchDelegate(ref, (client) {
      // 🎯 Redirect to Gateway Screen (History View)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultationGatewayScreen(client: client),
        ),
      );
    }));
  }

  void _registerNewPatient() {
    // 🎯 DIRECT ENTRY: Go straight to checklist with a blank client.
    // The checklist screen handles the "Profile Creation" step internally.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          // Pass a blank model to indicate a new patient
          client: null,
          forceNew: true,    // Treats this as a fresh start
          isFollowup: false, // It's an initial consultation
        ),
      ),
    ).then((_) {
      // Refresh queue when returning
      setState(() {});
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.indigo),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

// ===========================================================================
// 🎯 SEARCH DELEGATE
// ===========================================================================

class ClientSearchDelegate extends SearchDelegate {
  final WidgetRef ref;
  final Function(ClientModel) onSelect;

  ClientSearchDelegate(this.ref, this.onSelect);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) return const Center(child: Text("Type name to search..."));

    return FutureBuilder<List<ClientModel>>(
      future: ref.read(clientServiceProvider).searchClients(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final clients = snapshot.data ?? [];
        if (clients.isEmpty) return const Center(child: Text("No clients found."));

        return ListView.builder(
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final c = clients[index];
            return ListTile(
              leading: CircleAvatar(
                  backgroundImage: c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                  child: c.photoUrl == null ? Text(c.name.isNotEmpty ? c.name[0] : '?') : null
              ),
              title: Text(c.name),
              subtitle: Text(c.mobile),
              onTap: () {
                close(context, null);
                onSelect(c);
              },
            );
          },
        );
      },
    );
  }
}

// ===========================================================================
// 🎯 QUEUE CARD (Live Ops View)
// ===========================================================================

class _ConsultationQueueCard extends ConsumerWidget {
  final ConsultationSessionModel session;
  const _ConsultationQueueCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ClientModel>(
      future: ref.read(clientServiceProvider).getClientById(session.clientId),
      builder: (context, snapshot) {
        final client = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final clientName = client?.name ?? "Loading...";

        final isCompleted = session.status == 'complete';
        final isOngoing = session.status == 'Ongoing';

        Color statusColor = isCompleted ? Colors.green : (isOngoing ? Colors.orange : Colors.blue);
        String timeStr = DateFormat('hh:mm a').format(session.startTime.toDate());

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
              if (isOngoing) BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 0, spreadRadius: 1, offset: Offset.zero),
            ],
          ),
          child: InkWell(
            onTap: isLoading || client == null ? null : () => _openChecklist(context, client, session),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --- TOP ROW ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          children: [
                            Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(isCompleted ? "DONE" : (isOngoing ? "NOW" : "WAIT"),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: session.consultationType == 'Followup' ? Colors.purple.shade50 : Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text(
                                      session.consultationType.toUpperCase(),
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: session.consultationType == 'Followup' ? Colors.purple : Colors.teal)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (!isLoading)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.indigo.shade50,
                          child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.indigo.shade400, size: 14),
                        )
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // --- BOTTOM ROW: EXTENDED MICRO-PIPELINE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPipelineStage("Profile", Icons.person, session.steps['profile'] ?? false),
                      _buildPipelineConnector(),
                      _buildPipelineStage("Vitals", Icons.monitor_heart, session.steps['vitals'] ?? false),
                      _buildPipelineConnector(),
                      _buildPipelineStage("History", Icons.history_edu, session.steps['history'] ?? false),
                      _buildPipelineConnector(),
                      _buildPipelineStage("Clinical", Icons.medical_services, session.steps['clinical'] ?? false),
                      _buildPipelineConnector(),
                      _buildPipelineStage("Plan", Icons.restaurant_menu, session.steps['plan'] ?? false),
                      _buildPipelineConnector(),
                      // 🎯 Billing/Package Stage
                      _buildPipelineStage("Billing", Icons.account_balance_wallet_rounded, session.steps['payment'] ?? false),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPipelineStage(String label, IconData icon, bool isComplete) {
    final color = isComplete ? Colors.green : Colors.grey.shade300;
    final iconColor = isComplete ? Colors.white : Colors.grey.shade400;

    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isComplete ? Colors.green : Colors.transparent,
            shape: BoxShape.circle,
            border: isComplete ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: isComplete ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
            label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isComplete ? Colors.green.shade700 : Colors.grey.shade400
            )
        ),
      ],
    );
  }

  Widget _buildPipelineConnector() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
        color: Colors.grey.shade100,
      ),
    );
  }

  void _openChecklist(BuildContext context, ClientModel client, ConsultationSessionModel session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: client,
          forceNew: false,
          isFollowup: session.consultationType == 'Followup',
          viewSessionId: session.id,
        ),
      ),
    );
  }
}