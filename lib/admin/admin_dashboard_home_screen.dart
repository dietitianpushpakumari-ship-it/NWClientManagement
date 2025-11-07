import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/admin/pending_client_list_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/scheduler/content_library_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';

class AdminDashboardHomeScreen extends StatelessWidget {
  const AdminDashboardHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
    // 🎯 1. Capture screen width for dynamic sizing
    final double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // --- Welcome/Greeting Section (Now uses FutureBuilder) ---
          FutureBuilder<AdminProfileModel?>(
            future: AdminProfileService().fetchAdminProfile(),
            builder: (context, snapshot) {
              String userName = 'Admin'; // Default name

              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                final profile = snapshot.data!;
                userName = '${profile.firstName} ${profile.lastName}';
              } else if (snapshot.hasError) {
                // Optionally log the error or show a specific message
                userName = 'Admin (Error)';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName!', // 🎯 DISPLAY FETCHED NAME
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Quick actions for your client management.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 25),

          // --- 1st Section: Core Actions ---
          _buildCoreActionsSection(context, screenWidth), // 🎯 Pass screenWidth
          const SizedBox(height: 25),

          // --- 2nd Section: Snapshot/KPIs (Placeholder) ---
          Text(
            'Current Snapshot',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSnapshotSection(context),
          const SizedBox(height: 25),

          // --- 3rd Section: Pending Tasks (Placeholder) ---
          Text(
            'Alerts & Pending Tasks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPendingTasksSection(context),
        ],
      ),
    );
  }

  // --- Widget for Core Actions (Section 1) ---
  // 🎯 Updated signature to receive screenWidth
  Widget _buildCoreActionsSection(BuildContext context, double screenWidth) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 8,
      children: [
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'New Client',
          icon: Icons.person_add,
          color: Colors.green.shade700,
          onTap: () {
            // Navigator to a screen that starts a new client form (e.g., ClientConsultationChecklistScreen)
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const PendingClientListScreen(),
            ));
          },
        ),
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'Library',
          icon: Icons.people,
          color: Colors.indigo.shade700,
          onTap: () {
            // Navigate to the list of existing clients
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const ContentLibraryScreen(),
            ));
          },
        ),
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'Ledger',
          icon: Icons.account_balance_wallet,
          color: Colors.teal.shade700,
          onTap: () {
            // Navigate to the client ledger overview
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const ClientLedgerOverviewScreen(),
            ));
          },
        ),
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'Master Setup',
          icon: Icons.settings,
          color: Colors.blueGrey.shade700,
          onTap: () {
            // Navigate to master data setup/configuration
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const MasterSetupPage(),
            ));
          },
        ),
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'Analytics',
          icon: Icons.bar_chart,
          color: Colors.purple.shade700,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Analytics screen coming soon!')),
            );
          },
        ),
        _buildActionButton(
          context,
          screenWidth, // 🎯 Pass screenWidth to the button builder
          title: 'Reports',
          icon: Icons.document_scanner,
          color: Colors.orange.shade700,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reports generation coming soon!')),
            );
          },
        ),
      ],
    );
  }

  // --- Reusable Action Button Widget ---
  // 🎯 Updated signature to receive screenWidth
  Widget _buildActionButton(
      BuildContext context,
      double screenWidth,
      {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    // Calculate dynamic icon size (e.g., 8% of screen width)
    final double dynamicIconSize = screenWidth * 0.08;
    // Calculate dynamic vertical spacing (e.g., 2.5% of screen width)
    final double dynamicSpacing = screenWidth * 0.025;

    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.4),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.015), // Dynamic padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 🎯 Use dynamic size for icon
              Icon(icon, size: dynamicIconSize, color: color),
              // 🎯 Use dynamic height for vertical space
              SizedBox(height: dynamicSpacing),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  // Font size can remain fixed for readability, but can also be made dynamic if needed.
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget for Snapshot (Section 2 Placeholder) ---
  Widget _buildSnapshotSection(BuildContext context) {
    return const Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.analytics, color: Colors.blue),
        title: Text('Total Active Clients: 45'),
        subtitle: Text('Revenue this month: \$5,200'),
      ),
    );
  }

  // --- Widget for Pending Tasks (Section 3 Placeholder) ---
  Widget _buildPendingTasksSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.red),
          title: const Text('2 Client Plans Expiring Tomorrow'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {/* Navigate to planner alerts */},
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.notifications_active, color: Colors.amber),
          title: const Text('New client registration pending approval'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {/* Navigate to client approval list */},
        ),
      ],
    );
  }
}