import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_home_screen.dart';
import 'package:nutricare_client_management/admin/admin_inbox_screen.dart';
import 'package:nutricare_client_management/admin/admin_more_screen.dart';
import 'package:nutricare_client_management/admin/admin_session_provider.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';
import 'package:nutricare_client_management/admin/configuration/app_module_config.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_model.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_services.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_model.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_service.dart';

enum UserRole { superAdmin, clinicAdmin, client }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // 🧩 Navigation Logic (YOUR ORIGINAL LOGIC - PRESERVED)
  _NavConfig _buildNavigationConfig({
    required List<String> companyEnabledModules,
    required List<String> roleAllowedModules,
    required UserRole userRole,
  }) {
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> items = [];

    // 1. DASHBOARD (Always Visible)
    pages.add(const AdminDashboardHomeScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'));

    // Helper to check permission
    bool canAccess(AppModule module) {
      // A. Super Admin & Clinic Admin: "God Mode" (Always True)
      if (userRole == UserRole.superAdmin || userRole == UserRole.clinicAdmin) return true;

      // B. Tenant Check: Is it enabled for this clinic?
      if (!companyEnabledModules.contains(module.id)) return false;

      // C. Staff Check: Does this specific role have permission?
      return roleAllowedModules.contains(module.id);
    }

    // 2. SCHEDULE
    if (canAccess(AppModule.appointments)) {
      pages.add(const AllMeetingsScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Schedule'));
    }

    // 3. INBOX
    if (canAccess(AppModule.chat)) {
      pages.add(const AdminInboxScreen());
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Inbox'));
    }

    // 4. ALERTS
    pages.add(const Center(child: Text("Notifications (Coming Soon)")));
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'));

    // 5. MORE
    pages.add(const AdminMoreScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'More'));

    return _NavConfig(pages, items);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 1. GET SESSION
    final session = ref.watch(adminSessionProvider);

    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 🎯 2. DETERMINE ROLE
    UserRole currentUserRole = UserRole.client;
    String staffAppRole = session.role;
    String? tenantId = session.tenantId;

    if (session.isSuperAdmin || session.role == 'superAdmin') {
      currentUserRole = UserRole.superAdmin;
    } else if (session.role == 'clinicAdmin' || session.role == 'owner') {
      currentUserRole = UserRole.clinicAdmin;
      staffAppRole = 'clinicAdmin';
    }

    // ==============================================================
    // 👑 PATH A: SUPER ADMIN (Bypass DB Configs)
    // ==============================================================
    if (currentUserRole == UserRole.superAdmin) {
      // Super Admin gets everything enabled by default
      final navConfig = _buildNavigationConfig(
        companyEnabledModules: AppModule.values.map((e) => e.id).toList(), // Enable All
        roleAllowedModules: AppModule.values.map((e) => e.id).toList(),    // Enable All
        userRole: UserRole.superAdmin,
      );
      return _buildScaffold(navConfig);
    }

    // ==============================================================
    // 🏥 PATH B: CLINIC USER (Fetch Configs from DB)
    // ==============================================================

    // Safety Check for Staff
    if (tenantId == null) {
      return const Scaffold(body: Center(child: Text("Error: Staff user has no Tenant ID")));
    }

    final configService = ref.watch(companyConfigServiceProvider);
    final permService = ref.watch(rolePermissionServiceProvider);

    // Stream 1: Company Config
    return StreamBuilder<CompanyConfigModel>(
      stream: configService.streamCompanyConfig(tenantId),
      builder: (context, companySnap) {

        final roleToStream = (currentUserRole == UserRole.client) ? staffAppRole : 'admin_bypass';

        // Stream 2: Role Permissions
        return StreamBuilder<RolePermissionModel>(
          stream: permService.streamPermissionForRole(tenantId, roleToStream),
          builder: (context, roleSnap) {

            if (companySnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            // Extract Data
            final companyModules = companySnap.data?.enabledModules ?? [];
            final roleModules = roleSnap.data?.moduleIds ?? [];

            // Build Nav Config
            final navConfig = _buildNavigationConfig(
              companyEnabledModules: companyModules,
              roleAllowedModules: roleModules,
              userRole: currentUserRole,
            );

            return _buildScaffold(navConfig);
          },
        );
      },
    );
  }

  // Helper to build the final Scaffold
  Widget _buildScaffold(_NavConfig navConfig) {
    if (_selectedIndex >= navConfig.pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: navConfig.pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navConfig.items,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        elevation: 10,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class _NavConfig {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> items;
  _NavConfig(this.pages, this.items);
}