import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_dashboard_home_screen.dart';
import 'package:nutricare_client_management/admin/admin_inbox_screen.dart';
import 'package:nutricare_client_management/admin/admin_more_screen.dart';
import 'package:nutricare_client_management/admin/all_meeting_screen.dart';
import 'package:nutricare_client_management/admin/configuration/app_module_config.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_model.dart';
import 'package:nutricare_client_management/admin/configuration/company_config_services.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_model.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_service.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // 🎯 Key Import


enum UserRole { superAdmin, clinicAdmin, client }

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String? _resolvedTenantId;

  UserRole _currentUserRole = UserRole.client;
  String _staffAppRole = 'guest';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 🎯 Defer execution to safe phase so we can use ref.read()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveUserContext();
    });
  }

  Future<void> _resolveUserContext() async {
    try {
      // 🎯 1. GET AUTH VIA PROVIDER (Correct Instance)
      final auth = ref.read(authProvider);
      final user = auth.currentUser;

      if (user == null) {
        print("❌ No user logged in (via Auth Provider)");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String? tenantId;
      UserRole userRole = UserRole.client;
      String appRole = 'guest';

      // 🎯 2. GET FIRESTORE VIA PROVIDER (Correct Database)
      final firestore = ref.read(firestoreProvider);

      // Check Super Admin Impersonation First
      final config = ref.read(currentTenantConfigProvider);

      if (config != null) {
        tenantId = config.id;
        userRole = UserRole.clinicAdmin;
      } else {
        // Normal Login: Check 'admins' collection
        final adminDoc = await firestore.collection('admins').doc(user.uid).get();

        if (adminDoc.exists) {
          final data = adminDoc.data()!;
          tenantId = data['tenantId'] ?? data['tenant_id'];

          final roleStr = (data['role'] as String? ?? 'guest');

          if (roleStr == 'clinicAdmin' || roleStr == 'owner') {
            userRole = UserRole.clinicAdmin;
            appRole = 'clinicAdmin';
          } else {
            userRole = UserRole.client; // Staff
            appRole = roleStr; // e.g. 'dietitian'
          }
        } else {
          print("⚠️ User document not found in 'admins' for UID: ${user.uid}");
        }
      }

      if (mounted) {
        setState(() {
          _resolvedTenantId = tenantId;
          _currentUserRole = userRole;
          _staffAppRole = appRole;
          _isLoading = false;
        });
        print("✅ Resolved Context: Tenant=$tenantId, AccessLevel=$_currentUserRole, AppRole=$_staffAppRole");
      }
    } catch (e) {
      print("Error resolving context: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🧩 Navigation Logic
  _NavConfig _buildNavigationConfig(List<String> companyEnabledModules, List<String> roleAllowedModules) {
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> items = [];

    // 1. DASHBOARD
    pages.add(const AdminDashboardHomeScreen());
    items.add(const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'));

    bool canAccess(AppModule module) {
      // 1. Company Check
      if (!companyEnabledModules.contains(module.id)) return false;

      // 2. Role Check (God Mode for Clinic Admin)
      if (_currentUserRole == UserRole.clinicAdmin || _currentUserRole == UserRole.superAdmin) return true;

      // 3. Staff Role Check
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_resolvedTenantId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Configuration Error", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Tenant ID not found. Contact support."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _resolveUserContext(),
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    final configService = ref.watch(companyConfigServiceProvider);
    final permService = ref.watch(rolePermissionServiceProvider);
    final tid = _resolvedTenantId!;

    return StreamBuilder<CompanyConfigModel>(
      stream: configService.streamCompanyConfig(tid),
      builder: (context, companySnap) {

        final roleToStream = (_currentUserRole == UserRole.client) ? _staffAppRole : 'admin_bypass';

        return StreamBuilder<RolePermissionModel>(
          stream: permService.streamPermissionForRole(tid, roleToStream),
          builder: (context, roleSnap) {

            if (companySnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final companyModules = companySnap.data?.enabledModules ?? [];
            final roleModules = roleSnap.data?.moduleIds ?? [];

            final navConfig = _buildNavigationConfig(companyModules, roleModules);

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
          },
        );
      },
    );
  }
}

class _NavConfig {
  final List<Widget> pages;
  final List<BottomNavigationBarItem> items;
  _NavConfig(this.pages, this.items);
}