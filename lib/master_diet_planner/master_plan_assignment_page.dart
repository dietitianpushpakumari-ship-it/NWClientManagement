// lib/screens/master_plan_selection_page.dart (REVISED & FIXED)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/master_diet_planner/client_diet_plan_service.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master_diet_planner/master_diet_plan_service.dart';
import 'package:nutricare_client_management/meal_planner/models/diet_plan_category.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/models/client_model.dart';
import 'package:provider/provider.dart';


class MasterPlanSelectionPage extends StatefulWidget {
  final ClientModel client;

  const MasterPlanSelectionPage({super.key, required this.client});

  @override
  State<MasterPlanSelectionPage> createState() => _MasterPlanSelectionPageState();
}

class _MasterPlanSelectionPageState extends State<MasterPlanSelectionPage> {
  final MasterDietPlanService _masterService = MasterDietPlanService();
  final ClientDietPlanService _clientService = ClientDietPlanService();


  String? _selectedCategoryId;
  String _selectedCategoryName = 'All Categories';
  List<String>? _activeFilterIds;

  // 🎯 FIX 1: Removed BuildContext context from the signature.
  // We will now use the State object's implicit 'context' property.
  Future<void> _assignPlan(MasterDietPlanModel masterPlan) async {
    try {
      // NOTE: Assuming assignPlanToClient is the correct method name based on your file
      await _clientService.assignPlanToClient(
        clientId: widget.client.id,
        masterPlan: masterPlan,
      );

      // Check if the widget is still mounted before using the State's context
      if (mounted) {
        // Success feedback uses the safe State's context
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${masterPlan.name} successfully assigned to ${widget.client.name}!'),
          backgroundColor: Colors.green,
        ));

        // Navigation uses the safe State's context
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      // Check mounted again for the error snackbar
      if (mounted) {
        // Error feedback uses the safe State's context
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Assignment failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Confirmation Dialog
  void _confirmAssignment(BuildContext dialogContext, MasterDietPlanModel plan) {
    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Assignment'),
        content: Text('Are you sure you want to assign the template "${plan.name}" to ${widget.client.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(), // Use dialog context to close dialog
              child: const Text('Cancel')
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog using the dialog's context
              // 🎯 FIX 2: Call the function without passing the unsafe dialog context
              _assignPlan(plan);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            child: const Text('Assign Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: If you are using Provider.of, ensure the service is provided higher up the tree.
    final _categoryService = Provider.of<DietPlanCategoryService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Plan to ${widget.client.name}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // FILTER WIDGET
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: StreamBuilder<List<DietPlanCategory>>(
              // NOTE: Assuming streamAllActive() returns a non-nullable stream
              stream: _categoryService.streamAllActive() ,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data ?? [];

                final dropdownItems = [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories (${categories.length + 1})'),
                  ),
                  ...categories.map((category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.enName),
                  )),
                ];

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by Diet Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  value: _selectedCategoryId,
                  items: dropdownItems,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategoryId = newValue;
                      _activeFilterIds = newValue == null ? null : [newValue];
                      _selectedCategoryName = categories.firstWhere(
                              (c) => c.id == newValue,
                          orElse: () => const DietPlanCategory(id: '', enName: 'All Categories')
                      ).enName;
                    });
                  },
                );
              },
            ),
          ),

          // MASTER PLAN LIST (Filtered)
          Expanded(
            child: StreamBuilder<List<MasterDietPlanModel>>(
              stream: _masterService.streamAllPlansByCategoryIds(categoryIds: _activeFilterIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading templates: ${snapshot.error}'));
                }

                final plans = snapshot.data ?? [];

                if (plans.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('No Master Plans found for "$_selectedCategoryName".', style: const TextStyle(fontSize: 16, color: Colors.red)),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(plan.description),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _confirmAssignment(context, plan),
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Assign'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}