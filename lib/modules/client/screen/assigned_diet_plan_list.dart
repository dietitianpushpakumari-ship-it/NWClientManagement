import 'dart:ffi';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/admin/diet_plan_comparasion_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';

// --- Project Imports ---
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';

final dietPlanStreamProvider =
    StreamProvider.family<List<ClientDietPlanModel>, String>((ref, clientId) {
      final service = ref.watch(clientDietPlanServiceProvider);
      return service.streamAllNonDeletedPlansForClient(clientId);
    });

class AssignedDietPlanListScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final ClientModel client;
  final String? sessionId;
  final bool isReadOnly;

  const AssignedDietPlanListScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.client,
    this.sessionId,
    required this.isReadOnly
  });

  @override
  ConsumerState<AssignedDietPlanListScreen> createState() =>
      _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState
    extends ConsumerState<AssignedDietPlanListScreen> {

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX: Accessing the provider correctly via ref.watch
    final dietPlansAsync = ref.watch(dietPlanStreamProvider(widget.clientId));



    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Diet Plan History"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
         actions: widget.isReadOnly ? [] : [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: "Use Template",
            onPressed: () async {
              // 🎯 Catch the 'true' result from the assignment sheet
              final bool? assigned = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => MasterPlanAssignmentSheet(
                    client: widget.client,
                    sessionId: widget.sessionId, // Pass the active session ID
                  ),
                ),
              );

              // 🎯 Force the provider to refresh if a new plan was assigned
              if (assigned == true) {
                ref.invalidate(dietPlanStreamProvider(widget.clientId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Diet plan successfully updated."),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Create Custom Plan",
            onPressed: () => _navigateToCreateCustom(context),
          ),
        ],
      ),
      // lib/modules/client/screen/assigned_diet_plan_list.dart

      // lib/modules/client/screen/assigned_diet_plan_list.dart

      body: dietPlansAsync.when(
        data: (plans) {
          if (plans.isEmpty) return _buildEmptyState();

          // 1. Sort plans chronologically
          final sortedPlans = List<ClientDietPlanModel>.from(plans)
            ..sort((a, b) {
              final DateTime dateA = (a.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              final DateTime dateB = (b.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

          // 2. Logic: Separate current session plan
          final currentSessionPlan = IterableExt(sortedPlans).firstWhereOrNull(
                  (p) => p.sessionId == widget.sessionId && widget.sessionId != null
          );

          final archivedPlans = sortedPlans.where(
                  (p) => p.sessionId != widget.sessionId || widget.sessionId == null
          ).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),

              // 3. Active Session Plan
              if (currentSessionPlan != null) ...[
                _buildSectionHeader("ACTIVE SESSION PLAN", Icons.bolt, Colors.green),
                _buildPlanCard(
                  currentSessionPlan,
                  isActive: true,
                  activePlan: currentSessionPlan,
                ),
              ] else if (widget.sessionId != null) ...[
                _buildNoActivePlanNudge(),
              ],

              // 4. Past History
              if (archivedPlans.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSectionHeader("PAST SESSION HISTORY", Icons.history, Colors.blueGrey),
                const SizedBox(height: 8),
                ...archivedPlans.map(
                      (plan) => _buildPlanCard(
                    plan,
                    isActive: false,
                    activePlan: currentSessionPlan ?? sortedPlans.first,
                  ),
                ),
              ],
            ],
          );
        },
        // 🎯 THE FIX: Add these required handlers
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text("Error loading diet plans: $err", style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildNoActivePlanNudge() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "No plan assigned for this session yet. Use a template or create custom.",
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // lib/modules/client/screen/assigned_diet_plan_list.dart

  Widget _buildPlanCard(ClientDietPlanModel plan, {required bool isActive, required ClientDietPlanModel activePlan}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final vitalsAsync = ref.read(vitalsHistoryStreamProvider(widget.clientId));

          vitalsAsync.whenData((vitalsList) {
            final sessionVitals = IterableExt(vitalsList).firstWhereOrNull(
                  (v) => v.sessionId == plan.sessionId && plan.sessionId != null,
            ) ?? (vitalsList.isNotEmpty ? vitalsList.first : null);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanReportViewScreen(
                  plan: plan,
                  client: widget.client,
                  vitals: sessionVitals,
                  isMasterPreview: true,
                ),
              ),
            );
          });
        },
        child: Column(
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.description_outlined, color: Colors.indigo),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🎯 1. RESTORED: Compare Button (Historical Analysis)
                  _buildCompareButton(plan,activePlan),
                  const SizedBox(width: 8),
                  // 🎯 Status Badge: Provisional vs Final
                  _buildStatusBadge(plan.isProvisional ?? false),
                ],
              ),
              subtitle: Text("Session: ${plan.sessionId?.substring(0, 8) ?? 'N/A'}..."),
              trailing:  widget.isReadOnly ? null :PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit': _navigateToEdit(plan); break;
                    case 'toggle_provisional': await ref.read(clientDietPlanServiceProvider).updatePlanProvisionalStatus(
                      clientId: widget.clientId,
                      planId: plan.id,
                      currentStatus: plan.isProvisional ?? false,
                    );

                    // Optional: Add a subtle feedback for the user
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(plan.isProvisional ?? false ? "Plan finalized" : "Plan marked as provisional"),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                    break; // 🎯 Toggle logic
                    case 'save_master': _showSaveAsMasterDialog(plan); break;
                    case 'delete': _handleDeleteSessionPlan(plan); break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text("Edit Plan"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  // 🎯 New Option: Change Status
                  PopupMenuItem(
                    value: 'toggle_provisional',
                    child: ListTile(
                      leading: Icon(
                        plan.isProvisional ?? false ? Icons.verified_outlined : Icons.pending_actions_outlined,
                        color: plan.isProvisional ?? false ? Colors.green : Colors.orange,
                      ),
                      title: Text(plan.isProvisional ?? false ? "Mark as Final" : "Mark as Provisional"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'save_master',
                    child: ListTile(
                      leading: Icon(Icons.drive_file_move_outlined),
                      title: Text("Save to Library"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (!widget.isReadOnly ?? false && plan.sessionId == widget.sessionId)
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline, color: Colors.red),
                        title: Text("Delete Draft", style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareButton(ClientDietPlanModel oldPlan, ClientDietPlanModel activePlan) {
    return InkWell(
      onTap: () => _handleCompare(oldPlan, activePlan), // 🎯 Passing both parameters
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              "COMPARE",
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
            ),
          ],
        ),
      ),
    );
  }
// 🎯 Helper for the visual badge
  Widget _buildStatusBadge(bool isProvisional) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isProvisional ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isProvisional ? Colors.orange.shade200 : Colors.green.shade200,
          width: 0.5,
        ),
      ),
      child: Text(
        isProvisional ? "PROVISIONAL" : "FINAL",
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: isProvisional ? Colors.orange.shade900 : Colors.green.shade900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showSaveAsMasterDialog(ClientDietPlanModel plan) {
    final controller = TextEditingController(text: plan.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save to Master Library"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Template Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(clientDietPlanServiceProvider)
                  .saveClientPlanAsMaster(plan, controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Template added to Master Library"),
                ),
              );
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  // lib/modules/client/screen/assigned_diet_plan_list.dart

  void _navigateToCreateCustom(BuildContext context) async {
    // 1. Show the Cycle Selector dialog (Weekly vs. Single Day)

    final plans = ref.read(dietPlanStreamProvider(widget.clientId)).value ?? [];
    final existingSessionPlan = IterableExt(plans).firstWhereOrNull(
      (p) => p.sessionId == widget.sessionId && p.isProvisional == true,
    );
    if (existingSessionPlan != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Replace Current Draft?"),
          content: const Text(
            "You already have a custom draft for this session. Creating a new one will replace it. Continue?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("REPLACE"),
            ),
          ],
        ),
      );
      if (proceed != true) return;

      // Hard-delete the previous session draft to make room for the new one
      await ref
          .read(clientDietPlanServiceProvider)
          .deletePlan(existingSessionPlan.id);
    }

    final cycleType = await showDialog<PlanCycleType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Plan Type"),
        content: const Text(
          "Would you like to create a fixed daily plan or a 7-day weekly schedule?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, PlanCycleType.singleDay),
            child: const Text("Single Day"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, PlanCycleType.weekly),
            child: const Text("Weekly"),
          ),
        ],
      ),
    );

    if (cycleType == null) return;

    // 2. Resolve the Future to get the actual List of meal names
    // 🎯 THE FIX: Use 'await' here so 'meals' becomes a List, not a Future
    final meals = await ref
        .read(masterMealNameServiceProvider)
        .fetchAllMealNames();

    // 3. Now you can safely use .map() on the resolved List
    final initialMeals = meals
        .map(
          (m) => DietPlanMealModel(
            id: m.id,
            mealNameId: m.id,
            mealName: m.name,
            items: [],
            order: m.order,
          ),
        )
        .toList();

    // 4. Initialize days based on cycle selection
    final List<MasterDayPlanModel> initialDays = [];
    if (cycleType == PlanCycleType.weekly) {
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      for (int i = 0; i < 7; i++) {
        initialDays.add(
          MasterDayPlanModel(
            id: 'd${i + 1}',
            dayName: dayNames[i],
            meals: initialMeals,
          ),
        );
      }
    } else {
      initialDays.add(
        MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals),
      );
    }

    // 5. Navigate to the entry page with the fully initialized structure
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDietPlanEntryPage(
            planId: null,
            initialPlan: ClientDietPlanModel(
              clientId: widget.clientId,
              name: "New Custom Plan",
              days: initialDays,
              isProvisional: true,
            ),
            onMealPlanSaved: () => setState(() {}),
          ),
        ),
      );
    }
  }

  void _navigateToEdit(ClientDietPlanModel plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          //clientId: widget.clientId,
          sessionId: widget.sessionId,
          initialPlan: plan,
          onMealPlanSaved: () {
            // 🎯 This triggers a UI refresh when the dietitian returns
            setState(() {});
          },
        ),
      ),
    );
  }



  void _handleCompare(
    ClientDietPlanModel oldPlan,
    ClientDietPlanModel activePlan,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietPlanComparisonScreen(
          activePlan: activePlan,
          oldPlan: oldPlan,
          clientId: widget.clientId,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Colors.indigo.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Design Session Plan",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1C1E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Choose a starting point for this consultation.\nYou can replace your draft at any time before finalizing.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey.shade400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _buildSelectionCard(
            title: "Select from Master Templates",
            subtitle: "Instant setup using clinical templates",
            icon: Icons.style_outlined,
            color: Colors.indigo,
            onTap: () => MasterPlanAssignmentSheet.showAssignmentSheet(
              context,
              widget.client,
              widget.sessionId,
            ),
          ),
          const SizedBox(height: 16),
          _buildSelectionCard(
            title: "Architect Custom Plan",
            subtitle: "Build a bespoke schedule from scratch",
            icon: Icons.architecture_rounded,
            color: Colors.teal,
            onTap: () => _navigateToCreateCustom(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.blueGrey.shade300,
            ),
          ],
        ),
      ),
    );
  }

// lib/modules/client/screen/assigned_diet_plan_list.dart

  Future<void> _handleDeleteSessionPlan(ClientDietPlanModel plan) async {
    if (widget.isReadOnly ?? false) return; // 🎯 Final safety check

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Session Draft?"),
        content: const Text("This plan will be permanently removed from this session. You can then create a new custom plan or use a template."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 🎯 Hard delete from services to clear the session slot
        await ref.read(clientDietPlanServiceProvider).deletePlan(plan.id);

        // Invalidate stream to show Empty State (Create Custom/Use Template)
        ref.invalidate(dietPlanStreamProvider(widget.clientId));

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Draft removed. You can now start a new plan."))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
