import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/scheduler/admin_scheduler_screen.dart';
import 'package:nutricare_client_management/admin/smart_booking_reminder.dart';
import 'package:nutricare_client_management/admin/smart_nudge_bar.dart';
import 'package:nutricare_client_management/admin/staff_management_screen.dart';

import 'package:nutricare_client_management/admin/admin_dahboard_provider.dart';

// 🎯 MODULE IMPORTS
import 'package:nutricare_client_management/admin/pending_client_list_screen.dart';
import 'package:nutricare_client_management/admin/feed_management_screen.dart';
import 'package:nutricare_client_management/scheduler/content_library_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';
import 'package:nutricare_client_management/admin/admin_analytics_screen.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';

class AdminDashboardHomeScreen extends ConsumerWidget {
  const AdminDashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch View Mode
    final dashboardState = ref.watch(adminDashboardProvider);
    final bool isGlobalView = dashboardState.viewMode == AdminViewMode.global;

    // 🎯 2. Watch Admin Profile (Global Fetch)
    // This ensures 'admin' is available for the Grid logic too
    final adminAsync = ref.watch(currentAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Background
          Positioned(
            top: -100, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isGlobalView ? Colors.deepPurple.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
                    blurRadius: 80, spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: adminAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error loading profile: $err")),
              data: (admin) {
                if (admin == null) return const Center(child: Text("Profile not found"));

                final bool canSwitch = admin.role == AdminRole.superAdmin;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 3. HEADER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // View Switcher
                                Row(
                                  children: [
                                    Text(
                                      isGlobalView ? "ADMIN CONSOLE" : "MY CLINIC",
                                      style: TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.w800,
                                        color: isGlobalView ? Colors.deepPurple : Colors.teal,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    if (canSwitch)
                                      Transform.scale(
                                        scale: 0.7,
                                        child: Switch(
                                          value: isGlobalView,
                                          activeColor: Colors.deepPurple,
                                          inactiveThumbColor: Colors.teal,
                                          onChanged: (val) {
                                            ref.read(adminDashboardProvider.notifier).toggleViewMode();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Hello, ${admin.firstName}",
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                                ),
                              ],
                            ),

                            // Avatar
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountPage())),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isGlobalView ? Colors.deepPurple.withOpacity(0.2) : Colors.teal.withOpacity(0.2), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  backgroundImage: admin.photoUrl.isNotEmpty ? NetworkImage(admin.photoUrl) : null,
                                  child: admin.photoUrl.isEmpty ? Text(admin.firstName[0], style: TextStyle(color: isGlobalView ? Colors.deepPurple : Colors.teal, fontWeight: FontWeight.bold)) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SmartBookingReminders(coachId: admin.id),
                    ),


                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 🎯 3.1 SMART NUDGE BAR (Replaces Reminders)
                    SliverToBoxAdapter(
                      child: SmartNudgeBar(coachId: admin.id),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 4. HERO STATS
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            _buildHeroStatCard(
                                isGlobalView ? "Total Revenue" : "My Revenue",
                                isGlobalView ? "₹12.5L" : "₹1.2L",
                                "Aug 2024", Icons.currency_rupee_rounded, Colors.green, isHero: true
                            ),
                            _buildHeroStatCard(
                                isGlobalView ? "Total Clients" : "My Clients",
                                isGlobalView ? "1,240" : "42", "+5 New", Icons.people_alt_rounded, Colors.blue
                            ),
                            _buildHeroStatCard(
                                "Pending Plans", "3", "Action Req.", Icons.hourglass_top_rounded, Colors.orange
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // 5. SECTION TITLE
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Icon(Icons.grid_view_rounded, size: 20, color: isGlobalView ? Colors.deepPurple : Colors.teal),
                            const SizedBox(width: 8),
                            const Text("Management Console", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          ],
                        ),
                      ),
                    ),

                    // 6. ACTIONS GRID
                    // 🎯 FIX: Pass the 'admin' object here
                    _buildCoreActionsGrid(context, isGlobalView, admin),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Updated Signature to accept AdminProfileModel
  Widget _buildCoreActionsGrid(BuildContext context, bool isGlobal, AdminProfileModel admin) {
    // Helper to check permissions
    bool can(String perm) => admin.hasAccess(perm); // Ensure hasAccess exists in model

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          // 1. Clients
          if (can('onboard_client'))
            _buildBentoAction(context, "Onboard Client", "Register New", Icons.person_add_rounded, Colors.indigo,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingClientListScreen()))),

          // 2. Staff (Super Admin)
          if (isGlobal)
            _buildBentoAction(context, "Manage Team", "Staff & Roles", Icons.groups_rounded, Colors.cyan,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()))),

          // 3. Schedule
          if (can('manage_schedule'))
            _buildBentoAction(context, "Availability", "Slots & Blocks", Icons.calendar_month_rounded, Colors.deepPurple,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSchedulerScreen()))),

          // 4. Feed
          if (can('manage_content'))
            _buildBentoAction(context, "Client Feed", "Posts, Videos", Icons.dynamic_feed_rounded, Colors.deepOrange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedManagementScreen()))),

          // 5. Library
          if (can('manage_content'))
            _buildBentoAction(context, "Content Library", "Diet Tips", Icons.local_library_rounded, Colors.teal,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentLibraryScreen()))),

          // 6. Ledger
          if (can('view_financials'))
            _buildBentoAction(context, "Ledger", "Finances", Icons.account_balance_wallet_rounded, Colors.blueGrey,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLedgerOverviewScreen()))),

          // 7. Master Setup
          if (can('manage_master'))
            _buildBentoAction(context, "Master Setup", "Config & Tools", Icons.tune_rounded, Colors.brown,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterSetupPage()))),

          // 8. Analytics
          if (can('view_analytics'))
            _buildBentoAction(context, "Analytics", "Stats", Icons.bar_chart_rounded, Colors.pink,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()))),
        ],
      ),
    );
  }

  Widget _buildHeroStatCard(String title, String value, String footer, IconData icon, Color color, {bool isHero = false}) {
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isHero ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: isHero ? color.withOpacity(0.4) : Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: isHero ? Colors.white : color, size: 24)]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isHero ? Colors.white : Colors.black87)),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isHero ? Colors.white70 : Colors.grey.shade600)),
          const SizedBox(height: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isHero ? Colors.white24 : color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(footer, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isHero ? Colors.white : color)))
        ])
      ]),
    );
  }

  Widget _buildBentoAction(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500))])])));
  }
}