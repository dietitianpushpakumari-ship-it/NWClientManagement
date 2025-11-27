import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';

class PendingClientListScreen extends StatefulWidget {
  const PendingClientListScreen({super.key});

  @override
  State<PendingClientListScreen> createState() => _PendingClientListScreenState();
}

class _PendingClientListScreenState extends State<PendingClientListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🎯 STREAM: Fetch All Clients
  Stream<List<ClientModel>> _streamClients() {
    return FirebaseFirestore.instance
        .collection('clients')
        .where('isSoftDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      // 🎯 NEW: FLOATING ACTION BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Checklist with NULL profile (Starts fresh creation flow)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientConsultationChecklistScreen(initialProfile: null)),
          );
        },
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Client", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),

      body: Stack(
        children: [
          // 1. AMBIENT GLOW
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. CUSTOM HEADER (No App Bar)
                _buildHeader(),

                // 3. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 20),

                // 4. PILL TABS
                _buildTabBar(),
                const SizedBox(height: 16),

                // 5. TAB VIEWS
                Expanded(
                  child: StreamBuilder<List<ClientModel>>(
                    stream: _streamClients(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No clients found."));
                      }

                      final allClients = snapshot.data!;
                      // Filter by Search
                      final filtered = allClients.where((c) =>
                      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          c.mobile.contains(_searchQuery)
                      ).toList();

                      // 🎯 SEGMENTATION LOGIC
                      final newLeads = filtered.where((c) => c.clientType == 'new' || c.clientType.isEmpty).toList();
                      final activeClients = filtered.where((c) => c.clientType == 'active').toList();
                      final historyClients = filtered.where((c) => c.clientType == 'one_time' || c.clientType == 'expired').toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClientList(newLeads, "Waiting for assignment", Colors.blueGrey, isNew: true),
                          _buildClientList(activeClients, "Currently on plan", Colors.green, isActive: true),
                          _buildClientList(historyClients, "Past consultations", Colors.orange, isHistory: true),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 16),
              const Text("Client Directory", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
          // Filter Icon (Visual only for now)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.filter_list, color: Colors.indigo),
          ),
        ],
      ),
    );
  }

  // --- SEARCH BAR ---
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: "Search by Name or Mobile...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // --- TABS ---
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.indigo,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: "New / Pending"),
          Tab(text: "Active Members"),
          Tab(text: "History"),
        ],
      ),
    );
  }

  // --- LIST BUILDER ---
  Widget _buildClientList(List<ClientModel> clients, String emptyMsg, Color accentColor, {bool isNew = false, bool isActive = false, bool isHistory = false}) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("No clients here", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      // 🎯 Added bottom padding so FAB doesn't cover the last item
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        return _buildClientCard(clients[index], accentColor, isNew, isActive, isHistory);
      },
    );
  }

  // --- CLIENT CARD ---
  Widget _buildClientCard(ClientModel client, Color color, bool isNew, bool isActive, bool isHistory) {
    return GestureDetector(
      // 🎯 Navigation Logic
      onTap: () {
        if (isNew) {
          // New -> Onboarding Flow
          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(initialProfile: client)));
        } else {
          // Active/History -> Dashboard
          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.1),
                  backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                  child: client.photoUrl == null ? Text(client.name.isNotEmpty ? client.name[0] : '?', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)) : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(client.mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(width: 10),
                          if (client.patientId != null) ...[
                            Icon(Icons.badge, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(client.patientId!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Chip
                _buildStatusChip(client.clientType, color),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

            // 🎯 ACTION FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isNew)
                  const Text("⚠️ Pending Assignment", style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))
                else if (isActive)
                  const Text("🟢 Active Plan", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold))
                else
                  const Text("🔴 Expired / One-time", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),

                Row(
                  children: [
                    if (isNew)
                      _buildActionBtn("Onboard", Icons.arrow_forward, Colors.indigo, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(initialProfile: client)));
                      }),
                    if (!isNew)
                      _buildActionBtn("Manage", Icons.settings, Colors.grey, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDashboardScreen(client: client)));
                      }),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String type, Color color) {
    String label = type.toUpperCase();
    if (type.isEmpty) label = "NEW";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 4),
            Icon(icon, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}