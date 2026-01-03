import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 識 MODELS & PROVIDERS
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/admin_dahboard_provider.dart';
import 'package:nutricare_client_management/admin/daily_consultation_queue_screen.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';

// 識 SCREENS
import 'package:nutricare_client_management/admin/company_list_Screen.dart';
import 'package:nutricare_client_management/admin/migration/migration%20dashboard.dart';
import 'package:nutricare_client_management/admin/pending_client_list_screen.dart';
import 'package:nutricare_client_management/admin/staff_management_screen.dart';
import 'package:nutricare_client_management/admin/scheduler/admin_scheduler_screen.dart';
import 'package:nutricare_client_management/admin/feed_management_screen.dart';
import 'package:nutricare_client_management/modules/appointment/screens/booking/service_selection_screen.dart';
import 'package:nutricare_client_management/pages/admin/client_ledger_overview_screen.dart';
import 'package:nutricare_client_management/screens/admin_book_for_client_screen.dart';
import 'package:nutricare_client_management/screens/dash/master_Setup_page.dart';
import 'package:nutricare_client_management/admin/admin_analytics_screen.dart';
import 'package:nutricare_client_management/admin/admin_account_page.dart';
// 🎯 NEW IMPORT
import 'package:nutricare_client_management/admin/system_config_screen.dart';

import 'admin_session_provider.dart';

class AdminDashboardHomeScreen extends ConsumerWidget {
  const AdminDashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);
    final bool isGlobalView = dashboardState.viewMode == AdminViewMode.global;
    final adminAsync = ref.watch(currentAdminProvider);

    // 識 1. GET CURRENT TENANT CONTEXT
    final currentTenant = ref.watch(adminSessionProvider);

    final primaryColor = isGlobalView ? Colors.deepPurple : Colors.teal;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -150, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 100, spreadRadius: 40)]),
            ),
          ),

          SafeArea(
            child: adminAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
              data: (admin) {
                if (admin == null) return const Center(child: Text("Profile not found"));

                // 識 2. STRICT PERMISSION LOGIC
                final bool isSuperAdmin = admin.role == AdminRole.superAdmin ;
                final bool isClinicAdmin = admin.role == AdminRole.clinicAdmin;
                final bool canSwitch = isSuperAdmin || isClinicAdmin || admin.permissions.contains('view_financials');

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
                                Text(
                                  "Hello, ${admin.firstName.isNotEmpty ? admin.firstName : 'Admin'}",
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAccountPage())),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundImage: admin.photoUrl.isNotEmpty ? NetworkImage(admin.photoUrl) : null,
                                  backgroundColor: primaryColor.shade50,
                                  child: admin.photoUrl.isEmpty
                                      ? Text(admin.firstName.isNotEmpty ? admin.firstName[0] : 'A', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. SECTION HEADER (QUICK ACTIONS)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
                        child: Text(
                          "QUICK ACTIONS",
                          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                        ),
                      ),
                    ),

                    // 3. CORE ACTIONS GRID
                    _buildCoreActionsGrid(context, isGlobalView, admin, isSuperAdmin, isClinicAdmin),

                    // 🎯 4. NEW SECTION: SYSTEM CONFIGURATION (Super Admin Only)
                    if (!isSuperAdmin) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 30, 28, 12),
                          child: Text(
                            "SYSTEM & CONFIGURATION",
                            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            // 🎯 SYSTEM CONFIG CARD
                            _buildBentoAction(
                              context,
                              "System Keys",
                              "API & AI Models",
                              Icons.vpn_key_rounded,
                              Colors.blueGrey,
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemConfigScreen())),
                            ),

                            // You can also move DB Migration here if you want to group tech stuff
                          ],
                        ),
                      ),
                    ],

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

  // ... [Keep _buildCoreActionsGrid and _buildBentoAction exactly as they were] ...

  Widget _buildCoreActionsGrid(BuildContext context, bool isGlobal, AdminProfileModel admin, bool isSuperAdmin, bool isClinicAdmin) {
    bool can(String perm) => admin.hasAccess(perm);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [


          if (isSuperAdmin) ...[
            _buildBentoAction(
              context, "Add Clinic", "Onboard Tenant", Icons.domain_add_rounded, Colors.blueAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyListScreen())),
            ),
            _buildBentoAction(
              context, "DB Migration", "Transfer Data", Icons.move_to_inbox, Colors.redAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MigrationDashboard())),
            ),
          ],

          if (isSuperAdmin || isClinicAdmin || can('onboard_client'))
            _buildBentoAction(
              context,
              "Today's Queue",
              "Manage daily visits",
              Icons.calendar_view_day_rounded,
              Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyConsultationQueueScreen())),
            ),
          if (isSuperAdmin || isClinicAdmin || can('onboard_client'))
            _buildBentoAction(
              context, "Onboard", "New Client", Icons.person_add_alt_1_rounded, Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingClientListScreen())),
            ),

          if (isGlobal && (isSuperAdmin || isClinicAdmin))
            _buildBentoAction(
              context, "Team", "Manage Roles", Icons.groups_2_rounded, Colors.cyan,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('manage_schedule'))
            _buildBentoAction(
              context, "Availability", "Slots & Blocks", Icons.edit_calendar_rounded, Colors.deepPurple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSchedulerScreen())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('manage_schedule'))
            _buildBentoAction(
              context, "new", "Slots & Blocks", Icons.edit_calendar_rounded, Colors.deepPurple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  ServiceSelectionScreen())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('manage_schedule'))
            _buildBentoAction(
              context, "new1", "Slots & Blocks", Icons.edit_calendar_rounded, Colors.deepPurple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookForClientScreen())),
            ),
          if (isSuperAdmin || isClinicAdmin || can('manage_content'))
            _buildBentoAction(
              context, "Content", "Feed & Library", Icons.dynamic_feed_rounded, Colors.deepOrange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) =>  FeedManagementScreen())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('view_financials'))
            _buildBentoAction(
              context, "Ledger", "Records", Icons.account_balance_wallet_rounded, Colors.blueGrey,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientLedgerOverviewScreen())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('manage_master'))
            _buildBentoAction(
              context, "Setup", "Master Data", Icons.tune_rounded, Colors.brown,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterSetupPage())),
            ),

          if (isSuperAdmin || isClinicAdmin || can('view_analytics'))
            _buildBentoAction(
              context, "Analytics", "Reports", Icons.bar_chart_rounded, Colors.pink,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen())),
            ),
        ],
      ),
    );
  }

  Widget _buildBentoAction(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 0))
          ],
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, color.withOpacity(0.05)]),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -15, bottom: -15,
                child: Transform.rotate(angle: -0.2, child: Icon(icon, size: 80, color: color.withOpacity(0.05))),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: color.withOpacity(0.5)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}