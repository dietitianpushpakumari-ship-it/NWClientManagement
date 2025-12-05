import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/appoinment_settelment_screen.dart';
import 'package:nutricare_client_management/admin/dashboard_metric_service.dart';
import 'package:nutricare_client_management/admin/scheduler/admin_scheduler_screen.dart';
import 'package:nutricare_client_management/admin/smart_booking_reminder.dart';
import 'package:nutricare_client_management/admin/smart_nudge_bar.dart';
import 'package:nutricare_client_management/admin/staff_management_screen.dart';
import 'package:nutricare_client_management/admin/admin_dahboard_provider.dart';
import 'package:nutricare_client_management/admin/pending_client_list_screen.dart';
import 'package:nutricare_client_management/admin/feed_management_screen.dart';
import 'package:nutricare_client_management/scheduler/content_library_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';
import 'package:nutricare_client_management/admin/admin_analytics_screen.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';


class AdminDashboardHomeScreen extends ConsumerWidget {
  const AdminDashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final bool isGlobalView = dashboardState.viewMode == AdminViewMode.global;
    final adminAsync = ref.watch(currentAdminProvider);
    final metrics = DashboardMetricsService();

    final primaryColor = isGlobalView ? Colors.deepPurple : Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150, right: -100,
            child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 100, spreadRadius: 40)])),
          ),

          SafeArea(
            child: adminAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (admin) {
                if (admin == null) return const Center(child: Text("Profile not found"));
                final bool canSwitch = admin.role == AdminRole.superAdmin;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. HEADER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        isGlobalView ? "ADMIN CONSOLE" : "MY CLINIC",
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 1.0),
                                      ),
                                    ),
                                    if (canSwitch)
                                      Transform.scale(
                                        scale: 0.7,
                                        child: Switch(
                                          value: isGlobalView,
                                          activeColor: Colors.deepPurple,
                                          inactiveThumbColor: Colors.teal,
                                          onChanged: (val) => ref.read(adminDashboardProvider.notifier).toggleViewMode(),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text("Hello, ${admin.firstName}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountPage())),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: admin.photoUrl.isNotEmpty ? NetworkImage(admin.photoUrl) : null,
                                  backgroundColor: primaryColor.shade50,
                                  child: admin.photoUrl.isEmpty ? Text(admin.firstName[0], style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. ACTION RADAR (Live Streams)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Row(
                          children: [
                            // A. REQUESTS
                            Expanded(
                              child: StreamBuilder<int>(
                                stream: metrics.streamPendingRequestCount(admin.id),
                                builder: (context, snapshot) => _buildLiveActionCard(
                                  context, "Requests", snapshot.data ?? 0, Icons.notifications_active, Colors.orange,
                                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllMeetingsScreen())),
                                  (snapshot.data ?? 0) > 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // B. UPCOMING
                            Expanded(
                              child: StreamBuilder<int>(
                                stream: metrics.streamUpcomingCount(admin.id),
                                builder: (context, snapshot) => _buildLiveActionCard(
                                  context, "Upcoming", snapshot.data ?? 0, Icons.calendar_today, Colors.indigo,
                                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllMeetingsScreen())),
                                  false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. STRATEGIC INSIGHTS
                    SliverToBoxAdapter(
                      child: Container(
                        height: 140,
                        margin: const EdgeInsets.only(top: 10, bottom: 20),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            StreamBuilder<int>(
                                stream: metrics.streamPendingPlanCount(),
                                builder: (ctx, snap) {
                                  final count = snap.data ?? 0;
                                  return _buildStrategyCard("Pending Plans", "$count Clients", "Needs Diet Plan", Icons.restaurant_menu, Colors.blue, () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PendingClientListScreen())));
                                }
                            ),
                            FutureBuilder<double>(
                                future: metrics.fetchTotalPendingCollections(),
                                builder: (ctx, snap) {
                                  final amount = snap.data ?? 0.0;
                                  return _buildStrategyCard("Collections", "₹${amount.toStringAsFixed(0)}", "Payment Pending", Icons.account_balance_wallet, Colors.green, () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ClientLedgerOverviewScreen())));
                                }
                            ),
                            FutureBuilder<List<String>>(
                                future: metrics.fetchAtRiskClientNames(),
                                builder: (ctx, snap) {
                                  final count = snap.data?.length ?? 0;
                                  return _buildStrategyCard("Retention Radar", "$count At Risk", "Inactive >3 Days", Icons.radar, Colors.red, () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())));
                                }
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. SMART NUDGES
                    SliverToBoxAdapter(child: SmartNudgeBar(coachId: admin.id)),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // 5. COACH STREAK
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.deepOrange.shade600]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.deepOrange.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
                        ),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.local_fire_department, color: Colors.white, size: 28)),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Productivity Streak!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("You're on fire! 5 days active.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white54)
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 6. SECTION HEADER
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text("QUICK ACTIONS", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // 7. CORE ACTIONS GRID
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

  // --- WIDGETS ---

  Widget _buildLiveActionCard(BuildContext context, String title, int count, IconData icon, Color color, VoidCallback onTap, bool isAlert) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 🎯 FIX: Increased height to prevent overflow
        height: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAlert ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: isAlert ? color.withOpacity(0.4) : Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
          gradient: isAlert
              ? LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : LinearGradient(colors: [Colors.white, color.withOpacity(0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: isAlert ? null : Border.all(color: Colors.white, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // 🎯 FIX: Use Spacer() for safe flexibility instead of MainAxisAlignment.spaceBetween
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: isAlert ? Colors.white.withOpacity(0.2) : Colors.white, shape: BoxShape.circle),
                  child: Icon(icon, color: isAlert ? Colors.white : color, size: 18),
                ),
                if (isAlert) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
              ],
            ),
            const Spacer(), // Pushes text to bottom safely
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(count.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isAlert ? Colors.white : const Color(0xFF2D3142))),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isAlert ? Colors.white.withOpacity(0.9) : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(String title, String value, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
            border: Border.all(color: Colors.white, width: 1)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 24, color: color)),
            const Spacer(), // Safe spacing
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3142)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreActionsGrid(BuildContext context, bool isGlobal, AdminProfileModel admin) {
    bool can(String perm) => admin.hasAccess(perm);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        // 🎯 FIX: Adjusted ratio to prevent text overflow in Bento Cards
        childAspectRatio: 1.1,
        children: [
          if (can('onboard_client')) _buildBentoAction(context, "Onboard", "New Client", Icons.person_add_alt_1_rounded, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingClientListScreen()))),
          if (isGlobal) _buildBentoAction(context, "Team", "Manage Roles", Icons.groups_2_rounded, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()))),
          if (can('manage_schedule')) _buildBentoAction(context, "Availability", "Slots & Blocks", Icons.edit_calendar_rounded, Colors.deepPurple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSchedulerScreen()))),
          if (can('manage_content')) _buildBentoAction(context, "Client Feed", "Engage", Icons.dynamic_feed_rounded, Colors.deepOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedManagementScreen()))),
          if (can('manage_content')) _buildBentoAction(context, "Library", "Diet Tips", Icons.book_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContentLibraryScreen()))),
          if (can('view_financials')) ...[
            _buildBentoAction(context, "Ledger", "Records", Icons.account_balance_wallet_rounded, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLedgerOverviewScreen()))),
            _buildBentoAction(context, "Settlements", "Verify", Icons.verified_user_rounded, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentSettlementScreen()))),
          ],
          if (can('manage_master')) _buildBentoAction(context, "Setup", "Master Data", Icons.tune_rounded, Colors.brown, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterSetupPage()))),
          if (can('view_analytics')) _buildBentoAction(context, "Analytics", "Reports", Icons.bar_chart_rounded, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()))),
        ],
      ),
    );
  }

  Widget _buildBentoAction(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)), BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 0))],
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, color.withOpacity(0.05)]),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned(right: -15, bottom: -15, child: Transform.rotate(angle: -0.2, child: Icon(icon, size: 80, color: color.withOpacity(0.05)))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(icon, color: color, size: 20)),
                        const Spacer(),
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                        const SizedBox(height: 2),
                        Row(children: [
                          Expanded(child: Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: color.withOpacity(0.5))
                        ])
                      ],
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }
}