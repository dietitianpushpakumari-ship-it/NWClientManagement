import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/diet_plan_pdf_generator.dart'
    hide ClientModel;
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';

import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';

import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
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
  VoidCallback onMealPlanSaved;

  AssignedDietPlanListScreen({
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
  bool _isDraftExpanded = false;

  // --- Navigation/Action Handlers ---

  void _navigateToEntryScreen({String? planId, ClientDietPlanModel? plan}) {
    // NOTE: Assuming AssignedDietPlanEntryScreen is the correct entry point
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          planId: planId,
          initialPlan: plan,
          onMealPlanSaved: () {},
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

  // 🎯 NEW: Navigate to the Plan Report View screen
  void _viewPlanReport(ClientDietPlanModel plan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PlanReportViewScreen(client: widget.client, plan: plan),
      ),
    );
  }

  // 🎯 NEW IMPLEMENTATION: Toggle Freeze/Ready Status
  Future<void> _toggleReadyStatus(
    ClientDietPlanModel plan,
    ClientDietPlanService service,
  ) async {
    final bool isReady = plan.isReadyToDeliver;
    final String action = isReady ? 'Unfreezing' : 'Freezing';
    final String status = isReady ? 'Unfrozen' : 'Ready to Deliver (Frozen)';

    try {
      final updatedPlan = plan.copyWith(isReadyToDeliver: !isReady);

      await service.savePlan(
        updatedPlan,
      ); // Assuming service has a savePlan method
      widget.onMealPlanSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan $status successfully.'),
          backgroundColor: isReady
              ? Colors.orange.shade700
              : Colors.blue.shade700,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$action failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 識 IMPLEMENTATION: Delete/Archive Confirmation (UNCHANGED)
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
        await service.deletePlan(
          plan.id,
        ); // Assuming service has a deletePlan method
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 識 IMPLEMENTATION: Toggle Active/Archive Status (UNCHANGED)
  Future<void> _togglePlanStatus(
    ClientDietPlanModel plan,
    bool newActiveState,
  ) async {
    final service = ClientDietPlanService(); // Instantiate the service

    try {
      // 1. Create a copy with the updated status flags
      final updatedPlan = plan.copyWith(
        isActive: newActiveState,
        isArchived:
            !newActiveState, // If active, it's not archived, and vice-versa.
      );

      // 2. Save the updated plan to Firestore
      await service.savePlan(updatedPlan);

      // 3. Show confirmation message
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update plan status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 識 PDF SHARE FUNCTION (Moved to PlanReportViewScreen, kept here as stub for completeness)
  Future<void> _exportPlanToPdf(ClientDietPlanModel plan) async {
    // This is now handled in PlanReportViewScreen
  }

  // --- Widget Builders ---

  // UPDATED: _buildPlanTile now includes Freeze and View buttons
  Widget _buildPlanTile(
    ClientDietPlanModel plan,
    ClientDietPlanService service,
  ) {
    final bool isActive = getPlanGroup(plan) == PlanGroup.active;
    final bool isArchived = getPlanGroup(plan) == PlanGroup.archived;
    final bool isDraft = getPlanGroup(plan) == PlanGroup.draft;
    final bool isReady = plan.isReadyToDeliver;

    return Dismissible(
      key: ValueKey(plan.id),
      // Only allow swipe to delete for Archived or Drafts
      direction: isArchived || isDraft
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _confirmAndDelete(plan, service);
          return false;
        }
        return false;
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      child: Card(
          elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 👈 No rounded corners
        ),

          child: ListTile(


        leading: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
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
            // 🎯 NEW: Freeze indicator icon (Lock)
            if (isReady)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.blue.shade700,
                  size: 14,
                ),
              ),
          ],
        ),
        title: Column(

          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            plan.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              // 🎯 Add a visual cue if frozen
              color: isReady ? Colors.blue.shade800 : null,
            ),),

            Text(
              'Assigned: ${DateFormat('MMM d, y').format(plan.assignedDate ?? DateTime.now())}',
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎯 NEW: Freeze/Ready Button
                IconButton(
                  icon: Icon(
                    isReady ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                    color: isReady ? Colors.orange.shade700 : Colors.redAccent.shade700,
                  ),
                  tooltip: isReady
                      ? 'Unfreeze / Unready'
                      : 'Freeze / Ready to Deliver',
                  onPressed: () => _toggleReadyStatus(plan, service),
                ),

                // 🎯 NEW: View Report Button
                IconButton(
                  icon: Icon(Icons.description, color: Colors.blueAccent.shade700),
                  tooltip: 'View Report',
                  onPressed: () => _viewPlanReport(plan),
                ),

                // Edit Button (always available)
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.indigo.shade700),
                  tooltip: 'Edit Plan Items',
                  onPressed: () => _editPlan(plan),
                ),

                // Status Switch (Active/Archive)
                if (!plan.isDeleted) ...[
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


          ],),

       // subtitle:
        onTap: () => _editPlan(plan),
      //  trailing:
      ),),
    );
  }

  // --- MAIN BUILD METHOD (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    final clientPlanService = ClientDietPlanService();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.client.name}\'s Assigned Plans'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,),
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

          // Grouping the plans
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
              // 1. ACTIVE PLANS (Always expanded)
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
      /*floatingActionButton: FloatingActionButton(
        onPressed: _createNewPlan,
        child: const Icon(Icons.add),
      ),*/
    );
  }

  // Helper Widget for Active Group (always expanded)
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
