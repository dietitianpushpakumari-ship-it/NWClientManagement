import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart'; // For PDF Logic if needed
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';

// --- Enums and Utility Functions ---

enum PlanGroup { active, archived, draft }

PlanGroup getPlanGroup(ClientDietPlanModel plan) {
  if (plan.isDeleted) return PlanGroup.archived;
  if (plan.isActive) return PlanGroup.active;
  if (plan.isArchived) return PlanGroup.archived;
  return PlanGroup.draft;
}

// --- Main Screen Widget ---

class AssignedDietPlanListScreen extends StatefulWidget {
  final ClientModel client;
  final VoidCallback onMealPlanSaved;

  const AssignedDietPlanListScreen({
    super.key,
    required this.client,
    required this.onMealPlanSaved,
  });

  @override
  State<AssignedDietPlanListScreen> createState() =>
      _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState
    extends State<AssignedDietPlanListScreen> {
  bool _isArchiveExpanded = false;
  bool _isDraftExpanded = true; // Default expand drafts for easier access

  // --- Navigation/Action Handlers ---

  void _navigateToEntryScreen({String? planId, ClientDietPlanModel? plan}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          planId: planId,
          initialPlan: plan,
          onMealPlanSaved: widget.onMealPlanSaved,
        ),
      ),
    );
  }

  void _editPlan(ClientDietPlanModel plan) {
    _navigateToEntryScreen(planId: plan.id, plan: plan);
  }

  void _createNewPlan() {
    _navigateToEntryScreen();
  }

  void _viewPlanReport(ClientDietPlanModel plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PlanReportViewScreen(client: widget.client, plan: plan),
      ),
    );
  }

  // Toggle Freeze/Ready Status
  Future<void> _toggleReadyStatus(
      ClientDietPlanModel plan,
      ClientDietPlanService service,
      ) async {
    final bool isReady = plan.isReadyToDeliver;
    final String action = isReady ? 'Unfreezing' : 'Freezing';
    final String status = isReady ? 'Unfrozen' : 'Ready to Deliver';

    try {
      final updatedPlan = plan.copyWith(isReadyToDeliver: !isReady);
      await service.savePlan(updatedPlan);
      widget.onMealPlanSaved();

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan $status successfully.'),
            backgroundColor: isReady ? Colors.orange.shade700 : Colors.blue.shade700,
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete/Archive Confirmation
  Future<void> _confirmAndDelete(
      ClientDietPlanModel plan,
      ClientDietPlanService service,
      ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete the plan "${plan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
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
        await service.deletePlan(plan.id);
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan deleted successfully.')),
          );
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Toggle Active/Archive Status
  Future<void> _togglePlanStatus(
      ClientDietPlanModel plan,
      bool newActiveState,
      ) async {
    final service = ClientDietPlanService();

    try {
      final updatedPlan = plan.copyWith(
        isActive: newActiveState,
        isArchived: !newActiveState,
      );
      await service.savePlan(updatedPlan);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newActiveState ? 'Plan set as Active.' : 'Plan Archived.',
            ),
            backgroundColor: newActiveState
                ? Colors.green.shade700
                : Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update plan status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Widget Builders ---

  // 🎯 REVAMPED PLAN CARD
  Widget _buildPlanCard(
      ClientDietPlanModel plan,
      ClientDietPlanService service,
      PlanGroup group,
      ) {
    final bool isActive = group == PlanGroup.active;
    final bool isReady = plan.isReadyToDeliver;

    // Theme Colors based on status
    final Color accentColor = isActive
        ? Colors.green.shade700
        : (group == PlanGroup.archived ? Colors.orange.shade800 : Colors.grey.shade700);
    final Color cardBgColor = isActive ? Colors.green.shade50 : Colors.white;

    return Dismissible(
      key: ValueKey(plan.id),
      direction: group != PlanGroup.active ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _confirmAndDelete(plan, service);
          return false;
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_forever, color: Colors.red),
      ),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accentColor.withOpacity(0.3), width: 1),
        ),
        color: cardBgColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP ROW: Title & Status Icon ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isActive ? Icons.check_circle : (isReady ? Icons.lock : Icons.edit_note),
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assigned: ${DateFormat('MMM d, y').format(plan.assignedDate ?? DateTime.now())}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isReady)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'READY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // --- BOTTOM ROW: Action Buttons ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side Actions
                  Row(
                    children: [
                      // Freeze/Ready
                      IconButton(
                        icon: Icon(
                          isReady ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                          color: isReady ? Colors.orange : Colors.grey,
                          size: 22,
                        ),
                        tooltip: isReady ? 'Unfreeze Plan' : 'Freeze Plan',
                        onPressed: () => _toggleReadyStatus(plan, service),
                      ),
                      // Edit
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.indigo, size: 22),
                        tooltip: 'Edit Plan',
                        onPressed: () => _editPlan(plan),
                      ),
                      // View
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: Colors.blue, size: 22),
                        tooltip: 'View Report',
                        onPressed: () => _viewPlanReport(plan),
                      ),
                    ],
                  ),

                  // Right Side Actions (Status Switch)
                  if (!plan.isDeleted)
                    Row(
                      children: [
                        Text(
                          isActive ? 'Active' : 'Archived',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (val) => _togglePlanStatus(plan, val),
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.grey,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientPlanService = ClientDietPlanService();

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Assigned Plans'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ClientDietPlanModel>>(
          stream: clientPlanService.streamAllNonDeletedPlansForClient(
            widget.client.id,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading plans: ${snapshot.error}'),
              );
            }

            final allPlans = snapshot.data ?? [];

            // Grouping
            final activePlans = allPlans
                .where((p) => getPlanGroup(p) == PlanGroup.active)
                .toList();
            final archivedPlans = allPlans
                .where((p) => getPlanGroup(p) == PlanGroup.archived)
                .toList();
            final draftPlans = allPlans
                .where((p) => getPlanGroup(p) == PlanGroup.draft)
                .toList();

            if (allPlans.isEmpty) {
              return const Center(child: Text("No diet plans assigned yet."));
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB if added later
              children: [
                // 1. ACTIVE PLANS
                if (activePlans.isNotEmpty) ...[
                  _buildHeader('Active Plans', Colors.green.shade800),
                  ...activePlans.map((plan) =>
                      _buildPlanCard(plan, clientPlanService, PlanGroup.active)),
                ],

                // 2. DRAFT PLANS
                if (draftPlans.isNotEmpty) ...[
                  _buildHeader('Drafts', Colors.blueGrey.shade700, isCollapsible: true,
                      isExpanded: _isDraftExpanded,
                      onExpand: (val) => setState(() => _isDraftExpanded = val)),

                  if (_isDraftExpanded)
                    ...draftPlans.map((plan) =>
                        _buildPlanCard(plan, clientPlanService, PlanGroup.draft)),
                ],

                // 3. ARCHIVED PLANS
                if (archivedPlans.isNotEmpty) ...[
                  _buildHeader('Archived History', Colors.orange.shade800, isCollapsible: true,
                      isExpanded: _isArchiveExpanded,
                      onExpand: (val) => setState(() => _isArchiveExpanded = val)),

                  if (_isArchiveExpanded)
                    ...archivedPlans.map((plan) =>
                        _buildPlanCard(plan, clientPlanService, PlanGroup.archived)),
                ],
              ],
            );
          },
        ),
      ),
      // Floating Action Button (Optional, if you want creating new plans from here)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewPlan,
        icon: const Icon(Icons.add),
        label: const Text("New Plan"),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  // Simple Section Header
  Widget _buildHeader(String title, Color color, {bool isCollapsible = false, bool isExpanded = true, Function(bool)? onExpand}) {
    if (isCollapsible) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpand,
          title: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          leading: Icon(Icons.folder_open, color: color),
          // We handle children in the main ListView to prevent nesting scroll views
          children: const [],
          trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: color),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Icon(Icons.star, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}