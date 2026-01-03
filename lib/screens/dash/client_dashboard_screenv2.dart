import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/client_consultataion_history_tab.dart';
import 'package:nutricare_client_management/admin/client_log_review_tab.dart';
import 'package:nutricare_client_management/admin/dashboard/client_profile_tab.dart';
import 'package:nutricare_client_management/admin/labvital/client_profile_edit_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/labvital/vitals_comprasion_screen.dart';
import 'package:nutricare_client_management/admin/smart_consultation_history_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/admin/client_meeting_schedule_tab.dart';
import 'package:nutricare_client_management/admin/client_package_list_screen.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';

import 'package:nutricare_client_management/admin/consultation_session_service.dart';
import 'package:nutricare_client_management/admin/consultation_session_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/modules/package/service/package_payment_service.dart';
import 'package:nutricare_client_management/admin/consultation_gateway_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  final ClientModel client;

  const ClientDashboardScreen({super.key, required this.client});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> with SingleTickerProviderStateMixin {
  late ClientModel _currentClient;
  late TabController _tabController;
  bool _isLoading = false;

  ConsultationSessionModel? _activeSession;
  ConsultationSessionModel? _lastSession;
  PackageAssignmentModel? _activePackage;
  double _pendingDues = 0.0;

  @override
  void initState() {
    super.initState();
    _currentClient = widget.client;
    // 4 Tabs: Profile, Schedule, Actions, Consultations
    _tabController = TabController(length: 5, vsync: this);
    _refreshClientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshClientData() async {
    setState(() => _isLoading = true);
    try {
      final clientService = ref.read(clientServiceProvider);
      final sessionService = ref.read(consultationServiceProvider);
      final paymentService = ref.read(packagePaymentServiceProvider);
      final firestore = ref.read(firestoreProvider);

      final updatedClient = await clientService.getClientById(_currentClient.id);
      final active = await sessionService.getActiveSession(_currentClient.id);
      final last = await sessionService.getLatestSession(_currentClient.id);

      final packageQuery = await firestore
          .collection('package_assignments')
          .where('clientId', isEqualTo: _currentClient.id)
          .where('isActive', isEqualTo: true)
          .orderBy('expiryDate', descending: true)
          .limit(1)
          .get();

      PackageAssignmentModel? pkg;
      if (packageQuery.docs.isNotEmpty) {
        pkg = PackageAssignmentModel.fromFirestore(packageQuery.docs.first);
      }

      final dues = await paymentService.getClientPendingAmount(_currentClient.id);

      if (mounted) {
        setState(() {
          _currentClient = updatedClient;
          _activeSession = active;
          _lastSession = last;
          _activePackage = pkg;
          _pendingDues = dues;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientProfileEditScreen(client: _currentClient),
      ),
    );
    _refreshClientData();
  }

  // ===========================================================================
  // 🎯 ACTIONS
  // ===========================================================================

  void _handleResumeSession() {
    if (_activeSession == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientConsultationChecklistScreen(
          client: _currentClient,
          activePackage: _activePackage,
          forceNew: false,
          isFollowup: _activeSession!.consultationType == 'Followup',
        ),
      ),
    ).then((_) => _refreshClientData());
  }

  void _openConsultationGateway() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationGatewayScreen(client: _currentClient),
      ),
    ).then((_) => _refreshClientData());
  }

  void _openSmartHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SmartConsultationHistoryScreen(
          client: _currentClient,
          currentSessionId: null,
        ),
      ),
    );
  }

  void _openPackageHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientPackageListScreen(
          client: _currentClient,
          sessionId: _activeSession?.id,
          isReadOnly: false,
        ),
      ),
    ).then((_) => _refreshClientData());
  }

  void _openDietPlanList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignedDietPlanListScreen(
          clientId: _currentClient.id,
          clientName: _currentClient.name,
          client: _currentClient,
          isReadOnly: false,
        ),
      ),
    );
  }

  // ===========================================================================
  // 🎯 UI BUILDERS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
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
              _buildCustomHeader(),
              _buildPremiumTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ClientProfileTab(client: _currentClient, onRefresh: _refreshClientData),
                    ClientMeetingScheduleTab(client: _currentClient),
                    ClientLogReviewTab(
                      clientId: _currentClient.id, clientName: _currentClient.name,
                    ),
                    _buildActionsGrid(),
                    ClientConsultationHistoryTab(client: _currentClient),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid() {
    List<Widget> actionCards = [];

    // 1. Resume Active Session (Priority)
    if (_activeSession != null) {
      actionCards.add(_buildActionCard("Resume Session", "Continue active visit", Icons.play_circle_fill, Colors.green, _handleResumeSession));
    }

    // 2. Start Consultation
    actionCards.add(_buildActionCard(
        "Start Consultation",
        "New or Follow-up",
        Icons.medical_services_outlined,
        Colors.teal,
        _openConsultationGateway
    ));

    // 🎯 3. MERGED CARD: Packages + Pay Pending
    String pkgTitle = "Packages";
    String pkgSubtitle = "History & Payments";
    IconData pkgIcon = Icons.card_membership;
    Color pkgColor = Colors.deepPurple;

    // If Dues Exist, override look to be an Alert
    if (_pendingDues > 0) {
      pkgTitle = "Pay Pending";
      pkgSubtitle = "Due: ₹${_pendingDues.toInt()}";
      pkgIcon = Icons.warning_amber_rounded;
      pkgColor = Colors.red;
    }

    actionCards.add(_buildActionCard(
        pkgTitle,
        pkgSubtitle,
        pkgIcon,
        pkgColor,
        _openPackageHistory
    ));

    // 4. Diet Plans
    actionCards.add(_buildActionCard(
        "Diet Plans",
        "Quick Edits / View",
        Icons.restaurant_menu,
        Colors.orange,
        _openDietPlanList
    ));

    // 5. Smart History
    actionCards.add(_buildActionCard("Smart History", "Analyze Trends", Icons.history_edu, Colors.blueAccent, _openSmartHistory));

    // 6. Vitals
    actionCards.add(_buildActionCard("Vitals Progress", "Compare Labs", Icons.show_chart, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => VitalsComparisonScreen(clientId: _currentClient.id, clientName: _currentClient.name)))));

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: actionCards,
    );
  }

  // ... [Header & Helper Widgets unchanged] ...

  Widget _buildCustomHeader() {
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
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87))),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(statusIcon, size: 12, color: statusColor), const SizedBox(width: 6), Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor))])),
                    const SizedBox(width: 10),
                    InkWell(onTap: _navigateToEdit, child: CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1), radius: 18, child: Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.primary))),
                  ])
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                CircleAvatar(radius: 30, backgroundColor: Theme.of(context).colorScheme.primary, backgroundImage: _currentClient.photoUrl != null ? NetworkImage(_currentClient.photoUrl!) : null, child: _currentClient.photoUrl == null ? Text(_currentClient.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)) : null),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_currentClient.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))), const SizedBox(height: 4), Text("ID: ${_currentClient.patientId}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600, letterSpacing: 0.5))]))
              ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    return Container(
      height: 60, width: double.infinity, color: Colors.white.withOpacity(0.5),
      child: TabBar(
        controller: _tabController, isScrollable: true, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        indicator: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]),
        labelColor: Colors.white, unselectedLabelColor: Colors.grey.shade600, labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [Tab(text: "Profile"), Tab(text: "Schedule"), Tab(text: "Logs"), Tab(text: "Actions"), Tab(text: "Consultations")],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}