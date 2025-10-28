import 'package:flutter/material.dart';

// 🎯 STUB IMPORTS: Replace with your actual project paths
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';


// --- Enums and Utility Functions ---

enum PackageGroup { active, archived }

PackageGroup getPackageGroup(PackageAssignmentModel assignment) {
  // Assuming 'isActive' determines the group status
  return assignment.isActive ? PackageGroup.active : PackageGroup.archived;
}


// --- Main Screen Widget ---

class ClientPackageListScreen extends StatefulWidget {
  final ClientModel client;

  const ClientPackageListScreen({super.key, required this.client});

  @override
  State<ClientPackageListScreen> createState() => _ClientPackageListScreenState();
}

class _ClientPackageListScreenState extends State<ClientPackageListScreen> {
  final ClientService _clientService = ClientService();
  bool _isArchiveExpanded = false;
  late ClientModel _clientProfile;

  @override
  void initState() {
    super.initState();
    _clientProfile = widget.client;
  }

  // --- Core Action Handlers ---

  // 🎯 IMPLEMENTATION: Archive/Unarchive Toggle
  Future<void> _handleArchiveToggle(PackageAssignmentModel assignment) async {
    final bool currentlyActive = assignment.isActive;
    final String action = currentlyActive ? 'Archiving' : 'Activating';

    try {
      final updatedAssignment = assignment.copyWith(
        isActive: !currentlyActive, // Toggle the status
        isLocked: false, // Optional: Unlock on status change
      );

      // Assuming ClientService has an update method that saves the changes
      await _clientService.updateAssignedPackage(clientId: widget.client.id,updatedAssignment: updatedAssignment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${assignment.packageName} successfully ${currentlyActive ? 'archived' : 'set as active'}.'),
          backgroundColor: currentlyActive ? Colors.orange.shade700 : Colors.green.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 🎯 IMPLEMENTATION: Delete Package
  Future<void> _handleDelete(PackageAssignmentModel assignment) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to permanently delete the package assignment for "${assignment.packageName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        // Assuming ClientService has a delete method
        await _clientService.deleteAssignedPackage(clientId: widget.client.id, packageId: assignment.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package assignment deleted successfully.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete package: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- UI Action Handlers (Kept) ---

  void _navigateToAssignPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageAssignmentPage(
          clientId: widget.client.id,
          clientName: _clientProfile.name,
          onPackageAssignment: () {},
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToPaymentLedger(PackageAssignmentModel assignment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentLedgerScreen(
          assignment: assignment,
          clientName: _clientProfile.name,
          initialCollectedAmount: 0.0,
        ),
      ),
    );
  }

  Future<void> _toggleLockStatus(PackageAssignmentModel assignment) async {
    final bool isLocked = assignment.isLocked;
    final String action = isLocked ? 'Unlocking' : 'Locking';

    try {
      final updatedAssignment = assignment.copyWith(
        isLocked: !isLocked,
      );
      await _clientService.updateAssignedPackage(clientId: widget.client.id, updatedAssignment: updatedAssignment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Package ${assignment.packageName} ${isLocked ? 'Unlocked' : 'Locked'} successfully.'),
          backgroundColor: isLocked ? Colors.orange.shade700 : Colors.blue.shade700,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Widget Builders ---

  Widget _buildAssignmentTile(PackageAssignmentModel assignment) {
    final bool isLocked = assignment.isLocked;
    final bool isActive = getPackageGroup(assignment) == PackageGroup.active;

    final lockIcon = isLocked ? Icons.lock_rounded : Icons.lock_open_rounded;
    final lockColor = isLocked ? Colors.red.shade700 : Colors.green.shade700;

    final archiveIcon = isActive ? Icons.archive : Icons.unarchive;
    final archiveTooltip = isActive ? 'Archive Package' : 'Activate Package';
    final archiveColor = isActive ? Colors.orange.shade700 : Colors.blue.shade700;

    return ListTile(
      leading: Icon(
        isActive ? Icons.wallet_membership : Icons.archive,
        color: isActive ? Colors.indigo : Colors.orange,
      ),
      title: Text(
        assignment.packageName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isLocked ? Colors.black54 : null,
        ),
      ),
      subtitle: Text(
          'Assigned on: ${assignment. purchaseDate.toString().split(' ')[0]}'
      ),
      onTap: () => _navigateToPaymentLedger(assignment),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Lock/Freeze Toggle Button
          IconButton(
            icon: Icon(lockIcon, color: lockColor),
            tooltip: isLocked ? 'Unlock Package' : 'Lock Package',
            onPressed: () => _toggleLockStatus(assignment),
          ),

          // 2. Archive/Activate Toggle Button
          IconButton(
            icon: Icon(archiveIcon, color: archiveColor),
            tooltip: archiveTooltip,
            onPressed: () => _handleArchiveToggle(assignment),
          ),

          // 3. Delete Button (Often placed at the end and in red for finality)
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Delete Package Assignment',
            onPressed: () => _handleDelete(assignment),
          ),

          // 4. Edit/Ledger Button (Optional: Can be accessed via onTap)
          // IconButton(
          //   icon: const Icon(Icons.payment, color: Colors.blue),
          //   tooltip: 'View Payment Ledger',
          //   onPressed: () => _navigateToPaymentLedger(assignment),
          // ),
        ],
      ),
    );
  }

  // ... (The rest of the build and helper methods remain the same) ...

  Widget _buildExpansionTile({
    required String title, required IconData icon, required Color color,
    required bool isExpanded, required ValueChanged<bool> onExpansionChanged,
    required List<PackageAssignmentModel> assignments,
  }) {
    if (assignments.isEmpty && title.contains("Active")) return const SizedBox.shrink();

    return ExpansionTile(
      initiallyExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      children: assignments.map((plan) => _buildAssignmentTile(plan)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.client.name}\'s Packages'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Assign New Package',
            onPressed: _navigateToAssignPage,
          )
        ],
      ),
      body: StreamBuilder<List<PackageAssignmentModel>>(
        stream: _clientService.streamClientAssignments(widget.client.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading packages: ${snapshot.error}'));
          }

          final allAssignments = snapshot.data ?? [];

          final activeAssignments = allAssignments.where((p) => getPackageGroup(p) == PackageGroup.active).toList();
          final archivedAssignments = allAssignments.where((p) => getPackageGroup(p) == PackageGroup.archived).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              _buildExpansionTile(
                title: 'Active Packages (${activeAssignments.length})',
                icon: Icons.check_circle,
                color: Colors.green,
                isExpanded: true,
                onExpansionChanged: (_) {},
                assignments: activeAssignments,
              ),

              _buildExpansionTile(
                title: 'Archived Packages (${archivedAssignments.length})',
                icon: Icons.archive,
                color: Colors.orange,
                isExpanded: _isArchiveExpanded,
                onExpansionChanged: (expanded) => setState(() => _isArchiveExpanded = expanded),
                assignments: archivedAssignments,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAssignPage,
        child: const Icon(Icons.add),
      ),
    );
  }
}