// lib/screens/supplementation_master_screen.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/supplement_master_entry_dialog.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';

class SupplementationMasterScreen extends StatefulWidget {
  const SupplementationMasterScreen({super.key});

  @override
  State<SupplementationMasterScreen> createState() => _SupplementationMasterScreenState();
}

class _SupplementationMasterScreenState extends State<SupplementationMasterScreen> {
  final SupplimentMasterService _service = SupplimentMasterService();
  late Future<List<SupplimentMasterModel>> _supplementationFuture;

  @override
  void initState() {
    super.initState();
    _loadSupplementations();
  }

  void _loadSupplementations() {
    setState(() {
      _supplementationFuture = _service.fetchAllSupplimentMaster();
    });
  }

  // --- CRUD HANDLERS ---

  void _addSupplementation() async {
    final result = await showDialog<SupplimentMasterModel>(
      context: context,
      builder: (context) => const SupplementationMasterEntryDialog(),
    );

    if (result != null) {
      _loadSupplementations(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.enName} added successfully!')),
      );
    }
  }

  void _editSupplementation(SupplimentMasterModel supplementation) async {
    final result = await showDialog<SupplimentMasterModel>(
      context: context,
      builder: (context) => SupplementationMasterEntryDialog(supplementation: supplementation),
    );

    if (result != null) {
      _loadSupplementations(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.enName} updated successfully!')),
      );
    }
  }

  void _deleteSupplementation(String id) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleting...')),
    );

    try {
      await _service.deleteSupplementation(id);
      _loadSupplementations(); // Refresh the list after successful deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplementation deleted successfully!')),
      );
    } catch (e) {
      _loadSupplementations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete supplementation: $e')),
      );
    }
  }

  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplementation Master'),
      ),
      body: FutureBuilder<List<SupplimentMasterModel>>(
        future: _supplementationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No supplementations found. Tap + to add one.'));
          }

          final supplementations = snapshot.data!;

          return ListView.builder(
            itemCount: supplementations.length,
            itemBuilder: (context, index) {
              final supplementation = supplementations[index];

              // Swipe-to-Delete Implementation
              return Dismissible(
                key: ValueKey(supplementation.id),
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
                      content: Text('Are you sure you want to delete "${supplementation.enName}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  _deleteSupplementation(supplementation.id);
                },
                child: ListTile(
                  // Added Leading Icon 💊
                  leading: const Icon(Icons.medication_outlined, color: Colors.green),
                  title: Text(supplementation.enName),
                  subtitle: Text('ID: ${supplementation.id}'),
                  // Edit Functionality
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editSupplementation(supplementation),
                  ),
                  onTap: () => _editSupplementation(supplementation),
                ),
              );
            },
          );
        },
      ),
      // Add Functionality
      floatingActionButton: FloatingActionButton(
        onPressed: _addSupplementation,
        child: const Icon(Icons.add),
      ),
    );
  }
}