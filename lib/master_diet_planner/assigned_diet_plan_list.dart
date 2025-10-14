import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master_diet_planner/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/master_diet_planner/client_diet_plan_model.dart';
import 'package:nutricare_client_management/master_diet_planner/client_diet_plan_service.dart';
import 'package:nutricare_client_management/models/client_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// --- Enums and Utility Functions ---

enum PlanGroup { active, archived, draft }

PlanGroup getPlanGroup(ClientDietPlanModel plan) {
  if (plan.isDeleted)
    return PlanGroup.archived; // Treat soft-deleted as archived history
  if (plan.isActive) return PlanGroup.active;
  if (plan.isArchived) return PlanGroup.archived;
  return PlanGroup.draft; // Default state
}

// --- Main Screen Widget ---

class AssignedDietPlanListScreen extends StatefulWidget {
  final ClientModel client;

  const AssignedDietPlanListScreen({super.key, required this.client});

  @override
  State<AssignedDietPlanListScreen> createState() =>
      _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState
    extends State<AssignedDietPlanListScreen> {
  // 🎯 NEW STATE: Expansion toggles for collapsed groups
  bool _isArchiveExpanded = false;
  bool _isDraftExpanded = false;

  // --- Navigation Handlers ---

  void _navigateToEntryScreen({String? planId}) {
    // Pass the client ID to the entry screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(planId: planId),
      ),
    ); // No need to refresh the list, StreamBuilder handles it
  }

  // For EDITING an existing plan
  void _editPlan(ClientDietPlanModel plan) {
    _navigateToEntryScreen(planId: plan.id);
  }

  // For creating a NEW plan (as a draft)
  void _createNewPlan() {
    _navigateToEntryScreen();
  }

  // --- Core Service Interaction ---

  // 🎯 NEW/UPDATED: Handles the soft delete with confirmation
  void _confirmAndDelete(ClientDietPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete the plan "${plan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ClientDietPlanService().deletePlan(plan.id).catchError((e) {
                // Show error if delete fails
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🎯 NEW: Handles the switch toggle for Active/Archive status
  Future<void> _togglePlanStatus(
    ClientDietPlanModel plan,
    bool newActiveState,
  ) async {
    final service = ClientDietPlanService();

    // Toggle logic: If newActiveState is true, set it active and archive all others.
    // If newActiveState is false, set it archived (and inactive).
    if (newActiveState) {
      await service.reactivatePlan(plan.id);
    } else {
      await service.archivePlan(plan.id);
    }
  }

  // --- Widget Builders ---

  // 🎯 NEW: Builds the list tile wrapped in a Dismissible (Slide-to-Delete)
  Widget _buildPlanTile(
    ClientDietPlanModel plan,
    ClientDietPlanService service,
  ) {
    final bool isActive = getPlanGroup(plan) == PlanGroup.active;
    final bool isArchived = getPlanGroup(plan) == PlanGroup.archived;
    final bool isDraft = getPlanGroup(plan) == PlanGroup.draft;

    // Use Dismissible for Slide-to-Delete
    return Dismissible(
      key: ValueKey(plan.id),
      direction: isArchived || isDraft
          ? DismissDirection.endToStart
          : DismissDirection.none,
      // Only allow deleting Drafts/Archived
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Show confirmation dialog before deleting
          bool shouldDelete =
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Delete'),
                  content: Text(
                    'Are you sure you want to delete "${plan.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldDelete) {
            await service.deletePlan(
              plan.id,
            ); // Assuming this is the hard delete function or soft delete endpoint
          }
          return shouldDelete;
        }
        return false;
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      child: ListTile(
        leading: Icon(
          isActive
              ? Icons.favorite
              : isArchived
              ? Icons.archive
              : Icons.edit,
          color: isActive
              ? Colors.green
              : isArchived
              ? Colors.orange
              : Colors.grey,
        ),
        title: Text(
          plan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Assigned: ${DateFormat('MMM d, y').format(plan.assignedDate!)}',
        ),
        onTap: () => _editPlan(plan),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit Button (always available for non-deleted plans)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade700),
              tooltip: 'Edit Plan Items',
              onPressed: () => _editPlan(plan),
            ),

            // 🎯 NEW: Status Switch (Active/Archive)
            if (!plan.isDeleted) ...[
              const Text('Active'),
              Switch(
                value: isActive,
                onChanged: (bool newValue) => _togglePlanStatus(plan, newValue),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.orange,
                inactiveTrackColor: Colors.orange.shade100,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final clientPlanService = ClientDietPlanService();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.client.name}\'s Assigned Plans')),
      body: StreamBuilder<List<ClientDietPlanModel>>(
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

          // 🎯 Grouping the plans
          final activePlans = allPlans
              .where((p) => getPlanGroup(p) == PlanGroup.active)
              .toList();
          final archivedPlans = allPlans
              .where((p) => getPlanGroup(p) == PlanGroup.archived)
              .toList();
          final draftPlans = allPlans
              .where((p) => getPlanGroup(p) == PlanGroup.draft)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: [
              // 1. ACTIVE PLANS (Always expanded and at the top)
              _buildGroupTile(
                title: 'Active Plan (${activePlans.length})',
                icon: Icons.check_circle,
                color: Colors.green,
                isExpanded: true,
                plans: activePlans,
                service: clientPlanService,
              ),

              // 2. DRAFT PLANS (Collapsible)
              _buildExpansionTile(
                title: 'Drafts (${draftPlans.length})',
                icon: Icons.edit_note,
                color: Colors.grey,
                isExpanded: _isDraftExpanded,
                onExpansionChanged: (expanded) =>
                    setState(() => _isDraftExpanded = expanded),
                plans: draftPlans,
                service: clientPlanService,
              ),

              // 3. ARCHIVED PLANS (Collapsible)
              _buildExpansionTile(
                title: 'Archived Plans (${archivedPlans.length})',
                icon: Icons.archive,
                color: Colors.orange,
                isExpanded: _isArchiveExpanded,
                onExpansionChanged: (expanded) =>
                    setState(() => _isArchiveExpanded = expanded),
                plans: archivedPlans,
                service: clientPlanService,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewPlan,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper for Active Group (always expanded)
  Widget _buildGroupTile({
    required String title,
    required IconData icon,
    required Color color,
    required List<ClientDietPlanModel> plans,
    required ClientDietPlanService service,
    required bool isExpanded,
  }) {
    if (plans.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plans.length,
          itemBuilder: (context, index) =>
              _buildPlanTile(plans[index], service),
        ),
        const Divider(),
      ],
    );
  }

  // Helper for Collapsible Groups (Draft and Archive)
  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
    required List<ClientDietPlanModel> plans,
    required ClientDietPlanService service,
  }) {
    if (plans.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      initiallyExpanded: isExpanded,
      onExpansionChanged: onExpansionChanged,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      children: plans.map((plan) => _buildPlanTile(plan, service)).toList(),
    );
  }
}
