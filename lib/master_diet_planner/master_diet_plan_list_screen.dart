import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'master_diet_plan_entry_page.dart';
import 'master_diet_plan_service.dart';
import 'diet_plan_item_model.dart';

// We'll use the placeholders defined in the service layer
// import '../models/master_diet_plan_model.dart';
// import '../services/master_diet_plan_service.dart';
// Assuming all necessary models/services are available

class MasterDietPlanListScreen extends StatefulWidget {
  const MasterDietPlanListScreen({super.key});

  @override
  State<MasterDietPlanListScreen> createState() => _MasterDietPlanListScreenState();
}

class _MasterDietPlanListScreenState extends State<MasterDietPlanListScreen> {
  Future<List<MasterDietPlanModel>>? _plansFuture;

  @override
  void initState() {
    super.initState();
  //  _loadPlans();
  }

  // Function to reload the list after any action (save, delete, clone)
 /* void _loadPlans() {
    setState(() {
      _plansFuture = MasterDietPlanService().streamAllPlans();
    });
  }*/

  // --- Navigation Handlers ---

  // For creating a NEW template
  void _createNewTemplate() {
    _navigateToEntryScreen();
  }

  // For EDITING an existing template
  void _editTemplate(MasterDietPlanModel plan) {
    _navigateToEntryScreen(planId: plan.id);
  }

  // For CLONING an existing template
  Future<void> _cloneTemplate(MasterDietPlanModel plan) async {
    final clonedPlan = plan.clone();
    // Navigate to the entry screen with the cloned model pre-filled
    _navigateToEntryScreen(initialPlan: clonedPlan);
  }

  // Navigate to the MasterDietPlanEntryPage
  void _navigateToEntryScreen({String? planId, MasterDietPlanModel? initialPlan}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MasterDietPlanEntryPage(
          planId: planId,
          initialPlan: initialPlan,
        ),
      ),
    );
    // Reload list when returning from the entry page
   // _loadPlans();
  }

  // --- Action Handlers ---

  void _confirmDelete(BuildContext context, MasterDietPlanModel plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the template "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteTemplate(plan.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTemplate(String planId) async {
    try {
      await MasterDietPlanService().deletePlan(planId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template deleted successfully!')));
     // _loadPlans();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete template: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<MasterDietPlanService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Diet Templates'),
      ),
      body: StreamBuilder<List<MasterDietPlanModel>>(
          stream: service.streamAllPlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return const Center(
              child: Text('No templates found. Tap the "+" to create one.'),
            );
          }

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plan.description.isEmpty ? 'No description' : plan.description),
                  onTap: () => _editTemplate(plan),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Clone Button
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue.shade700),
                        tooltip: 'Clone Template',
                        onPressed: () => _cloneTemplate(plan),
                      ),
                      // Edit Button
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green.shade700),
                        tooltip: 'Edit Template',
                        onPressed: () => _editTemplate(plan),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Template',
                        onPressed: () => _confirmDelete(context, plan),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}