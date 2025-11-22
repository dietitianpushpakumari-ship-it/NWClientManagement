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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. Welcome Header ---
            FutureBuilder<AdminProfileModel?>(
              future: AdminProfileService().fetchAdminProfile(),
              builder: (context, snapshot) {
                String userName = 'Admin';
                if (snapshot.hasData && snapshot.data != null) {
                  userName = snapshot.data!.firstName;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your daily practice overview.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // --- 2. Business Snapshot (Horizontal Stats) ---
            Text(
              'Business Snapshot',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110, // Fixed height for stat cards
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none, // Allow shadow to show
                children: [
                  _buildStatCard(context, 'Active Clients', '42', Icons.people_alt, Colors.blue),
                  _buildStatCard(context, 'Revenue (Aug)', '₹1.2L', Icons.currency_rupee, Colors.green),
                  _buildStatCard(context, 'Pending Plans', '3', Icons.pending_actions, Colors.orange),
                  _buildStatCard(context, 'New Leads', '5', Icons.person_add_alt, Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. Core Quick Actions (Grid) ---
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCoreActionsGrid(context, screenWidth),

            const SizedBox(height: 30),

            // --- 4. Critical Alerts & Tasks ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Tasks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            _buildPriorityTaskTile(
              context,
              title: 'Diet Plan Expiring: Sarah Jones',
              subtitle: 'Plan expires tomorrow. Renewal needed.',
              isUrgent: true,
              onTap: () {},
            ),
            _buildPriorityTaskTile(
              context,
              title: 'New Registration: Mike Ross',
              subtitle: 'Pending profile approval.',
              isUrgent: false,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const PendingClientListScreen(),
                ));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Widget: Stat Card ---
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              // Optional: Trend indicator
              // Icon(Icons.arrow_upward, size: 14, color: Colors.green),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget: Action Grid ---
  Widget _buildCoreActionsGrid(BuildContext context, double screenWidth) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1, // Slightly rectangular
      children: [
        _buildActionCard(
          context,
          title: 'Add Client',
          icon: Icons.person_add_rounded,
          color: Colors.indigo,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PendingClientListScreen())),
        ),
        _buildActionCard(
          context,
          title: 'Content',
          icon: Icons.article_rounded,
          color: Colors.teal,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContentLibraryScreen())),
        ),
        _buildActionCard(
          context,
          title: 'Ledger',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.blueGrey,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClientLedgerOverviewScreen())),
        ),
        _buildActionCard(
          context,
          title: 'Master Setup',
          icon: Icons.settings_suggest_rounded,
          color: Colors.deepPurple,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MasterSetupPage())),
        ),
        _buildActionCard(
          context,
          title: 'Analytics',
          icon: Icons.bar_chart_rounded,
          color: Colors.pink,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics coming soon!')));
          },
        ),
        _buildActionCard(
          context,
          title: 'Reports',
          icon: Icons.pie_chart_rounded,
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reports coming soon!')));
          },
        ),
      ],
    );
  }

  // --- Widget: Single Action Button ---
  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withOpacity(0.08), // Very subtle background
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget: Priority Task Tile ---
  Widget _buildPriorityTaskTile(BuildContext context, {required String title, required String subtitle, required bool isUrgent, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: isUrgent ? Colors.red.shade50 : Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isUrgent ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isUrgent ? Icons.access_time_filled : Icons.verified_user,
            color: isUrgent ? Colors.red : Colors.amber[800],
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}