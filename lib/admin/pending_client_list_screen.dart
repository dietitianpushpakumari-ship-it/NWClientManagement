import 'dart:ui';
import 'package:flutter/material.dart';
// 🎯 CRITICAL: Riverpod Imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/screens/dash/client_dashboard_screenv2.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

// 🎯 PROVIDER: Fetch Active Package for a Client from 'patient_subscription'
final clientActivePackageProvider = StreamProvider.family.autoDispose<PackageAssignmentModel?, String>((ref, clientId) {
  return ref.read(firestoreProvider)
      .collection(MasterCollectionMapper.getPath(TransactionEntity.entity_patientSubscription))
      .where('clientId', isEqualTo: clientId)
      .where('status', isEqualTo: 'active') // Only fetch active ones
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;

    // 1. Convert to Models
    final packages = snapshot.docs.map((d) {
      try {
        return PackageAssignmentModel.fromFirestore(d);
      } catch (e) {
        return null;
      }
    }).whereType<PackageAssignmentModel>().toList();

    final now = DateTime.now();

    // 2. Filter: Must not be expired
    final validPackages = packages.where((p) => p.expiryDate.isAfter(now)).toList();

    if (validPackages.isEmpty) return null;

    // 3. Sort: Get the one expiring last (longest remaining)
    validPackages.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));

    return validPackages.first;
  });
});

final allActiveClientsStreamProvider = StreamProvider.autoDispose<List<ClientModel>>((ref) {
  final clientService = ref.watch(clientServiceProvider);
  return clientService.streamAllClientsForReporting();
});

class PendingClientListScreen extends ConsumerStatefulWidget {
  const PendingClientListScreen({super.key});

  @override
  ConsumerState<PendingClientListScreen> createState() => _PendingClientListScreenState();
}

class _PendingClientListScreenState extends ConsumerState<PendingClientListScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allActiveClientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(client: null)),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
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
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 20),
                _buildTabBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: clientsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Center(child: Text("Error loading clients: ${err.toString()}")),
                    data: (allClients) {
                      final filtered = allClients.where((c) =>
                      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          c.mobile.contains(_searchQuery)
                      ).toList();

                      final newLeads = filtered.where((c) => c.clientType == 'new' || c.clientType.isEmpty).toList();
                      final activeClients = filtered.where((c) => c.clientType == 'active').toList();
                      final historyClients = filtered.where((c) => c.clientType == 'one_time' || c.clientType == 'expired').toList();

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClientList(newLeads, "Waiting for assignment", Colors.blueGrey, isNew: true),
                          // 🎯 Active List with Nudges
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

  // --- WIDGETS ---

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.1), shape: BoxShape.circle),
            child: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
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

  Widget _buildClientList(List<ClientModel> clients, String emptyMsg, Color accentColor, {bool isNew = false, bool isActive = false, bool isHistory = false}) {
    if (clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        return _buildClientCard(clients[index], accentColor, isNew, isActive, isHistory);
      },
    );
  }

  Widget _buildClientCard(ClientModel client, Color color, bool isNew, bool isActive, bool isHistory) {
    return GestureDetector(
      onTap: () {
        if (isNew) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(client: client)));
        } else {
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color.withOpacity(0.1),
                  backgroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                  child: client.photoUrl == null ? Text(client.name.isNotEmpty ? client.name[0] : '?', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)) : null,
                ),
                const SizedBox(width: 16),
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
                _buildStatusChip(client.clientType, color),
              ],
            ),

            // 🎯 NEW: Insert Smart Nudge Widget
            if (isActive)
              ClientPackageNudge(clientId: client.id),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),

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
                      _buildActionBtn("Onboard", Icons.arrow_forward, Theme.of(context).colorScheme.primary, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClientConsultationChecklistScreen(client: client)));
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
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

// 🎯 NEW WIDGET: Smart Nudge for Package Info
class ClientPackageNudge extends ConsumerWidget {
  final String clientId;
  const ClientPackageNudge({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageAsync = ref.watch(clientActivePackageProvider(clientId));

    return packageAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (activeAssignment) {
        if (activeAssignment == null) return const SizedBox.shrink();

        final durationDays = activeAssignment.expiryDate.difference(activeAssignment.purchaseDate).inDays;

        // 🎯 RULE: Must be minimum 1 month (~28 days) duration
        if (durationDays < 28) return const SizedBox.shrink();

        final now = DateTime.now();
        final daysLeft = activeAssignment.expiryDate.difference(now).inDays;

        // 🎯 FIX: Use explicit Category, Type & Color logic
        String categoryName = activeAssignment.category ?? '';
        String typeName = activeAssignment.type ?? ''; // Get Type

        // Build Label: "PREMIUM MEMBER • WEIGHT LOSS"
        String labelPart1 = categoryName.isEmpty ? "MEMBER" : "${categoryName.toUpperCase()} MEMBER";
        String label = typeName.isNotEmpty ? "$labelPart1 • ${typeName.toUpperCase()}" : labelPart1;

        // Ensure color logic respects saved preference or falls back safely
        Color color = Colors.blue;
        if (activeAssignment.colorCode != null) {
          try {
            color = Color(int.parse(activeAssignment.colorCode!));
          } catch (_) {}
        } else {
          // Fallback logic
          final catLower = categoryName.toLowerCase();
          if (catLower.contains('premium')) color = Colors.deepPurple;
          else if (catLower.contains('standard')) color = Colors.teal;
          else if (catLower.contains('basic')) color = Colors.orange;
        }

        // 🎯 RULE: End date notification
        bool isExpiringSoon = daysLeft <= 7;

        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, size: 16, color: color),
              const SizedBox(width: 8),
              // Expanded to avoid overflow with long Type names
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isExpiringSoon)
                Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_filled, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text("Expiring in $daysLeft days", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                )
              else
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Text("Active • $daysLeft days left", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}