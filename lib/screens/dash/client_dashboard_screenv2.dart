import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/client_meeting_schedule_tab.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_list.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart'
    hide ClientModel;
import 'package:nutricare_client_management/scheduler/client_content_scheduler_tab.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/package_status_card.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modules/client/model/client_model.dart';
import '../../modules/package/model/package_assignment_model.dart';
import '../client_form_screen.dart' hide ClientModel, ClientService;
import '../../modules/client/services/client_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';


// 🎯 WIDGET: SlideToAct for secure deletion
class SlideToAct extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onSlide;
  final bool isDisabled;

  const SlideToAct({
    super.key,
    required this.label,
    required this.icon,
    this.backgroundColor = Colors.red,
    required this.onSlide,
    this.isDisabled = false,
  });

  @override
  State<SlideToAct> createState() => _SlideToActState();
}

class _SlideToActState extends State<SlideToAct> {
  double _dragValue = 0.0;
  final double _maxDrag = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.isDisabled) {
      return Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragValue += details.primaryDelta! / (context.size?.width ?? 300);
          _dragValue = _dragValue.clamp(0.0, _maxDrag);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragValue >= 0.95) {
          widget.onSlide();
        }
        setState(() {
          _dragValue = 0.0;
        });
      },
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: widget.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Sliding Button
            FractionallySizedBox(
              widthFactor: 0.2 + 0.8 * _dragValue,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Transform.translate(
                      offset: Offset((1 - _dragValue) * -30, 0),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: widget.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MAIN DASHBOARD SCREEN ---

class ClientDashboardScreen extends StatefulWidget {
  final ClientModel client;

  const ClientDashboardScreen({super.key, required this.client});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late ClientModel _currentClient;
  final ClientService _clientService = ClientService();
  late TabController _tabController;

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
    try {
      final updatedClient = await _clientService.getClientById(
        _currentClient.id,
      );
      if (mounted) {
        setState(() {
          _currentClient = updatedClient;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reload client data: $e')),
        );
    }
  }

  Future<void> _handleDeleteRequest() async {
    final hasActivePackage = _currentClient.packageAssignments.values.any(
      (p) => p.isActive,
    );

    if (mounted) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('CONFIRM PROFILE DELETION'),
                content: Text(
                  'Are you absolutely sure you want to permanently delete ${_currentClient.name}? This is irreversible.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('DELETE NOW'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (confirmed) {
        await _attemptClientSoftDelete(context);
      }
    }
  }

  Widget _buildProfileRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Widget? actionWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
          if (actionWidget != null) actionWidget,
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required VoidCallback editAction,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: editAction,
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _attemptClientSoftDelete(BuildContext context) async {
    final ClientService clientService =
        ClientService(); // Use your existing instance

    // 1. Check if deletion is allowed
    final checkResult = await clientService.softDeleteClient(
      clientId: widget.client.id,
      isCheckOnly: true,
    );

    if (!checkResult['canDelete']) {
      // If check fails (e.g., active packages exist), show the warning dialog
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Deletion Blocked',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(checkResult['message']),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Deletion is allowed (Check passed), show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Soft Delete'),
        content: Text(
          'Are you sure you want to soft delete ${widget.client.name}? The client will be marked Inactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Soft Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 3. Perform the actual soft delete (isCheckOnly: false)
      final deleteResult = await clientService.softDeleteClient(
        clientId: widget.client.id,
        isCheckOnly: false, // Perform the action
      );

      // Show success/failure snackbar and navigate back
      if (deleteResult['canDelete']) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(deleteResult['message'])));
        // Navigate away, as the client is now inactive
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteResult['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileTab(ClientModel client) {
    // Function to navigate and refresh, accepting a section to focus on
    void navigateToEdit({
      ClientFormSection focusSection = ClientFormSection.personal,
    }) async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClientFormScreen(
            clientToEdit: client,
            // 🎯 PASSING A NON-NULLABLE VALUE TO A NULLABLE PARAMETER IS VALID
            initialFocusSection: focusSection,
          ),
        ),
      );
      _refreshClientData();
    }

    final hasActivePackage = client.packageAssignments.values.any(
      (p) => p.isActive,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Personal & Contact Information
          _buildSectionCard(
            context,
            title: 'Personal & Contact',
            editAction: () =>
                navigateToEdit(focusSection: ClientFormSection.personal),
            children: [
              _buildProfileRow(context, Icons.person, 'Name', client.name),
              _buildProfileRow(
                context,
                Icons.phone,
                'Mobile (P)',
                client.mobile,
              ),
              if (client.altMobile != null && client.altMobile!.isNotEmpty)
                _buildProfileRow(
                  context,
                  Icons.phone_android,
                  'Mobile (A)',
                  client.altMobile!,
                ),
              _buildProfileRow(context, Icons.email, 'Email', client.email),
              // _buildProfileRow(context, Icons.calendar_today, 'DOB', DateFormat('yyyy-MM-dd').format(client.dob!)),
              _buildProfileRow(context, Icons.person, 'Gender', client.gender),
              if (client.address != null && client.address!.isNotEmpty)
                _buildProfileRow(
                  context,
                  Icons.home,
                  'Address',
                  client.address!,
                ),
            ],
          ),

          // 2. Security & Login
          _buildSectionCard(
            context,
            title: 'Security & Login',
            editAction: () =>
                navigateToEdit(focusSection: ClientFormSection.password),
            children: [
              _buildProfileRow(
                context,
                Icons.vpn_key,
                'Login ID',
                client.loginId,
              ),
              _buildProfileRow(
                context,
                client.hasPasswordSet ? Icons.lock_open : Icons.lock,
                'Password',
                client.hasPasswordSet ? 'Set' : 'Not Set',
                actionWidget: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () =>
                      navigateToEdit(focusSection: ClientFormSection.password),
                ),
              ),
            ],
          ),

          // 3. Agreement Status
          _buildSectionCard(
            context,
            title: 'Client Agreement',
            editAction: () =>
                navigateToEdit(focusSection: ClientFormSection.agreement),
            children: [
              _buildProfileRow(
                context,
                Icons.description,
                'Status',
                client.agreementUrl != null ? 'Uploaded' : 'Missing',
                actionWidget: client.agreementUrl != null
                    ? Row(
                        children: [
                          // Download/View Button
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.green,
                            ),
                            onPressed: () async {
                              if (await canLaunchUrl(
                                Uri.parse(client.agreementUrl!),
                              )) {
                                launchUrl(Uri.parse(client.agreementUrl!));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Could not open agreement URL.',
                                    ),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Download/View Agreement',
                          ),
                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => navigateToEdit(
                              focusSection: ClientFormSection.agreement,
                            ),
                            tooltip: 'Upload New Agreement',
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.upload, color: Colors.blue),
                        onPressed: () => navigateToEdit(
                          focusSection: ClientFormSection.agreement,
                        ),
                        tooltip: 'Upload Agreement',
                      ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // DANGER ZONE: Slide-to-Delete Section
          Card(
            color: Colors.red.shade50,
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛑 DANGER ZONE: Profile Deletion',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(color: Colors.red),

                  const Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      'Deletion is irreversible. Client profiles cannot be deleted if they have a booked package.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),

                  // Slide-to-Act Widget
                  SlideToAct(
                    label: hasActivePackage
                        ? 'Cannot Delete (Active Packages)'
                        : 'SLIDE TO DELETE',
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    backgroundColor: Colors.red.shade600,
                    isDisabled: hasActivePackage,
                    onSlide: _handleDeleteRequest,
                  ),

                  if (hasActivePackage)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Deletion is blocked because the client has ${client.packageAssignments.length} active package${client.packageAssignments.length > 1 ? 's' : ''}.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text('${_currentClient.name} profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Overridden by labelColor below
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.normal,
            color: Colors.white70, // Overridden by unselectedLabelColor below
          ),
          tabs: const [
            Tab(text: 'Profile', ),
            Tab(text: 'Schedule'),
            Tab(text: 'Content Schedule'),
            Tab(text: 'Actions'),
            Tab(text: 'Vitals'),
            Tab(text: 'Package/Payment'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(_currentClient),
            ClientMeetingScheduleTab(
              client: _currentClient,

            ),
           Center(child:  ClientContentSchedulerTab(client: _currentClient)),
            _buildActionsTab(),
            Center(child: VitalsHistoryPage(clientId: _currentClient.id, clientName: _currentClient.name)),
            Center(child: _buildPackageStatusSection(_currentClient.id)),


          ],
        ),
      ),
    );
  }

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
                  clientName: _currentClient.name, onPackageAssignment: () {  },
                ),
              ),
            ).then((_) => setState(() {}));
          },

          onEditTap: (assignment) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PaymentLedgerScreen(
                  assignment: assignment,
                  clientName: _currentClient.name,
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


  Widget _buildDietPlanSection(ClientModel client) {

    return  MasterPlanSelectionPage(
      client: client, onMasterPlanAssigned: () {  },
    );



  }


  Widget _buildActionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
              leading: const Icon(Icons.monitor_heart, color: Colors.red),
              title: const Text('Capture/View Vitals'),
              subtitle: const Text('Record body measurements, blood pressure, etc.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _navigateToVitalsHistory
          ),
        ),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: const Icon(Icons.card_membership, color: Colors.purple),
            title: const Text('Assign/Book Package'),
            subtitle: const Text('Assign a new subscription or service package.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToAssignPackage,
          ),
        ),
        const Divider(),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: const Icon(Icons.restaurant_menu, color: Colors.indigo),
            title: const Text('Assign Master Diet Plan'),
            subtitle: const Text('Select a template to assign to the client.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToAssignDietPlan,
          ),
        ),
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16.0),
          child: ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.orange),
            title: const Text('Create/Edit Final Diet Plan'),
            subtitle: const Text('Customize the currently assigned plan (The Final Plan).'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToFinalPlanCreation,
          ),
        ),
        const Divider(),

      ],
    );
  }
  void _navigateToAssignDietPlan() {
    if (_currentClient == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MasterPlanSelectionPage(client: _currentClient, onMasterPlanAssigned: () {  },),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToFinalPlanCreation() {
    if (_currentClient == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssignedDietPlanListScreen(client: _currentClient, onMealPlanSaved: () {  },),
      ),
    ).then((_) => setState(() {}));
  }
  void _navigateToVitalsHistory() {
    if (_currentClient == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => VitalsHistoryPage(clientId: _currentClient.id, clientName: _currentClient.name)
      ),
    );
  }
  void _navigateToAssignPackage() {
    if (_currentClient == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageAssignmentPage(clientId: _currentClient.id, clientName: _currentClient.name, onPackageAssignment: () {  },),
      ),
    ).then((_) => setState(() {}));
  }

}
