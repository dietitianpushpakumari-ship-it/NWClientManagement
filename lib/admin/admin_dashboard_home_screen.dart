import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/admin/client_consultation_checlist_screen.dart';
import 'package:nutricare_client_management/admin/pending_client_list_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/client_form_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';

class AdminDashboardHomeScreen extends StatelessWidget {
  const AdminDashboardHomeScreen({super.key});


  @override
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Quick actions for your client management.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 25),

          // --- 1st Section: Core Actions ---
          _buildCoreActionsSection(context),
          const SizedBox(height: 25),

          // --- 2nd Section: Snapshot/KPIs (Placeholder) ---
          Text(
            'Current Snapshot',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildSnapshotSection(context),
          const SizedBox(height: 25),

          // --- 3rd Section: Pending Tasks (Placeholder) ---
          Text(
            'Alerts & Pending Tasks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPendingTasksSection(context),
        ],
      ),
    );
  }

  // ... (Rest of the class methods remain the same) ...

  // --- Widget for Core Actions (Section 1) ---
  Widget _buildCoreActionsSection(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildActionButton(
          context,
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
          title: 'Client List',
          icon: Icons.people,
          color: Colors.indigo.shade700,
          onTap: () {
            // Navigate to the list of existing clients
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const PendingClientListScreen(),
            ));
          },
        ),
        _buildActionButton(
          context,
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
  Widget _buildActionButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: color.withOpacity(0.4),
      //  color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
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