// lib/widgets/SupplementationMultiSelectDialog.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';

// Dialog for creating a new master record
class SupplementationMasterCreationDialog extends StatefulWidget {
  const SupplementationMasterCreationDialog({super.key});

  @override
  State<SupplementationMasterCreationDialog> createState() => _SupplementationMasterCreationDialogState();
}

class _SupplementationMasterCreationDialogState extends State<SupplementationMasterCreationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  void _saveSupplementation() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final unitToSave = _controller.text.trim();

      try {
        final uniqueId = DateTime.now().microsecondsSinceEpoch.toString();

        // Replace with actual API call to save new record
        await Future.delayed(const Duration(milliseconds: 50));
        final itemToSave = SupplimentMasterModel(
          id:  uniqueId,
          isDeleted:  false,
          enName: unitToSave,
        );
        final newRecord = await SupplimentMasterService().addOrUpdateSupplimentMaster(itemToSave);
        if (mounted) Navigator.of(context).pop(itemToSave);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create supplementation: $e')),
          );
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Supplementation Type'),
      content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Supplementation Name', border: OutlineInputBorder()),
            validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
          )
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveSupplementation,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
          label: Text(_isSaving ? 'Saving...' : 'Create'),
        ),
      ],
    );
  }
}


// The main multi-select dialog
class SupplementationMultiSelectDialog extends StatefulWidget {
  final List<String> initialSelectedIds;

  const SupplementationMultiSelectDialog({
    super.key,
    required this.initialSelectedIds,
  });

  @override
  State<SupplementationMultiSelectDialog> createState() => _SupplementationMultiSelectDialogState();
}

class _SupplementationMultiSelectDialogState extends State<SupplementationMultiSelectDialog> {
  List<SupplimentMasterModel> _allSupplementations = [];
  List<SupplimentMasterModel> _filteredSupplementations = [];
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds.toSet();
    _loadSupplementations();
    _searchController.addListener(_filterSupplementations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSupplementations);
    _searchController.dispose();
    super.dispose();
  }

  void _loadSupplementations() async {
    setState(() { _isLoading = true; });
    final supplementations = await SupplimentMasterService().fetchAllSupplimentMaster();

    setState(() {
      _allSupplementations = supplementations;
      _filterSupplementations();
      _isLoading = false;
    });
  }

  void _filterSupplementations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSupplementations = _allSupplementations;
      } else {
        _filteredSupplementations = _allSupplementations
            .where((sup) => sup.enName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _addNewSupplementation() async {
    final newRecord = await showDialog<SupplimentMasterModel>(
      context: context,
      builder: (context) => const SupplementationMasterCreationDialog(),
    );

    if (newRecord != null) {
      setState(() {
        _allSupplementations.add(newRecord);
        // Note: New items are not automatically selected.

        if (_selectedIds.contains(newRecord.id)) {
          _selectedIds.remove(newRecord.id);
        }
        _filterSupplementations();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newRecord.enName} added to master list.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select'),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Section (Search and Add Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add New Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('Add'),
                    onPressed: _addNewSupplementation,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List View for Selection
            _isLoading
                ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
                : _filteredSupplementations.isEmpty && _searchController.text.isNotEmpty
                ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No match found.'),
            )
                : _filteredSupplementations.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No supplement found. Add a new one.'),
            )
                : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSupplementations.length,
                itemBuilder: (context, index) {
                  final supplementation = _filteredSupplementations[index];
                  return CheckboxListTile(
                    title: Text(supplementation.enName),
                    value: _selectedIds.contains(supplementation.id),
                    onChanged: (bool? isChecked) {
                      setState(() {
                        if (isChecked == true) {
                          _selectedIds.add(supplementation.id);
                        } else {
                          _selectedIds.remove(supplementation.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: const Text('Done'),
        ),
      ],
    );
  }
}