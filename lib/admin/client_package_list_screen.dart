import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

// 🎯 STUB IMPORTS: Replace with your actual project paths
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';

// --- Enums and Utility Functions ---

enum PackageGroup { active, archived }

PackageGroup getPackageGroup(PackageAssignmentModel assignment) {
  return assignment.isActive ? PackageGroup.active : PackageGroup.archived;
}

// --- Main Screen Widget ---

class ClientPackageListScreen extends StatefulWidget {
  final ClientModel client;

  const ClientPackageListScreen({super.key, required this.client});

  @override
  State<ClientPackageListScreen> createState() =>
      _ClientPackageListScreenState();
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

  Future<void> _handleArchiveToggle(PackageAssignmentModel assignment) async {
    final bool currentlyActive = assignment.isActive;
    final String action = currentlyActive ? 'Archiving' : 'Activating';

    try {
      final updatedAssignment = assignment.copyWith(
        isActive: !currentlyActive,
        isLocked: false,
      );

      await _clientService.updateAssignedPackage(
          clientId: widget.client.id, updatedAssignment: updatedAssignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${assignment.packageName} successfully ${currentlyActive ? 'archived' : 'set as active'}.'),
            backgroundColor: currentlyActive
                ? Colors.orange.shade700
                : Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$action failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDelete(PackageAssignmentModel assignment) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to permanently delete the package assignment for "${assignment.packageName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
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
        await _clientService.deleteAssignedPackage(
            clientId: widget.client.id, packageId: assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Package assignment deleted successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to delete package: $e'),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  void _navigateToAssignPage() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => PackageAssignmentPage(
          clientId: widget.client.id,
          clientName: _clientProfile.name,
          onPackageAssignment: () {},
        ),
      ),
    )
        .then((_) => setState(() {}));
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
      await _clientService.updateAssignedPackage(
          clientId: widget.client.id, updatedAssignment: updatedAssignment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Package ${assignment.packageName} ${isLocked ? 'Unlocked' : 'Locked'} successfully.'),
            backgroundColor:
            isLocked ? Colors.orange.shade700 : Colors.blue.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$action failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Widget Builders ---

  // 🎯 REVAMPED PACKAGE CARD
  Widget _buildAssignmentCard(PackageAssignmentModel assignment) {
    final bool isLocked = assignment.isLocked;
    final bool isActive = getPackageGroup(assignment) == PackageGroup.active;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Theme Colors
    final Color statusColor = isActive ? Colors.green.shade700 : Colors.orange.shade800;
    final Color lightStatusColor = isActive ? Colors.green.shade50 : Colors.orange.shade50;
    final IconData statusIcon = isActive ? Icons.check_circle : Icons.archive;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPaymentLedger(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: lightStatusColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.packageName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assigned: ${DateFormat('MMM d, y').format(assignment.purchaseDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        if (assignment.category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              assignment.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(assignment.bookedAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      if (isLocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 12, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text('LOCKED', style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),

              // --- Action Buttons Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lock Toggle
                  TextButton.icon(
                    icon: Icon(
                      isLocked ? Icons.lock_open : Icons.lock_outline,
                      size: 20,
                      color: isLocked ? Colors.green : Colors.grey.shade700,
                    ),
                    label: Text(isLocked ? 'Unlock' : 'Lock'),
                    onPressed: () => _toggleLockStatus(assignment),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade800),
                  ),

                  // Archive Toggle
                  TextButton.icon(
                    icon: Icon(
                      isActive ? Icons.archive_outlined : Icons.unarchive_outlined,
                      size: 20,
                      color: isActive ? Colors.orange : Colors.green,
                    ),
                    label: Text(isActive ? 'Archive' : 'Activate'),
                    onPressed: () => _handleArchiveToggle(assignment),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade800),
                  ),

                  // Delete
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Assignment',
                    onPressed: () => _handleDelete(assignment),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 REVAMPED SECTION HEADER (Collapsible)
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required int count,
  }) {
    if (count == 0 && title.contains("Active")) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            '$title ($count)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          // Children are handled in the main list view to avoid nesting scrolls
          children: const [],
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Package Assignments'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<PackageAssignmentModel>>(
          stream: _clientService.streamClientAssignments(widget.client.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading packages: ${snapshot.error}'));
            }

            final allAssignments = snapshot.data ?? [];

            final activeAssignments = allAssignments
                .where((p) => getPackageGroup(p) == PackageGroup.active)
                .toList();
            final archivedAssignments = allAssignments
                .where((p) => getPackageGroup(p) == PackageGroup.archived)
                .toList();

            if (allAssignments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      "No packages assigned yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToAssignPage,
                      icon: const Icon(Icons.add),
                      label: const Text("Assign New Package"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              children: [
                // --- ACTIVE PACKAGES ---
                if (activeAssignments.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Active Packages',
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade800,
                    isExpanded: true,
                    onExpansionChanged: (_) {},
                    count: activeAssignments.length,
                  ),
                  ...activeAssignments.map(_buildAssignmentCard),
                ],

                const SizedBox(height: 10),

                // --- ARCHIVED PACKAGES ---
                if (archivedAssignments.isNotEmpty) ...[
                  _buildSectionHeader(
                    title: 'Archived History',
                    icon: Icons.history,
                    color: Colors.orange.shade800,
                    isExpanded: _isArchiveExpanded,
                    onExpansionChanged: (expanded) => setState(() => _isArchiveExpanded = expanded),
                    count: archivedAssignments.length,
                  ),
                  if (_isArchiveExpanded)
                    ...archivedAssignments.map(_buildAssignmentCard),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAssignPage,
        icon: const Icon(Icons.add),
        label: const Text("New Package"),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}