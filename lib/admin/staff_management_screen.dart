import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 🎯 Import
import 'package:nutricare_client_management/admin/staff_management_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_profile_model.dart';
import 'dietitian_onboarding_screen.dart'; // 🎯 Import

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffManagementService _service = StaffManagementService();
  final TextEditingController _searchCtrl = TextEditingController();

  AdminRole? _selectedRole;
  bool _showInactive = false;
  String _searchQuery = "";

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- CONTACT LOGIC ---

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  void _showContactOptions(AdminProfileModel staff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: staff.photoUrl.isNotEmpty ? NetworkImage(staff.photoUrl) : null,
                  child: staff.photoUrl.isEmpty ? Text(staff.firstName[0]) : null,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Contact ${staff.firstName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(staff.designation, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),

            // 1. WhatsApp (Primary)
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20)),
              title: Text(staff.mobile),
              subtitle: const Text("WhatsApp"),
              onTap: () => _launch("https://wa.me/${staff.mobile}"),
            ),

            // 2. Call Primary
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.call, color: Colors.white, size: 20)),
              title: Text(staff.mobile),
              subtitle: const Text("Call Primary"),
              onTap: () => _launch("tel:${staff.mobile}"),
            ),

            // 3. Call Alternate (If exists)
            if (staff.alternateMobile.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.phone_android, color: Colors.white, size: 20)),
                title: Text(staff.alternateMobile),
                subtitle: const Text("Call Alternative"),
                onTap: () => _launch("tel:${staff.alternateMobile}"),
              ),

            // 4. Email
            if (staff.email.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.email, color: Colors.white, size: 20)),
                title: Text(staff.email),
                subtitle: const Text("Send Email"),
                onTap: () => _launch("mailto:${staff.email}"),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleStatus(AdminProfileModel staff) async {
    final newStatus = !staff.isActive;
    final action = newStatus ? "Activate" : "Deactivate";

    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("$action Staff?"),
          content: Text("Are you sure you want to $action ${staff.firstName}?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: newStatus ? Colors.green : Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action, style: const TextStyle(color: Colors.white)),
            )
          ],
        )
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('admins').doc(staff.id).update({'isActive': newStatus});
    }
  }

  void _editStaff(AdminProfileModel staff) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DietitianOnboardingScreen(staffToEdit: staff)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: 12),
                      _buildFilterBar(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('admins').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data?.docs ?? [];

                      var filtered = docs.map((d) => AdminProfileModel.fromFirestore(d)).where((staff) {
                        if (!_showInactive && !staff.isActive) return false;
                        if (_selectedRole != null && staff.role != _selectedRole) return false;
                        if (_searchQuery.isNotEmpty) {
                          final matchName = staff.fullName.toLowerCase().contains(_searchQuery);
                          final matchId = staff.employeeId.toLowerCase().contains(_searchQuery);
                          if (!matchName && !matchId) return false;
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) return _buildEmptyState();

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_,__) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => _buildStaffCard(filtered[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DietitianOnboardingScreen())),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Staff", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
            const SizedBox(width: 16),
            const Text("Team Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: const InputDecoration(hintText: "Search Name or Emp ID...", prefixIcon: Icon(Icons.search, color: Colors.grey), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16)),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _buildFilterChip("All Roles", _selectedRole == null, () => setState(() => _selectedRole = null)),
        ...AdminRole.values.map((r) => _buildFilterChip(r.name.toUpperCase(), _selectedRole == r, () => setState(() => _selectedRole = r))),
        const SizedBox(width: 8),
        FilterChip(label: const Text("Show Inactive"), selected: _showInactive, onSelected: (v) => setState(() => _showInactive = v), selectedColor: Colors.red.shade50, checkmarkColor: Colors.red, side: BorderSide.none, backgroundColor: Colors.white, elevation: 2)
      ]),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: isSelected ? Colors.indigo : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: isSelected ? [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
          child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildStaffCard(AdminProfileModel staff) {
    final bool isActive = staff.isActive;
    return Container(
      decoration: BoxDecoration(color: isActive ? Colors.white : Colors.grey.shade50, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))], border: !isActive ? Border.all(color: Colors.grey.shade300) : null),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(children: [
              Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isActive ? Colors.indigo.withOpacity(0.2) : Colors.grey, width: 2)), child: CircleAvatar(radius: 28, backgroundImage: staff.photoUrl.isNotEmpty ? NetworkImage(staff.photoUrl) : null, backgroundColor: isActive ? Colors.indigo.shade50 : Colors.grey.shade200, child: staff.photoUrl.isEmpty ? Text(staff.firstName[0], style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.indigo : Colors.grey, fontSize: 20)) : null)),
              if (isActive) Positioned(bottom: 2, right: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(staff.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? const Color(0xFF1A1A1A) : Colors.grey)),
                const SizedBox(height: 4),
                Text("${staff.designation} • ${staff.role.name.toUpperCase()}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text("ID: ${staff.employeeId}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)))
              ]),
            ),
            Column(children: [
              // 🎯 Contact Button
              IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _showContactOptions(staff)),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') _editStaff(staff);
                  if (val == 'toggle') _toggleStatus(staff);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Edit Profile")])),
                  PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isActive ? Icons.block : Icons.check_circle, size: 18, color: isActive ? Colors.red : Colors.green), const SizedBox(width: 8), Text(isActive ? "Deactivate" : "Activate")])),
                ],
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.group_off_rounded, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text("No staff found matching criteria.", style: TextStyle(color: Colors.grey.shade500))]));
  }
}