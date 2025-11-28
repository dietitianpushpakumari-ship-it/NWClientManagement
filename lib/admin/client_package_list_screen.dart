import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// 🎯 Project Imports
import 'package:nutricare_client_management/modules/client/services/client_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/package/model/package_assignment_model.dart';
import 'package:nutricare_client_management/screens/package_assignment_page.dart';
import 'package:nutricare_client_management/screens/payment_ledger_screen.dart';

enum PackageGroup { active, archived }

PackageGroup getPackageGroup(PackageAssignmentModel assignment) {
  return assignment.isActive ? PackageGroup.active : PackageGroup.archived;
}

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

  // --- Actions ---

  Future<void> _handleArchiveToggle(PackageAssignmentModel assignment) async {
    final bool currentlyActive = assignment.isActive;
    try {
      final updatedAssignment = assignment.copyWith(
        isActive: !currentlyActive,
        isLocked: false,
      );
      await _clientService.updateAssignedPackage(
          clientId: widget.client.id, updatedAssignment: updatedAssignment);

      if (mounted) _showSnackbar('${assignment.packageName} ${currentlyActive ? 'archived' : 'activated'}.', currentlyActive ? Colors.orange : Colors.green);
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', Colors.red);
    }
  }

  Future<void> _toggleLockStatus(PackageAssignmentModel assignment) async {
    try {
      final updatedAssignment = assignment.copyWith(isLocked: !assignment.isLocked);
      await _clientService.updateAssignedPackage(
          clientId: widget.client.id, updatedAssignment: updatedAssignment);
      if (mounted) _showSnackbar('Package ${assignment.isLocked ? 'Unlocked' : 'Locked'}.', Colors.blue);
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', Colors.red);
    }
  }

  Future<void> _handleDelete(PackageAssignmentModel assignment) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Permanently delete this package assignment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _clientService.deleteAssignedPackage(clientId: widget.client.id, packageId: assignment.id);
        if (mounted) _showSnackbar('Package deleted.', Colors.grey);
      } catch (e) {
        if (mounted) _showSnackbar('Error: $e', Colors.red);
      }
    }
  }

  void _navigateToAssignPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageAssignmentPage(
          clientId: widget.client.id,
          clientName: _clientProfile.name,
          onPackageAssignment: () {},
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _navigateToLedger(PackageAssignmentModel assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentLedgerScreen(
          assignment: assignment,
          clientName: _clientProfile.name,
          initialCollectedAmount: 0.0, // Service will fetch actual amount
        ),
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text("Client Packages", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),

                // Package List
                Expanded(
                  child: StreamBuilder<List<PackageAssignmentModel>>(
                    stream: _clientService.streamClientAssignments(widget.client.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final allAssignments = snapshot.data ?? [];

                      final active = allAssignments.where((p) => p.isActive).toList();
                      final archived = allAssignments.where((p) => !p.isActive).toList();

                      if (allAssignments.isEmpty) return _buildEmptyState();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        children: [
                          if (active.isNotEmpty) ...[
                            _buildSectionTitle("Active Subscriptions", Colors.green),
                            ...active.map((p) => _buildPremiumPackageCard(p)),
                          ],

                          if (archived.isNotEmpty) ...[
                            _buildSectionTitle("Archived History", Colors.orange),
                            if (!_isArchiveExpanded)
                              OutlinedButton.icon(
                                onPressed: () => setState(() => _isArchiveExpanded = true),
                                icon: const Icon(Icons.history, size: 18),
                                label: const Text("Show History"),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700),
                              ),
                            if (_isArchiveExpanded)
                              ...archived.map((p) => _buildPremiumPackageCard(p)),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAssignPage,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Package", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPremiumPackageCard(PackageAssignmentModel assignment) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final bool isActive = assignment.isActive;
    final bool isLocked = assignment.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: isActive ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () => _navigateToLedger(assignment),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(isActive ? Icons.card_membership : Icons.archive, color: isActive ? Colors.green.shade700 : Colors.orange.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(assignment.packageName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(
                          "${DateFormat('MMM d, y').format(assignment.purchaseDate)} - ${DateFormat('MMM d, y').format(assignment.expiryDate)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Action Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (val) {
                      if(val == 'ledger') _navigateToLedger(assignment);
                      if(val == 'lock') _toggleLockStatus(assignment);
                      if(val == 'archive') _handleArchiveToggle(assignment);
                      if(val == 'delete') _handleDelete(assignment);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'ledger', child: Row(children: [Icon(Icons.receipt_long, size: 18, color: Colors.blue), SizedBox(width: 10), Text("View Ledger")])),
                      PopupMenuItem(value: 'lock', child: Row(children: [Icon(isLocked ? Icons.lock_open : Icons.lock, size: 18, color: Colors.orange), const SizedBox(width: 10), Text(isLocked ? "Unlock" : "Lock")])),
                      PopupMenuItem(value: 'archive', child: Row(children: [Icon(isActive ? Icons.archive : Icons.unarchive, size: 18, color: Colors.grey), const SizedBox(width: 10), Text(isActive ? "Archive" : "Activate")])),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 12),

              // Footer Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTag(assignment.category.toUpperCase(), Theme.of(context).colorScheme.primary.withOpacity(.8), Theme.of(context).colorScheme.primary.withOpacity(.1)),
                  if(isLocked) _buildTag("LOCKED", Colors.red.shade700, Colors.red.shade50),
                  Text(
                    currencyFormatter.format(assignment.bookedAmount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No packages assigned.", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }
}