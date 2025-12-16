import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';

class AssignedDietPlanListScreen extends ConsumerStatefulWidget {
  final ClientModel client;
  final VoidCallback onMealPlanSaved;

  const AssignedDietPlanListScreen({
    super.key,
    required this.client,
    required this.onMealPlanSaved,
  });

  @override
  ConsumerState<AssignedDietPlanListScreen> createState() => _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState extends ConsumerState<AssignedDietPlanListScreen> {
  bool _isArchiveExpanded = false;

  // --- ACTIONS ---

  void _openPlanDetail(ClientDietPlanModel plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          planId: plan.id,
          initialPlan: plan,
          onMealPlanSaved: widget.onMealPlanSaved,
        ),
      ),
    );
  }

  void _createNewPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          onMealPlanSaved: widget.onMealPlanSaved,
        ),
      ),
    );
  }

  void _viewReport(ClientDietPlanModel plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlanReportViewScreen(client: widget.client, plan: plan),
      ),
    );
  }

  Future<void> _setAsPrimary(ClientDietPlanModel plan) async {
    try {
      await ref.read(clientDietPlanServiceProvider).setAsPrimary(widget.client.id, plan.id);
      widget.onMealPlanSaved();
      if (mounted) _showSnackbar('Plan "${plan.name}" is now Primary.', Colors.green);
    } catch (e) {
      if (mounted) _showSnackbar('Failed to set primary: $e', Colors.red);
    }
  }

  Future<void> _toggleLock(ClientDietPlanModel plan) async {
    try {
      final newStatus = !plan.isReadyToDeliver;
      final updated = plan.copyWith(isReadyToDeliver: newStatus);
      await ref.read(clientDietPlanServiceProvider).savePlan(updated);
      widget.onMealPlanSaved();
      if (mounted) _showSnackbar(newStatus ? 'Plan Locked.' : 'Plan Unlocked for editing.', Colors.blue);
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', Colors.red);
    }
  }

  Future<void> _toggleProvisional(ClientDietPlanModel plan) async {
    try {
      await ref.read(clientDietPlanServiceProvider).toggleProvisional(plan.id, plan.isProvisional);
      widget.onMealPlanSaved();
      if (mounted) _showSnackbar(plan.isProvisional ? 'Marked as Final.' : 'Marked as Provisional.', Colors.orange);
    } catch (e) {
      if (mounted) _showSnackbar('Error: $e', Colors.red);
    }
  }

  Future<void> _deletePlan(ClientDietPlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("This will move the plan to archived history. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          )
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(clientDietPlanServiceProvider).deletePlan(plan.id);
        widget.onMealPlanSaved();
        if (mounted) _showSnackbar('Plan deleted.', Colors.grey);
      } catch (e) {
        if (mounted) _showSnackbar('Error: $e', Colors.red);
      }
    }
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 20)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      const Text("Diet Plans", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    ],
                  ),
                ),

                // Plan List
                Expanded(
                  child: StreamBuilder<List<ClientDietPlanModel>>(
                    stream: ref.watch(clientDietPlanServiceProvider).streamAllNonDeletedPlansForClient(widget.client.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final allPlans = snapshot.data ?? [];

                      if (allPlans.isEmpty) return _buildEmptyState();

                      // Grouping
                      final primaryPlan = allPlans.where((p) => p.isActive).toList();
                      final otherPlans = allPlans.where((p) => !p.isActive && !p.isArchived).toList();
                      final archivedPlans = allPlans.where((p) => p.isArchived).toList();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        children: [
                          if (primaryPlan.isNotEmpty) ...[
                            _buildSectionTitle("Primary Plan (Active)", Colors.green),
                            _buildPlanCard(primaryPlan.first, isPrimary: true),
                          ],

                          if (otherPlans.isNotEmpty) ...[
                            _buildSectionTitle("Drafts & Others", Colors.blueGrey),
                            ...otherPlans.map((p) => _buildPlanCard(p)),
                          ],

                          if (archivedPlans.isNotEmpty) ...[
                            _buildSectionTitle("Archive", Colors.orange),
                            if (!_isArchiveExpanded)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.history, size: 18),
                                label: const Text("Show Archived Plans"),
                                onPressed: () => setState(() => _isArchiveExpanded = true),
                              ),
                            if (_isArchiveExpanded)
                              ...archivedPlans.map((p) => _buildPlanCard(p)),
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
        onPressed: _createNewPlan,
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Plan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPlanCard(ClientDietPlanModel plan, {bool isPrimary = false}) {
    final isLocked = plan.isReadyToDeliver;
    final isProvisional = plan.isProvisional;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: isPrimary ? Border.all(color: Colors.green.withOpacity(0.5), width: 1.5) : null,
      ),
      child: InkWell(
        onTap: () => _openPlanDetail(plan),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary ? Colors.green.shade50 : (isLocked ? Colors.blue.shade50 : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPrimary ? Icons.star : (isLocked ? Icons.lock : Icons.edit_note),
                  color: isPrimary ? Colors.green.shade700 : (isLocked ? Colors.blue.shade700 : Colors.orange.shade700),
                ),
              ),
              title: Text(
                plan.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                "Created: ${DateFormat('MMM d, y').format(plan.assignedDate ?? DateTime.now())}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              // 🎯 ACTION MENU
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (val) {
                  switch(val) {
                    case 'setPrimary': _setAsPrimary(plan); break;
                    case 'toggleProvisional': _toggleProvisional(plan); break;
                    case 'toggleLock': _toggleLock(plan); break;
                    case 'preview': _viewReport(plan); break;
                    case 'print': _viewReport(plan); break;
                    case 'delete': _deletePlan(plan); break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isPrimary)
                    const PopupMenuItem(value: 'setPrimary', child: Row(children: [Icon(Icons.check_circle_outline, size: 18, color: Colors.green), SizedBox(width: 10), Text("Set as Primary")])),

                  PopupMenuItem(
                      value: 'toggleProvisional',
                      child: Row(children: [
                        Icon(isProvisional ? Icons.verified : Icons.timelapse, size: 18, color: Colors.orange),
                        const SizedBox(width: 10),
                        Text(isProvisional ? "Mark as Final" : "Mark as Provisional")
                      ])
                  ),

                  PopupMenuItem(
                      value: 'toggleLock',
                      child: Row(children: [
                        Icon(isLocked ? Icons.lock_open : Icons.lock, size: 18, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(isLocked ? "Unlock Plan" : "Lock Plan")
                      ])
                  ),

                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'preview', child: Row(children: [Icon(Icons.visibility, size: 18, color: Colors.grey), SizedBox(width: 10), Text("Preview")])),
                  const PopupMenuItem(value: 'print', child: Row(children: [Icon(Icons.print, size: 18, color: Colors.grey), SizedBox(width: 10), Text("Print / PDF")])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete")])),
                ],
              ),
            ),

            // Status Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (isPrimary) _buildTag("PRIMARY", Colors.green.shade700, Colors.green.shade50),
                  _buildTag(isProvisional ? "PROVISIONAL" : "FINAL",
                      isProvisional ? Colors.orange.shade800 : Colors.teal.shade800,
                      isProvisional ? Colors.orange.shade50 : Colors.teal.shade50
                  ),
                  if (isLocked) _buildTag("LOCKED", Colors.blue.shade700, Colors.blue.shade50),

                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color text, Color bg) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text)),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No diet plans assigned yet.", style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Tap '+ New Plan' to create one.", style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}