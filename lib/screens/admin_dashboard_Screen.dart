import 'package:flutter/material.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/master_client_screen.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';

import '../../models/client_model.dart';
import '../../services/client_service.dart';
import 'master_Setup_page.dart';
// Import your module entry points

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<ClientModel>> _clientsFuture;
  final ClientService clientService = ClientService();

  @override
  void initState() {
    super.initState();
    _clientsFuture = _loadClients();
  }

  Future<List<ClientModel>> _loadClients() {

    return clientService.getAllClients();
  }

  /// Navigates to a new screen and refreshes the current screen's data upon return.
  void _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));

    // Refresh the client list when returning from the Entry/Edit page
    setState(() {
      _clientsFuture = _loadClients();
    });
  }

  // --- Widget Builders ---

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.blueGrey,
  }) {
    return Card(
      elevation: 4,
      color: Colors.blue.shade900,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blueAccent.shade100),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent.shade100,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Divider(),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildModuleCard(
                  title: 'Client List',
                  icon: Icons.groups,
                  color: Colors.amber,
                  onTap: () {
                    _navigateAndRefresh(const MasterClientScreen());
                  },
                ),
                _buildModuleCard(
                  title: 'Settings',
                  icon: Icons.settings,
                  color: Colors.deepPurple,
                  onTap: () => _navigateAndRefresh(const MasterSetupPage()), // 🎯 NEW LINK
                ),
                _buildModuleCard(
                  title: 'Account',
                  icon: Icons.account_balance,
                  color: Colors.deepOrangeAccent,
                  onTap: () => _navigateAndRefresh(const ClientLedgerOverviewScreen()) // 🎯 NEW LINK
                ),
                _buildModuleCard(
                    title: 'Settings',
                    icon: Icons.account_balance,
                    color: Colors.deepOrangeAccent,
                    onTap: () => _navigateAndRefresh(const ClientLedgerOverviewScreen()) // 🎯 NEW LINK
                ),
              ],
            ),

            const SizedBox(height: 30),


          ],
        ),
      ),
    );
  }
}