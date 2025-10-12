// lib/screens/master_diet_plan_list_screen.dart

import 'package:flutter/material.dart';
// Note: Assuming these imports are correct based on your file structure


import 'diet_plan_item_model.dart';
import 'master_diet_plan_entry_page.dart' hide MasterDietPlanModel, MasterDietPlanService;
import 'master_diet_plan_service.dart'; // Import the page you already have

class MasterDietPlanListScreen extends StatefulWidget {
  const MasterDietPlanListScreen({super.key});

  @override
  State<MasterDietPlanListScreen> createState() => _MasterDietPlanListScreenState();
}

class _MasterDietPlanListScreenState extends State<MasterDietPlanListScreen> {
  final MasterDietPlanService _planService = MasterDietPlanService();
  final DependencyServices _services = DependencyServices();
  late Future<List<MasterDietPlanModel>> _plansFuture;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  // Method to reload the list of plans
  void _fetchPlans() {
    setState(() {
      _plansFuture = _planService.fetchAllPlans();
    });
  }

  // --- NAVIGATION & ACTIONS ---

  // 1. Navigate to Create New Plan
  void _navigateToCreatePlan() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MasterDietPlanEntryPage(),
      ),
    );
    // Reload if a new plan was created/saved
    if (result == true) _fetchPlans();
  }

  // 2. Navigate to Edit/View Plan
  void _navigateToEditPlan(MasterDietPlanModel plan) async {
    //final result = await Navigator.of(context).push(
     // MaterialPageRoute(
        //builder: (context) => MasterDietPlanEntryPage(planToEdit: plan),
      //),
   // );
    // Reload if the plan was updated/saved
   // if (result == true) _fetchPlans();
  }

  // 3. Delete Plan
  void _deletePlan(String planId, String planName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the plan: "$planName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting plan...')));
              try {
                await _planService.deletePlan(planId);
                // After successful deletion, refresh the list
                _fetchPlans();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan "$planName" deleted successfully.')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete plan: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Diet Plans (List)'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      // --- List View ---
      body: FutureBuilder<List<MasterDietPlanModel>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading plans: ${snapshot.error}'));
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return const Center(child: Text('No master plans found. Start by creating one!'));
          }

          // List of Plans
          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.purple),
                  title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    plan.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🎯 VIEW/EDIT Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit/View Plan Details',
                        onPressed: () => _navigateToEditPlan(plan),
                      ),
                      // 🎯 DELETE Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Plan',
                        onPressed: () => _deletePlan(plan.id, plan.name),
                      ),
                    ],
                  ),
                  // Tap the whole tile to View/Edit
                  onTap: () => _navigateToEditPlan(plan),
                ),
              );
            },
          );
        },
      ),
      // --- Floating Action Button for Create ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePlan,
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }
}