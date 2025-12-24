// Create a new file: lib/admin/generic_staff_master_manager.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/staff_management_service.dart';

class GenericStaffMasterManager extends ConsumerWidget {
  final String title;
  final String entityType;

  const GenericStaffMasterManager({required this.title, required this.entityType, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(staffManagementProvider);

    // Select the correct stream and field name based on entityType
    Stream<List<String>> stream;
    String field;

    if (entityType == 'STAFF_DESIGNATION') {
      stream = service.streamDesignations();
      field = 'designations';
    } else if (entityType == 'STAFF_QUALIFICATION') {
      stream = service.streamQualifications();
      field = 'qualifications';
    } else {
      stream = service.streamSpecializations();
      field = 'specializations';
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<String>>(
        stream: stream,
        builder: (context, snapshot) {
          // 1. Handle Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle Errors
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];

          // 3. Handle Empty List (This prevents the "Blank" look)
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("No $title found. Tap + to add."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(context, service, field, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => service.deleteFromMaster(field, item),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context, service, field),
      ),
    );
  }

  void _showAddDialog(BuildContext context, StaffManagementService service, String field) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add New $title"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (field == 'designations') service.addDesignationToMaster(controller.text);
              else if (field == 'qualifications') service.addQualificationToMaster(controller.text);
              else service.addSpecializationToMaster(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, StaffManagementService service, String field, String oldValue) {
    final controller = TextEditingController(text: oldValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              service.updateInMaster(field, oldValue, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}