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
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

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
    final actionColor =
    isCurrentlyAssigned ? Colors.red : Colors.green.shade700;

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

  Widget _buildGroupHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanListItem(
      BuildContext context, MasterDietPlanModel plan, bool isAssigned) {
    final buttonColor =
    isAssigned ? Colors.red.shade50 : Colors.green.shade50;
    final buttonTextColor =
    isAssigned ? Colors.red.shade700 : Colors.green.shade700;
    final buttonLabel = isAssigned ? 'Unassign' : 'Assign';
    final buttonIcon = isAssigned ? Icons.remove_circle_outline : Icons.add_circle_outline;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Status Badge
                if (isAssigned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                plan.description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmToggle(context, plan, isAssigned),
                icon: Icon(buttonIcon, size: 18, color: buttonTextColor),
                label: Text(buttonLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: buttonTextColor,
                  backgroundColor: buttonColor,
                  side: BorderSide(color: buttonTextColor.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _categoryService =
    Provider.of<DietPlanCategoryService>(context, listen: false);

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Assign Meal Template'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- FILTER WIDGET ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: StreamBuilder<List<DietPlanCategory>>(
                    stream: _categoryService.streamAllActive(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator(minHeight: 2);
                      }
                      final categories = snapshot.data ?? [];

                      final dropdownItems = [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories', style: TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        ...categories.map(
                              (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.enName),
                          ),
                        ),
                      ];

                      return DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          // 🎯 FIX 1: Added isExpanded: true to prevent overflow
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Diet Category',
                            border: InputBorder.none,
                            icon: Icon(Icons.filter_list, color: Colors.indigo),
                          ),
                          value: _selectedCategoryId,
                          items: dropdownItems,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategoryId = newValue;
                              _activeFilterIds =
                              newValue == null ? null : [newValue];
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // --- PLAN LISTS ---
            Expanded(
              child: StreamBuilder<List<MasterDietPlanModel>>(
                stream: _masterService.streamAllPlansByCategoryIds(
                  categoryIds: _activeFilterIds,
                ),
                builder: (context, masterPlansSnapshot) {
                  if (masterPlansSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (masterPlansSnapshot.hasError) {
                    return Center(
                      child: Text(
                          'Error loading templates: ${masterPlansSnapshot.error}'),
                    );
                  }

                  final allPlans = masterPlansSnapshot.data ?? [];

                  return StreamBuilder<List<String>>(
                    stream:
                    _clientService.streamAssignedPlanIds(widget.client.id),
                    initialData: const [],
                    builder: (context, assignedIdsSnapshot) {
                      final assignedIds =
                          assignedIdsSnapshot.data?.toSet() ?? {};

                      final assignedPlans = allPlans
                          .where((plan) => assignedIds.contains(plan.id))
                          .toList();
                      final unassignedPlans = allPlans
                          .where((plan) => !assignedIds.contains(plan.id))
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          // --- Assigned Plans Group ---
                          if (assignedPlans.isNotEmpty) ...[
                            _buildGroupHeader(
                                'Currently Assigned (${assignedPlans.length})',
                                Colors.indigo.shade700,
                                Icons.check_circle),
                            ...assignedPlans
                                .map((plan) =>
                                _buildPlanListItem(context, plan, true))
                                .toList(),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                              child: Divider(),
                            ),
                          ],

                          // --- Unassigned Plans Group ---
                          _buildGroupHeader(
                              'Available Templates (${unassignedPlans.length})',
                              Colors.grey.shade800,
                              Icons.dashboard_customize),

                          if (unassignedPlans.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'No matching plans found.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...unassignedPlans
                                .map((plan) =>
                                _buildPlanListItem(context, plan, false))
                                .toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}