// lib/screens/diet_plan_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_service.dart';

import '../models/diet_plan_assignment_model.dart';


// NOTE: Placeholder for the page used for creating a new assignment
class DietPlanAssignmentPage extends StatelessWidget {
  final String clientId;
  final String clientName;
  const DietPlanAssignmentPage({super.key, required this.clientId, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Diet Plan')),
      body: const Center(child: Text('Diet Plan Assignment Form Placeholder')),
    );
  }
}


class DietPlanHistoryPage extends StatefulWidget {
  final String clientId;
  final String clientName;

  const DietPlanHistoryPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<DietPlanHistoryPage> createState() => _DietPlanHistoryPageState();
}

class _DietPlanHistoryPageState extends State<DietPlanHistoryPage> {
  late Future<List<DietPlanAssignmentModel>> _assignmentsFuture;
  final DietPlanService _service = DietPlanService();

  @override
  void initState() {
    super.initState();
    _assignmentsFuture = _loadAssignments();
  }

  Future<List<DietPlanAssignmentModel>> _loadAssignments() {
    return _service.getClientAssignments(widget.clientId);
  }

  // --- NAVIGATION AND REFRESH ---

  void _navigateAndRefresh(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => page));
    // Refresh the list when returning from the Entry/Edit page
    setState(() {
      _assignmentsFuture = _loadAssignments();
    });
  }

  // --- DELETE ACTION (Soft Delete via Swipe) ---

  void _deleteRecord(DietPlanAssignmentModel assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete the plan "${assignment.masterPlanName}"? This action is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.softDeleteAssignment(assignment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan assignment deleted successfully (soft-deleted).')),
          );
          // Refresh the list immediately after successful deletion
          setState(() {
            _assignmentsFuture = _loadAssignments();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete plan: $e')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName}\'s Diet Plans'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<DietPlanAssignmentModel>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading plans: ${snapshot.error}'));
          }
          final assignments = snapshot.data ?? [];
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No diet plans assigned to this client yet.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _navigateAndRefresh(DietPlanAssignmentPage(
                      clientId: widget.clientId,
                      clientName: widget.clientName,
                    )),
                    icon: const Icon(Icons.add),
                    label: const Text('Assign First Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final assignment = assignments[index];
              final isActive = assignment.isActive;
              final Color statusColor = isActive ? Colors.green.shade700 : Colors.red.shade700;

              return Dismissible(
                key: Key(assignment.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  // The actual deletion is handled in the _deleteRecord confirmation dialog
                  // This is a common pattern to avoid accidental deletion on swipe alone.
                },
                confirmDismiss: (direction) async {
                  // Show the confirmation dialog before dismissing
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: Text('Do you want to permanently delete the assignment for "${assignment.masterPlanName}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                            _deleteRecord(assignment); // Execute soft delete
                          },
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: Icon(
                      Icons.restaurant_menu,
                      color: statusColor,
                      size: 30,
                    ),
                    title: Text(
                      assignment.masterPlanName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Start: ${DateFormat.yMMMd().format(assignment.startDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Expiry: ${DateFormat.yMMMd().format(assignment.expiryDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'EXPIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                          onPressed: () => _service.editAssignment(assignment),
                        ),
                      ],
                    ),
                    onTap: () => _service.editAssignment(assignment),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Floating button to ASSIGN a new package
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(DietPlanAssignmentPage(
            clientId: widget.clientId,
            clientName: widget.clientName,
          ));
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
        tooltip: 'Assign New Diet Plan',
      ),
    );
  }
}