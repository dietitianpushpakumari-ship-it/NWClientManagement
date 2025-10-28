// lib/screens/investigation_master_screen.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/investigation_master_entry_dialog.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';
// 🎯 ADJUST THESE IMPORTS TO YOUR PROJECT STRUCTURE

class InvestigationMasterScreen extends StatefulWidget {
  const InvestigationMasterScreen({super.key});

  @override
  State<InvestigationMasterScreen> createState() => _InvestigationMasterScreenState();
}

class _InvestigationMasterScreenState extends State<InvestigationMasterScreen> {
  final InvestigationMasterService _service = InvestigationMasterService();
  late Future<List<InvestigationMasterModel>> _investigationFuture;

  @override
  void initState() {
    super.initState();
    _loadInvestigations();
  }

  void _loadInvestigations() {
    setState(() {
      _investigationFuture = _service.fetchAllInvestigationMaster();
    });
  }

  // --- CRUD HANDLERS ---

  void _addInvestigation() async {
    final result = await showDialog<InvestigationMasterModel>(
      context: context,
      builder: (context) => const InvestigationMasterEntryDialog(),
    );

    if (result != null) {
      _loadInvestigations(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.enName} added successfully!')),
      );
    }
  }

  void _editInvestigation(InvestigationMasterModel investigation) async {
    final result = await showDialog<InvestigationMasterModel>(
      context: context,
      builder: (context) => InvestigationMasterEntryDialog(investigation: investigation),
    );

    if (result != null) {
      _loadInvestigations(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.enName} updated successfully!')),
      );
    }
  }

  void _deleteInvestigation(String id) async {
    // Optimistic UI update before actual deletion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting...')),
    );

    try {
      await _service.deleteInvestigation(id);
      _loadInvestigations(); // Refresh the list after successful deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Investigation deleted successfully!')),
      );
    } catch (e) {
      // If deletion fails, reload the list to restore the item
      _loadInvestigations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete investigation: $e')),
      );
    }
  }

  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investigation Master'),
      ),
      body: FutureBuilder<List<InvestigationMasterModel>>(
        future: _investigationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No investigations found. Tap + to add one.'));
          }

          final investigations = snapshot.data!;

          return ListView.builder(
            itemCount: investigations.length,
            itemBuilder: (context, index) {
              final investigation = investigations[index];

              // 🎯 Swipe-to-Delete Implementation
              return Dismissible(
                key: ValueKey(investigation.id), // Unique key is mandatory
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: Text('Are you sure you want to delete "${investigation.enName}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteInvestigation(investigation.id);
                },
                child: ListTile(
                  leading: const Icon(Icons.science, color: Colors.indigo),
                  title: Text(investigation.enName),
                  // 🎯 Edit Functionality
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editInvestigation(investigation),
                  ),
                  onTap: () => _editInvestigation(investigation), // Also edit on tap
                ),
              );
            },
          );
        },
      ),
      // 🎯 Add Functionality
      floatingActionButton: FloatingActionButton(
        onPressed: _addInvestigation,
        child: const Icon(Icons.add),
      ),
    );
  }
}