import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/client_profile_edit_screen.dart';
import 'package:nutricare_client_management/screens/dash/client-personal_info_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/admin/client_meeting_schedule_tab.dart';
import 'package:nutricare_client_management/scheduler/client_content_scheduler_tab.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';


class ClientDashboardScreen extends StatefulWidget {
  final ClientModel client;

  const ClientDashboardScreen({super.key, required this.client});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> with SingleTickerProviderStateMixin {
  late ClientModel _currentClient;
  final ClientService _clientService = ClientService();
  late TabController _tabController;
  bool _isLoading = false;


  void _openPersonalInfoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClientPersonalInfoSheet(
        client: _currentClient,
        onSave: (updated) => setState(() => _currentClient = updated),
      ),
    );
  }

  void _openClientTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClientTypeSheet(
        client: _currentClient,
        onSave: (updated) => setState(() => _currentClient = updated),
      ),
    );
  }

  void _openSecuritySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClientSecuritySheet(
        client: _currentClient,
        onSave: (updated) => setState(() => _currentClient = updated),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshClientData() async {
    setState(() => _isLoading = true);
    try {
      final updatedClient = await _clientService.getClientById(_currentClient.id);
      if (mounted) setState(() => _currentClient = updatedClient);
    } catch (e) {
      // Handle error silently or toast
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  void _navigateToEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientProfileEditScreen(client: _currentClient),
      ),
    );
    _refreshClientData();
  }

  Future<void> _handleSoftDelete() async {
    final check = await _clientService.softDeleteClient(clientId: _currentClient.id, isCheckOnly: true);

    if (!check['canDelete']) {
      _showDialog("Cannot Delete", check['message'], isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Soft delete this client? They will be moved to the archive."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _clientService.softDeleteClient(clientId: _currentClient.id, isCheckOnly: false);
      if (mounted) Navigator.pop(context); // Exit dashboard
    }
  }

  void _showDialog(String title, String msg, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: TextStyle(color: isError ? Colors.red : Colors.black)),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Premium Light Background
      body: Stack(
        children: [
          // 1. Ambient Glow
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), blurRadius: 100, spreadRadius: 40)],
              ),
            ),
          ),

          Column(
            children: [
              // 2. Custom Glass Header
              _buildCustomHeader(),

              // 3. Floating Tab Bar
              _buildPremiumTabBar(),

              // 4. Tab Views
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildProfileTab(),
                    ClientMeetingScheduleTab(client: _currentClient),
                    ClientContentSchedulerTab(client: _currentClient),
                    _buildActionsGrid(),
                    VitalsHistoryPage(clientId: _currentClient.id, clientName: _currentClient.name),
                    ClientPackageListScreen(client: _currentClient),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    // Status Logic
    Color statusColor = Colors.grey;
    String statusText = "Pending";
    IconData statusIcon = Icons.timelapse;

    switch (_currentClient.clientType) {
      case 'active': statusColor = Colors.green; statusText = "Active Member"; statusIcon = Icons.verified; break;
      case 'one_time': statusColor = Colors.orange; statusText = "One-Time"; statusIcon = Icons.flash_on; break;
      case 'expired': statusColor = Colors.red; statusText = "Expired"; statusIcon = Icons.history; break;
    }

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 20, right: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                      child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                    ),
                  ),
                  Row(
                    children: [
                      // Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 6),
                            Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Edit Button
                      InkWell(
                        onTap: () => _navigateToEdit(),
                        child: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1), radius: 18, child: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Header Avatar (Small - shows initial if no photo)
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: _currentClient.photoUrl != null ? NetworkImage(_currentClient.photoUrl!) : null,
                    child: _currentClient.photoUrl == null
                        ? Text(_currentClient.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentClient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        const SizedBox(height: 4),
                        Text("ID: ${_currentClient.patientId}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.white.withOpacity(0.5),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: "Profile"),
          Tab(text: "Schedule"),
          Tab(text: "Content"),
          Tab(text: "Actions"),
          Tab(text: "Vitals"),
          Tab(text: "Billing"),
        ],
      ),
    );
  }

  // --- TAB 1: PROFILE (Revamped) ---
  Widget _buildProfileTab() {
    final ageStr = _currentClient.age != null && _currentClient.age! > 0 ? "${_currentClient.age} Yrs" : "Age N/A";
    final dobStr = _currentClient.dob != null ? DateFormat('dd MMM yyyy').format(_currentClient.dob) : "Not Set";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Identity Card
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
                child: Column(
                  children: [
                    CircleAvatar(radius: 50, backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1), backgroundImage: _currentClient.photoUrl != null ? NetworkImage(_currentClient.photoUrl!) : null, child: _currentClient.photoUrl == null ? Text(_currentClient.name[0], style: const TextStyle(fontSize: 40)) : null),
                    const SizedBox(height: 16),
                    Text(_currentClient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text("PID: ${_currentClient.patientId ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Positioned(top: 10, right: 10, child: IconButton(icon:  Icon(Icons.edit, color: Theme.of(context).colorScheme.primary), onPressed: _openPersonalInfoSheet)),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Personal & Contact (Merged for simplicity in edit, split in view if desired)
          _buildInfoCard(
            title: "Personal & Contact",
            icon: Icons.person,
            color: Colors.purple,
            children: [
              _buildInfoRow(Icons.male, "Gender", _currentClient.gender),
              _buildInfoRow(Icons.cake, "DOB", _currentClient.dob != null ? DateFormat('dd MMM yyyy').format(_currentClient.dob) : "N/A"),
              _buildInfoRow(Icons.phone, "Mobile", _currentClient.mobile),
              _buildInfoRow(FontAwesomeIcons.whatsapp, "WhatsApp", _currentClient.whatsappNumber ?? "N/A"),
              _buildInfoRow(Icons.email, "Email", _currentClient.email),
              _buildInfoRow(Icons.location_on, "Address", _currentClient.address ?? "N/A", maxLines: 2),
            ],
            action: IconButton(icon: const Icon(Icons.edit, color: Colors.purple), onPressed: _openPersonalInfoSheet),
          ),
          const SizedBox(height: 20),

          // 3. Client Status
          _buildInfoCard(
            title: "Account Status",
            icon: Icons.verified_user,
            color: Colors.blue,
            children: [
              _buildInfoRow(Icons.category, "Client Type", _currentClient.clientType.toUpperCase()),
            ],
            action: TextButton(onPressed: _openClientTypeSheet, child: const Text("Change")),
          ),
          const SizedBox(height: 20),

          // 4. Security
          _buildInfoCard(
            title: "Security",
            icon: Icons.lock,
            color: Colors.orange,
            children: [
              _buildInfoRow(Icons.vpn_key, "Login ID", _currentClient.loginId),
              _buildInfoRow(Icons.shield, "Access", _currentClient.status == 'Active' ? "Granted" : "Blocked", isSecure: false),
            ],
            action: IconButton(icon: const Icon(Icons.settings, color: Colors.orange), onPressed: _openSecuritySheet),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );

  }

  // --- TAB 4: ACTIONS (Grid Layout) ---
  Widget _buildActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Square-ish cards
      children: [
        _buildActionCard(
          "Vitals", "Log Measurements", Icons.monitor_heart, Colors.red,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsHistoryPage(clientId: _currentClient.id, clientName: _currentClient.name))),
        ),
        _buildActionCard(
          "New Package", "Assign Service", Icons.card_giftcard, Colors.deepPurple,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => PackageAssignmentPage(clientId: _currentClient.id, clientName: _currentClient.name, onPackageAssignment: _refreshClientData))).then((_) => _refreshClientData()),
        ),
        _buildActionCard(
          "Diet Template", "Assign Master", Icons.restaurant_menu, Theme.of(context).colorScheme.primary,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterPlanSelectionPage(client: _currentClient, onMasterPlanAssigned: _refreshClientData))),
        ),
        _buildActionCard(
          "Custom Plan", "Edit Details", Icons.edit_note, Colors.orange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => AssignedDietPlanListScreen(client: _currentClient, onMealPlanSaved: _refreshClientData))),
        ),
      ],
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Color color, required List<Widget> children, Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87))]),
              if (action != null) action,
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isSecure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 24, child: Icon(icon, size: 16, color: Colors.grey.shade400)),
          const SizedBox(width: 12),
          Text("$label: ", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: maxLines, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}