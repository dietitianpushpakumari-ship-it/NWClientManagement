import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/configuration/app_module_config.dart';
import 'package:nutricare_client_management/admin/configuration/app_roles.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_model.dart';
import 'package:nutricare_client_management/admin/configuration/role_permission_service.dart';


class RolePolicyManagerScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const RolePolicyManagerScreen({super.key, required this.tenantId});

  @override
  ConsumerState<RolePolicyManagerScreen> createState() => _RolePolicyManagerScreenState();
}

class _RolePolicyManagerScreenState extends ConsumerState<RolePolicyManagerScreen> {
  AppRole _selectedRole = AppRole.dietitian; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Row(
                children: [
                  // 👈 LEFT PANEL: Role List
                  Container(
                    width: 100,
                    color: Colors.white,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: AppRole.values.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final role = AppRole.values[index];
                        final isSelected = role == _selectedRole;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedRole = role),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.indigo : Colors.indigo.shade50,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: Colors.indigo.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
                                      : [],
                                ),
                                child: Icon(role.icon, color: isSelected ? Colors.white : Colors.indigo, size: 24),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  role.label.split(' / ').first,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.indigo : Colors.grey
                                  )
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 👉 RIGHT PANEL: Module Toggles
                  Expanded(
                    child: _buildPermissionPanel(_selectedRole),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPanel(AppRole role) {
    // Watch real-time permissions for this role
    final permStream = ref.watch(rolePermissionServiceProvider).streamPermissionForRole(widget.tenantId, role.id);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(role.icon, size: 28, color: Colors.black87),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Access Permissions", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const Divider(height: 30),
          Expanded(
            child: StreamBuilder<RolePermissionModel>(
              stream: permStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Current list of allowed module IDs
                final currentModules = snapshot.data?.moduleIds ?? [];

                return ListView.builder(
                  itemCount: AppModule.values.length,
                  itemBuilder: (context, index) {
                    final module = AppModule.values[index];
                    final isEnabled = currentModules.contains(module.id);

                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.green,
                      title: Text(module.label, style: TextStyle(fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(module.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      value: isEnabled,
                      onChanged: (val) {
                        // Optimistic Update
                        final newModules = List<String>.from(currentModules);
                        if (val) {
                          newModules.add(module.id);
                        } else {
                          newModules.remove(module.id);
                        }
                        // Save to Firestore
                        ref.read(rolePermissionServiceProvider).updatePermissions(widget.tenantId, role.id, newModules);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
          const SizedBox(width: 16),
          const Text("Role & Permissions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}