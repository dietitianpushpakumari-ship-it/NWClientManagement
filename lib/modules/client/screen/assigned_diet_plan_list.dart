import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/admin/diet_plan_comparasion_screen.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';

// --- Project Imports ---
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assigned_diet_plan_entry_screen.dart';
import 'package:nutricare_client_management/modules/client/screen/master_plan_assignment_page.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
final dietPlanStreamProvider = StreamProvider.family<List<ClientDietPlanModel>, String>((ref, clientId) {
  final service = ref.watch(clientDietPlanServiceProvider);
  return service.streamAllNonDeletedPlansForClient(clientId);
});

class AssignedDietPlanListScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final ClientModel client;

  const AssignedDietPlanListScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.client,
  });

  @override
  ConsumerState<AssignedDietPlanListScreen> createState() => _AssignedDietPlanListScreenState();
}

class _AssignedDietPlanListScreenState extends ConsumerState<AssignedDietPlanListScreen> {
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
        actions: [
          // Choice 1: The previous behavior (Use Template)
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: "Use Template",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MasterPlanAssignmentSheet(
                     client: widget.client,
                  ),
                ),
              );
            },
          ),
          // Choice 2: The new custom behavior (Create Own)
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Create Custom Plan",
            onPressed: () => _navigateToCreateCustom(context),
          ),
        ],
      ),
      body: dietPlansAsync.when(
        data: (plans) {
          if (plans.isEmpty) return _buildEmptyState();

          // 🎯 Sorting logic with explicit casting
          final sortedPlans = List<ClientDietPlanModel>.from(plans)
            ..sort((a, b) {
              final DateTime dateA = (a.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              final DateTime dateB = (b.assignedDate as Timestamp?)?.toDate() ?? DateTime(2000);
              return dateB.compareTo(dateA);
            });

          final primaryPlan = sortedPlans.first;
          final archivedPlans = sortedPlans.skip(1).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTrendMiniChart(sortedPlans), // 🎯 Added Trend Visual
              const SizedBox(height: 20),
              _buildSectionHeader("ACTIVE DIET PLAN", Icons.bolt, Colors.green),
              _buildPlanCard(primaryPlan, isActive: true, activePlan: primaryPlan),

              if (archivedPlans.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSectionHeader("ARCHIVED HISTORY", Icons.history, Colors.blueGrey),
                const SizedBox(height: 8),
                ...archivedPlans.map((plan) => _buildPlanCard(plan, isActive: false, activePlan: primaryPlan)).toList(),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  // 🎯 Visual: Mini Trend Chart for Weight across plans
  Widget _buildTrendMiniChart(List<ClientDietPlanModel> plans) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Weight Progress Across Plans", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: plans.take(5).map((p) => Column(
              children: [
                Text("${p.targetWeightKg ?? '--'}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('MMM').format((p.assignedDate as Timestamp?)?.toDate() ?? DateTime.now()),
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            )).toList().reversed.toList(),
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
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ClientDietPlanModel plan, {required bool isActive, required ClientDietPlanModel activePlan}) {
    final cardColor = isActive ? Colors.white : Colors.grey.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.indigo.withOpacity(0.3) : Colors.grey.shade200),
        boxShadow: isActive ? [BoxShadow(color: Colors.indigo.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(plan.name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.blueGrey)),
            subtitle: Text("Created: ${DateFormat('dd MMM yyyy').format((plan.assignedDate as Timestamp?)?.toDate() ?? DateTime.now())}"),
            trailing: isActive ? const Icon(Icons.verified, color: Colors.green) : null,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isActive)
                  TextButton.icon(
                    onPressed: () => _openComparison(plan, activePlan),
                    icon: const Icon(Icons.compare, size: 16),
                    label: const Text("Compare"),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange.shade900),
                  )
                else
                  const SizedBox(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: Colors.indigo),
                      onPressed: () => _handleDuplicate(plan),
                      tooltip: "Duplicate",
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.indigo),
                      onPressed: () => _navigateToEdit(plan),
                      tooltip: "Edit",
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // lib/modules/client/screen/assigned_diet_plan_list.dart

  void _navigateToCreateCustom(BuildContext context) async {
    // 1. Show the Cycle Selector dialog (Weekly vs. Single Day)
    final cycleType = await showDialog<PlanCycleType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Plan Type"),
        content: const Text("Would you like to create a fixed daily plan or a 7-day weekly schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, PlanCycleType.singleDay), child: const Text("Single Day")),
          ElevatedButton(onPressed: () => Navigator.pop(context, PlanCycleType.weekly), child: const Text("Weekly")),
        ],
      ),
    );

    if (cycleType == null) return;

    // 2. Resolve the Future to get the actual List of meal names
    // 🎯 THE FIX: Use 'await' here so 'meals' becomes a List, not a Future
    final meals = await ref.read(masterMealNameServiceProvider).fetchAllMealNames();

    // 3. Now you can safely use .map() on the resolved List
    final initialMeals = meals.map((m) => DietPlanMealModel(
        id: m.id,
        mealNameId: m.id,
        mealName: m.name,
        items: [],
        order: m.order
    )).toList();

    // 4. Initialize days based on cycle selection
    final List<MasterDayPlanModel> initialDays = [];
    if (cycleType == PlanCycleType.weekly) {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      for (int i = 0; i < 7; i++) {
        initialDays.add(MasterDayPlanModel(id: 'd${i+1}', dayName: dayNames[i], meals: initialMeals));
      }
    } else {
      initialDays.add(MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals));
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => ClientDietPlanEntryPage(
      //clientId: widget.clientId,
      initialPlan: plan,onMealPlanSaved: () {
      // 🎯 This triggers a UI refresh when the dietitian returns
      setState(() {});
    },
    )));
  }

  Future<void> _handleDuplicate(ClientDietPlanModel plan) async {
    try {
      await ref.read(clientDietPlanServiceProvider).duplicatePlan(plan);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plan duplicated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _openComparison(ClientDietPlanModel oldPlan, ClientDietPlanModel activePlan) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => DietPlanComparisonScreen(
      activePlan: activePlan,
      oldPlan: oldPlan,
      clientName: widget.clientName,
    )));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_meals_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No diet plans found."),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _navigateToCreateCustom(context), child: const Text("Create Custom Plan")),
        ],
      ),
    );
  }
}