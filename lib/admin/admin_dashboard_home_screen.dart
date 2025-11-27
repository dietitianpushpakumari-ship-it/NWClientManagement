import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/admin_analytics_screen.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Clean Premium Background
      body: Stack(
        children: [
          // 🎨 1. SUBTLE AMBIENT GLOW (Top Right)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // 📜 2. SCROLLABLE CONTENT
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // --- A. CUSTOM HEADER (Replaces AppBar) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: FutureBuilder<AdminProfileModel?>(
                      future: AdminProfileService().fetchAdminProfile(),
                      builder: (context, snapshot) {
                        String name = "Doctor";
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data != null) {
                          name = snapshot.data!.firstName;
                          photoUrl = snapshot.data!.photoUrl;
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dashboard",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Hello, $name",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                              ],
                            ),
                            // Profile Avatar
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.indigo.withOpacity(0.2),
                                    width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.indigo.shade50,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? Text(name[0],
                                    style: TextStyle(
                                        color: Colors.indigo.shade800,
                                        fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // --- B. BUSINESS SNAPSHOT (Horizontal Rail) ---
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150, // Height for the cards
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      clipBehavior: Clip.none,
                      children: [
                        _buildHeroStatCard(
                          "Revenue",
                          "₹1.2L",
                          "Aug 2024",
                          Icons.currency_rupee_rounded,
                          Colors.green,
                          isHero: true,
                        ),
                        _buildHeroStatCard(
                          "Active Clients",
                          "42",
                          "+5 New",
                          Icons.people_alt_rounded,
                          Colors.blue,
                        ),
                        _buildHeroStatCard(
                          "Pending Plans",
                          "3",
                          "Action Req.",
                          Icons.hourglass_top_rounded,
                          Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),

                // --- C. QUICK ACTIONS (Bento Grid) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.grid_view_rounded,
                            size: 20, color: Colors.indigo),
                        const SizedBox(width: 8),
                        const Text(
                          "Management Console",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                  ),
                ),

                // 🎯 RESTORED & FIXED: _buildCoreActionsGrid (Now returns a Sliver)
                _buildCoreActionsGrid(context),

                // --- D. PRIORITY ALERTS (Feed) ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Priority Alerts",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            "2 NEW",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAlertCard(
                        "Plan Expiring: Sarah Jones",
                        "Diet plan expires tomorrow. Review needed.",
                        "2h ago",
                        true,
                            () {},
                      ),
                      _buildAlertCard(
                        "New Registration: Mike Ross",
                        "Pending profile approval & intake.",
                        "5h ago",
                        false,
                            () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const PendingClientListScreen())),
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 🎯 RESTORED METHOD: Returns a SliverGrid ---
  Widget _buildCoreActionsGrid(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid.count(
        crossAxisCount: 2, // 2 Column Grid
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3, // Rectangular Cards
        children: [
          _buildBentoAction(
            context,
            "Onboard Client",
            "Register New",
            Icons.person_add_rounded,
            Colors.indigo,
                () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const PendingClientListScreen())),
          ),
          _buildBentoAction(
            context,
            "Content Library",
            "Manage Resources",
            Icons.local_library_rounded,
            Colors.teal,
                () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ContentLibraryScreen())),
          ),
          _buildBentoAction(
            context,
            "Ledger",
            "Finances & Bills",
            Icons.account_balance_wallet_rounded,
            Colors.blueGrey,
                () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ClientLedgerOverviewScreen())),
          ),
          _buildBentoAction(
            context,
            "Master Setup",
            "Config & Tools",
            Icons.tune_rounded,
            Colors.deepPurple,
                () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const MasterSetupPage())),
          ),
          _buildBentoAction(
            context,
            "Analytics",
            "Growth & Stats",
            Icons.bar_chart_rounded,
            Colors.pink,
              //  () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analytics coming soon!"))),
             () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
          ),
          _buildBentoAction(
            context,
            "Reports",
            "Data Export",
            Icons.pie_chart_rounded,
            Colors.orange,
                () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reports coming soon!"))),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildHeroStatCard(String title, String value, String footer,
      IconData icon, Color color,
      {bool isHero = false}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHero ? color : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isHero ? color.withOpacity(0.4) : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: isHero ? Colors.white : color, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isHero ? Colors.white : Colors.black87),
              ),
              Text(
                title,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isHero ? Colors.white70 : Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                footer,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isHero ? Colors.white60 : color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoAction(BuildContext context, String title, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String title, String subtitle, String time,
      bool isUrgent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
                color: isUrgent ? Colors.redAccent : Colors.orangeAccent,
                width: 4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red.shade50 : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUrgent
                    ? Icons.priority_high_rounded
                    : Icons.notifications_none_rounded,
                size: 18,
                color: isUrgent ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}