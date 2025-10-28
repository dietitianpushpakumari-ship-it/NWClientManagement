// lib/widgets/InvestigationMultiSelectDialog.dart (UPDATED)

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';

//Dialog for creating a new master record (Remains the same, but uses the corrected method name)
class InvestigationMasterCreationDialog extends StatefulWidget {
  const InvestigationMasterCreationDialog({super.key});

  @override
  State<InvestigationMasterCreationDialog> createState() => _InvestigationMasterCreationDialogState();
}

class _InvestigationMasterCreationDialogState extends State<InvestigationMasterCreationDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  void _saveInvestigation() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });
      final unitToSave = _controller.text.trim();



      try {
        // FIX: Using the corrected service method
        final itemToSave = InvestigationMasterModel(
          id:  '',
          isDeleted:  false,
          enName: unitToSave,
        );
        final newRecord = await InvestigationMasterService().addOrUpdateInvestigation(itemToSave);
        if (mounted) Navigator.of(context).pop(itemToSave);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create investigation: $e')),
          );
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Investigation Type'),
      content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Investigation Name', border: OutlineInputBorder()),
            validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
          )
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveInvestigation,
          icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
          label: Text(_isSaving ? 'Saving...' : 'Create'),
        ),
      ],
    );
  }
}


// The main multi-select dialog (UPDATED for Search and Refresh)
class InvestigationMultiSelectDialog extends StatefulWidget {
  final List<String> initialSelectedIds;

  const InvestigationMultiSelectDialog({
    super.key,
    required this.initialSelectedIds,
  });

  @override
  State<InvestigationMultiSelectDialog> createState() => _InvestigationMultiSelectDialogState();
}

class _InvestigationMultiSelectDialogState extends State<InvestigationMultiSelectDialog> {
  List<InvestigationMasterModel> _allInvestigations = [];
  List<InvestigationMasterModel> _filteredInvestigations = []; // For search results
  Set<String> _selectedIds = {};
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds.toSet();
    _loadInvestigations();
    _searchController.addListener(_filterInvestigations);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterInvestigations);
    _searchController.dispose();
    super.dispose();
  }

  void _loadInvestigations() async {
    setState(() { _isLoading = true; });
    final investigations = await InvestigationMasterService().fetchAllInvestigationMaster();

    setState(() {
      _allInvestigations = investigations;
      _filterInvestigations(); // Apply current search filter after loading
      _isLoading = false;
    });
  }

  // New method for searching/filtering
  void _filterInvestigations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInvestigations = _allInvestigations;
      } else {
        _filteredInvestigations = _allInvestigations
            .where((inv) => inv.enName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _addNewInvestigation() async {
    final newRecord = await showDialog<InvestigationMasterModel>(
      context: context,
      builder: (context) => const InvestigationMasterCreationDialog(),
    );

    if (newRecord != null) {
      // FIX: Add the new record and refresh the entire list to ensure persistence
      // The calling screen relies on the final list of selected IDs.
      setState(() {
        _allInvestigations.add(newRecord);
       // _selectedIds.add(newRecord.id);
        _filterInvestigations(); // Refresh filter view
      });
      // OPTIONAL: Reloading the entire master list from the service here
      // is only needed if creation updates the persistent master list,
      // which we will assume the main page handles on return.
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Recommended Investigations'),
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
                        labelText: 'Search Investigations',
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
                    onPressed: _addNewInvestigation,
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
                : _filteredInvestigations.isEmpty && _searchController.text.isNotEmpty
                ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No matching investigations found.'),
            )
                : _filteredInvestigations.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No investigations found. Add a new one.'),
            )
                : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredInvestigations.length,
                itemBuilder: (context, index) {
                  final investigation = _filteredInvestigations[index];
                  return CheckboxListTile(
                    title: Text(investigation.enName),
                    value: _selectedIds.contains(investigation.id),
                    onChanged: (bool? isChecked) {
                      setState(() {
                        if (isChecked == true) {
                          _selectedIds.add(investigation.id);
                        } else {
                          _selectedIds.remove(investigation.id);
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
          // Return the current list of selected IDs
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: const Text('Done'),
        ),
      ],
    );
  }
}