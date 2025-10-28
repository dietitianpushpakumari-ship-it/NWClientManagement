import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for FieldValue
// 🎯 NOTE: Service and Model stubs are defined below for compilation
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/modules/client/model/client_model.dart';


class MasterPlanSelectionPage extends StatefulWidget {
  final ClientModel client;
  final VoidCallback onMasterPlanAssigned;

  const MasterPlanSelectionPage({
    super.key,
    required this.client,
    required this.onMasterPlanAssigned,
  });

  @override
  State<MasterPlanSelectionPage> createState() =>
      _MasterPlanSelectionPageState();
}

class _MasterPlanSelectionPageState extends State<MasterPlanSelectionPage> {
  // Use initialized services (assuming they are set up in the main app)
  final MasterDietPlanService _masterService = MasterDietPlanService();
  final ClientDietPlanService _clientService = ClientDietPlanService();

  String? _selectedCategoryId;
  List<String>? _activeFilterIds;

  // --- Assignment Logic ---

  Future<void> _togglePlanAssignment(
      MasterDietPlanModel masterPlan, bool isCurrentlyAssigned) async {
    try {
      if (isCurrentlyAssigned) {
        await _clientService.unassignPlanFromClient(
          clientId: widget.client.id,
          masterPlanId: masterPlan.id,
        );
      } else {
        await _clientService.assignPlanToClient(
          clientId: widget.client.id,
          masterPlan: masterPlan,
        );
      }

      widget.onMasterPlanAssigned();

      if (mounted) {
        final action = isCurrentlyAssigned ? 'unassigned' : 'assigned';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${masterPlan.name} successfully $action.',
            ),
            backgroundColor: isCurrentlyAssigned ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmToggle(
      BuildContext dialogContext,
      MasterDietPlanModel plan,
      bool isCurrentlyAssigned,
      ) {
    final actionText = isCurrentlyAssigned ? 'UNASSIGN' : 'ASSIGN';
    final actionColor = isCurrentlyAssigned ? Colors.red : Colors.green.shade700;

    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: Text('$actionText Plan'),
        content: Text(
          'Are you sure you want to $actionText the template "${plan.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _togglePlanAssignment(plan, isCurrentlyAssigned);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
            ),
            child: Text(
              actionText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Builders ---

  Widget _buildGroupHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPlanListItem(
      BuildContext context, MasterDietPlanModel plan, bool isAssigned) {
    final buttonColor = isAssigned ? Colors.red.shade700 : Colors.green.shade700;
    final buttonLabel = isAssigned ? 'Unassign' : 'Assign';
    final buttonIcon = isAssigned ? Icons.cancel : Icons.send;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      child: ListTile(
        title: Text(
          plan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(plan.description),
        trailing: ElevatedButton.icon(
          onPressed: () => _confirmToggle(context, plan, isAssigned),
          icon: Icon(buttonIcon, size: 18),
          label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: This assumes DietPlanCategoryService is provided higher up in the widget tree
    final _categoryService = Provider.of<DietPlanCategoryService>(context, listen: false);

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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: StreamBuilder<List<DietPlanCategory>>(
              stream: _categoryService.streamAllActive(),
              builder: (context, snapshot) {
                // ... (Category dropdown logic remains the same) ...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                final categories = snapshot.data ?? [];

                // Placeholder logic to update filter:
                if (_selectedCategoryId != null && categories.any((c) => c.id == _selectedCategoryId)) {
                  // Logic to update _activeFilterIds if needed
                }

                final dropdownItems = [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map(
                        (category) => DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.enName),
                    ),
                  ),
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
                    });
                  },
                );
              },
            ),
          ),

          // 🎯 COMBINED MASTER PLAN LISTS (Grouped)
          Expanded(
            child: StreamBuilder<List<MasterDietPlanModel>>(
              // 1. Stream all master plans based on the category filter
              stream: _masterService.streamAllPlansByCategoryIds(
                categoryIds: _activeFilterIds,
              ),
              builder: (context, masterPlansSnapshot) {
                if (masterPlansSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (masterPlansSnapshot.hasError) {
                  return Center(
                    child: Text('Error loading templates: ${masterPlansSnapshot.error}'),
                  );
                }

                final allPlans = masterPlansSnapshot.data ?? [];

                // 2. Stream all assigned plan IDs for the current client
                return StreamBuilder<List<String>>(
                  stream: _clientService.streamAssignedPlanIds(widget.client.id),
                  initialData: const [],
                  builder: (context, assignedIdsSnapshot) {
                    final assignedIds = assignedIdsSnapshot.data?.toSet() ?? {};

                    // 3. Separate plans into assigned and unassigned groups
                    final assignedPlans = allPlans
                        .where((plan) => assignedIds.contains(plan.id))
                        .toList();
                    final unassignedPlans = allPlans
                        .where((plan) => !assignedIds.contains(plan.id))
                        .toList();

                    // 4. Combine all list items into a single scrollable list
                    return ListView(
                      children: [
                        // --- Assigned Plans Group ---
                        if (assignedPlans.isNotEmpty) ...[
                          _buildGroupHeader('Assigned Plans (${assignedPlans.length})', Colors.red[900]!),
                          ...assignedPlans
                              .map((plan) => _buildPlanListItem(context, plan, true))
                              .toList(),
                          const Divider(),
                        ],

                        // --- Unassigned Plans Group ---
                        _buildGroupHeader('Available Plans (${unassignedPlans.length})', Colors.green[900]!),
                        if (unassignedPlans.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('All plans are currently assigned or no plans match the filter.'),
                            ),
                          )
                        else
                          ...unassignedPlans
                              .map((plan) => _buildPlanListItem(context, plan, false))
                              .toList(),
                        const SizedBox(height: 20),
                      ],
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