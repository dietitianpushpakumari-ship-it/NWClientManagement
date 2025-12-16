import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/admin_profile_model.dart';
import 'package:nutricare_client_management/admin/admin_provider.dart';
import 'package:nutricare_client_management/admin/admin_profile_service.dart';
import 'package:nutricare_client_management/login_screen.dart';

class AdminAccountPage extends ConsumerStatefulWidget {
  const AdminAccountPage({super.key});

  @override
  ConsumerState<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends ConsumerState<AdminAccountPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(currentAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: adminAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (profile) {
          if (profile == null) return const Center(child: Text("Profile not found"));
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(profile),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _ProfileDetailsTab(profile: profile),
                const _SettingsTab(), // Placeholder
                const _SecurityTab(), // Placeholder
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(AdminProfileModel profile) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.indigo,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: profile.photoUrl.isNotEmpty ? NetworkImage(profile.photoUrl) : null,

                // 🎯 SAFETY CHECK 1 (Header)
                child: profile.photoUrl.isEmpty
                    ? Text(
                    profile.firstName.isNotEmpty ? profile.firstName[0] : 'A',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.indigo)
                )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                "${profile.firstName} ${profile.lastName}",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                profile.designation,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: "Details"),
          Tab(text: "Settings"),
          Tab(text: "Security"),
        ],
      ),
    );
  }
}

class _ProfileDetailsTab extends StatelessWidget {
  final AdminProfileModel profile;
  const _ProfileDetailsTab({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSection("Personal Info", [
            _buildRow(Icons.email, "Email", profile.email),
            _buildRow(Icons.phone, "Phone", profile.mobile),
            if (profile.alternateMobile.isNotEmpty)
              _buildRow(Icons.phone_android, "Alt Phone", profile.alternateMobile),
          ]),
          const SizedBox(height: 20),
          _buildSection("Professional Info", [
            _buildRow(Icons.business, "Company", profile.companyName),
            _buildRow(Icons.badge, "Designation", profile.designation),
            if (profile.regdNo.isNotEmpty)
              _buildRow(Icons.verified, "Regd No", profile.regdNo),
            _buildRow(Icons.star, "Specializations", profile.specializations.join(", ")),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("App Settings (Theme, Notifications) - Coming Soon"));
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ListTile(
          leading: const Icon(Icons.lock_reset, color: Colors.orange),
          title: const Text("Change Password"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text("Logout"),
          onTap: () {
            // Logout logic handled by provider/service usually
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false
            );
          },
        ),
      ],
    );
  }
}