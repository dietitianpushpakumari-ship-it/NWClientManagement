import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- Internal Imports ---
import 'package:nutricare_client_management/admin/diet_plan_comparasion_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/screens/vitals_history_page.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // Import for firestoreProvider

// Provider
final dietPlanStreamProvider = StreamProvider.family<List<ClientDietPlanModel>, String>((ref, clientId) {
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
  ConsumerState<AssignedDietPlanListScreen> createState() => _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState extends ConsumerState<AssignedDietPlanListScreen> {

  bool _isMarkingComplete = false; // State to track marking completion

  @override
  Widget build(BuildContext context) {
    final dietPlansAsync = ref.watch(dietPlanStreamProvider(widget.clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Diet Plan Management", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: widget.isReadOnly ? [] : [
          IconButton(
            icon: const Icon(Icons.style_outlined, color: Colors.indigo),
            tooltip: "Use Template",
            onPressed: () => _openTemplateSelector(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
            tooltip: "Create Custom",
            onPressed: () => _navigateToCreateCustom(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dietPlansAsync.when(
        data: (plans) {
          if (plans.isEmpty) return _buildEmptyState();

          // 1. Sort: Newest First
          final sortedPlans = List<ClientDietPlanModel>.from(plans)
            ..sort((a, b) {
              final dateA = (a.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              final dateB = (b.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

          // 2. Identify Active Plan (For current Session)
          final currentSessionPlan = IterableExtension(sortedPlans).firstWhereOrNull(
                  (p) => p.sessionId == widget.sessionId && widget.sessionId != null
          );

          // 3. Separate History
          final archivedPlans = sortedPlans.where(
                  (p) => p.sessionId != widget.sessionId || widget.sessionId == null
          ).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: CustomScrollView(
              slivers: [
                // A. ACTIVE PLAN SECTION
                if (currentSessionPlan != null) ...[
                  _buildSliverHeader("CURRENT ACTIVE PLAN", Icons.bolt_rounded, Colors.green),
                  SliverToBoxAdapter(
                    child: _buildPremiumPlanCard(
                      currentSessionPlan,
                      isActiveSession: true,
                      activePlan: currentSessionPlan,
                    ),
                  ),
                ] else if (widget.sessionId != null) ...[
                  SliverToBoxAdapter(child: _buildNoActivePlanNudge()),
                ],

                // B. HISTORY SECTION
                if (archivedPlans.isNotEmpty) ...[
                  SliverToBoxAdapter(child: const SizedBox(height: 32)),
                  _buildSliverHeader("PLAN HISTORY", Icons.history_edu_rounded, Colors.blueGrey),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildPremiumPlanCard(
                        archivedPlans[index],
                        isActiveSession: false,
                        activePlan: currentSessionPlan ?? sortedPlans.first,
                      ),
                      childCount: archivedPlans.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  // --- 🎨 PREMIUM CARDS ---

  Widget _buildPremiumPlanCard(ClientDietPlanModel plan, {required bool isActiveSession, required ClientDietPlanModel activePlan}) {
    final date = (plan.assignedDate as Timestamp?)?.toDate();
    final dateStr = date != null ? DateFormat('dd MMM yyyy').format(date) : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Active Plan gets a subtle colored border/glow
        border: isActiveSession ? Border.all(color: Colors.green.withOpacity(0.3), width: 1.5) : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: isActiveSession ? Colors.green.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => widget.isReadOnly ? _navigateToReport(plan) : _navigateToEdit(plan),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Name + Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActiveSession ? Colors.green.shade50 : Colors.indigo.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActiveSession ? Icons.verified_user_outlined : Icons.description_outlined,
                        color: isActiveSession ? Colors.green.shade700 : Colors.indigo.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Assigned: $dateStr",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // 🎯 Action Menu
                    _buildPlanActionMenu(plan),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Bottom Row: Status + Compare
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    _buildStatusBadge(plan.isProvisional ?? false),

                    // Compare Button (if not comparing with self)
                    if (plan.id != activePlan.id)
                      InkWell(
                        onTap: () => _handleCompare(plan, activePlan),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Icon(Icons.compare_arrows_rounded, size: 14, color: Colors.blue.shade800),
                              const SizedBox(width: 4),
                              Text("COMPARE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                            ],
                          ),
                        ),
                      )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 🧩 COMPONENTS ---

  Widget _buildStatusBadge(bool isProvisional) {
    Color bg = isProvisional ? Colors.orange.shade50 : Colors.teal.shade50;
    Color text = isProvisional ? Colors.orange.shade800 : Colors.teal.shade800;
    String label = isProvisional ? "DRAFT (PROVISIONAL)" : "FINALIZED";
    IconData icon = isProvisional ? Icons.edit_note : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivePlanNudge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
            child: Icon(Icons.design_services_outlined, color: Colors.orange.shade800, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("No Plan Assigned", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("Assign a template or create a custom plan for this session.", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActionMenu(ClientDietPlanModel plan) {
    // Check if this plan is the active plan for the current session
    final bool isSessionPlan = widget.sessionId != null && plan.sessionId == widget.sessionId;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, plan),
      itemBuilder: (context) => [
        _buildMenuItem('view_report', "View Report", Icons.visibility_outlined, Colors.indigo),
        if (!widget.isReadOnly) ...[
          // 🎯 MARK AS COMPLETE OPTION
          if (isSessionPlan)
            _buildMenuItem('mark_complete', "Mark Step Complete", Icons.check_circle, Colors.green),

          _buildMenuItem('edit', "Edit Plan", Icons.edit_outlined, Colors.black87),
          _buildMenuItem('toggle_provisional',
              plan.isProvisional == true ? "Mark as Final" : "Mark as Draft",
              plan.isProvisional == true ? Icons.check_circle_outline : Icons.history_edu,
              plan.isProvisional == true ? Colors.teal : Colors.orange
          ),
          _buildMenuItem('save_master', "Save as Template", Icons.save_as_outlined, Colors.black87),
          if (isSessionPlan)
            _buildMenuItem('delete', "Delete Plan", Icons.delete_outline, Colors.redAccent),
        ]
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
            child: Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.indigo.shade300),
          ),
          const SizedBox(height: 24),
          const Text("No Diet Plans Yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text("Get started by assigning a template or\ncreating a new plan from scratch.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5)
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            children: [
              _buildBigActionButton("Use Template", Icons.copy_all_rounded, Colors.indigo, () => _openTemplateSelector()),
              _buildBigActionButton("Create Custom", Icons.add_circle_outline_rounded, Colors.teal, () => _navigateToCreateCustom(context)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBigActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  // --- 🚀 ACTIONS ---

  void _handleMenuAction(String value, ClientDietPlanModel plan) async {
    switch (value) {
      case 'view_report': _navigateToReport(plan); break;
      case 'edit': _navigateToEdit(plan); break;
      case 'toggle_provisional':
        await ref.read(clientDietPlanServiceProvider).updatePlanProvisionalStatus(
          clientId: widget.clientId,
          planId: plan.id,
          currentStatus: plan.isProvisional ?? false,
        );
        break;
      case 'save_master': _showSaveAsMasterDialog(plan); break;
      case 'delete': _handleDeleteSessionPlan(plan); break;
    // 🎯 Handle Mark Complete
      case 'mark_complete': _markStepAsComplete(); break;
    }
  }

  void _openTemplateSelector() async {
    final bool? assigned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MasterPlanAssignmentSheet(
          client: widget.client,
          sessionId: widget.sessionId,
        ),
      ),
    );

    if (assigned == true) {
      ref.invalidate(dietPlanStreamProvider(widget.clientId));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan assigned successfully"), backgroundColor: Colors.green));
    }
  }

  void _navigateToCreateCustom(BuildContext context) async {
    final plans = ref.read(dietPlanStreamProvider(widget.clientId)).value ?? [];
    final existingSessionPlan = IterableExtension(plans).firstWhereOrNull(
          (p) => p.sessionId == widget.sessionId && p.isProvisional == true,
    );

    if (existingSessionPlan != null) {
      final proceed = await _showReplaceDialog();
      if (proceed != true) return;
      await ref.read(clientDietPlanServiceProvider).deletePlan(existingSessionPlan.id);
    }

    final cycleType = await _showCycleTypeDialog();
    if (cycleType == null) return;

    final meals = await ref.read(masterMealNameServiceProvider).fetchAllMealNames();
    final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();

    final List<MasterDayPlanModel> initialDays = [];
    if (cycleType == PlanCycleType.weekly) {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      for (int i = 0; i < 7; i++) {
        initialDays.add(MasterDayPlanModel(id: 'd${i+1}', dayName: dayNames[i], meals: initialMeals));
      }
    } else {
      initialDays.add(MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals));
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ClientDietPlanEntryPage(
          planId: null,
          initialPlan: ClientDietPlanModel(
            clientId: widget.clientId,
            name: "New Custom Plan",
            days: initialDays,
            isProvisional: true,
            sessionId: widget.sessionId,
          ),
          onMealPlanSaved: () => setState(() {}),
        ),
      ));
    }
  }

  Future<bool?> _showReplaceDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Replace Current Draft?"),
        content: const Text("You already have a draft for this session. Replacing it will delete the existing draft."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("REPLACE")),
        ],
      ),
    );
  }

  Future<PlanCycleType?> _showCycleTypeDialog() {
    return showDialog<PlanCycleType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Plan Cycle"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PlanCycleType.singleDay),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Single Day (Fixed)")),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, PlanCycleType.weekly),
            child: const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Weekly (7 Days)")),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(ClientDietPlanModel plan) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ClientDietPlanEntryPage(
        sessionId: widget.sessionId,
        initialPlan: plan,
        onMealPlanSaved: () => setState(() {}),
      ),
    ));
  }

  void _navigateToReport(ClientDietPlanModel plan) {
    final vitalsAsync = ref.read(vitalsHistoryStreamProvider(widget.clientId));
    vitalsAsync.whenData((vitalsList) {
      final sessionVitals = IterableExtension(vitalsList).firstWhereOrNull(
            (v) => v.sessionId == plan.sessionId && plan.sessionId != null,
      ) ?? (vitalsList.isNotEmpty ? vitalsList.first : null);

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlanReportViewScreen(
          plan: plan,
          client: widget.client,
          vitals: sessionVitals,
          isMasterPreview: true,
        ),
      ));
    });
  }

  void _handleCompare(ClientDietPlanModel oldPlan, ClientDietPlanModel activePlan) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => DietPlanComparisonScreen(activePlan: activePlan, oldPlan: oldPlan, clientId: widget.clientId),
    ));
  }

  void _showSaveAsMasterDialog(ClientDietPlanModel plan) {
    final controller = TextEditingController(text: plan.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Save as Template"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Template Name", border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              await ref.read(clientDietPlanServiceProvider).saveClientPlanAsMaster(plan, controller.text);
              if(mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Master Library")));
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteSessionPlan(ClientDietPlanModel plan) async {
    if (widget.isReadOnly) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Draft?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(clientDietPlanServiceProvider).deletePlan(plan.id);
      ref.invalidate(dietPlanStreamProvider(widget.clientId));
    }
  }

  // 🎯 IMPLEMENTATION: MARK STEP COMPLETE
  Future<void> _markStepAsComplete() async {
    if (widget.sessionId == null || _isMarkingComplete) return;

    setState(() => _isMarkingComplete = true);

    try {
      // Update session step in Firestore
      await ref.read(firestoreProvider)
          .collection('consultation_sessions')
          .doc(widget.sessionId)
          .update({
        'steps.plan': true, // Mark plan step as true
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diet Plan step marked as complete!"), backgroundColor: Colors.green));
        Navigator.pop(context); // Optional: Return to checklist
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error marking complete: $e")));
    } finally {
      if (mounted) setState(() => _isMarkingComplete = false);
    }
  }
}