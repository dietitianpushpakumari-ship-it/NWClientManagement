// lib/widgets/InvestigationMasterEntryDialog.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_model.dart';
import 'package:nutricare_client_management/modules/client/screen/investigation_master_service.dart';

class InvestigationMasterEntryDialog extends StatefulWidget {
  final InvestigationMasterModel? investigation; // Null for Add, Not null for Edit

  const InvestigationMasterEntryDialog({super.key, this.investigation});

  @override
  State<InvestigationMasterEntryDialog> createState() => _InvestigationMasterEntryDialogState();
}

class _InvestigationMasterEntryDialogState extends State<InvestigationMasterEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.investigation != null) {
      _nameController.text = widget.investigation!.enName;
    }
  }

  void _saveInvestigation() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final investigationToSave = (widget.investigation ?? const InvestigationMasterModel(id: '', enName: '')).copyWith(
        enName: _nameController.text.trim(),id: DateTime.now().microsecondsSinceEpoch.toString()
      );

      try {
        final savedRecord = await InvestigationMasterService().addOrUpdateInvestigation(investigationToSave);
        if (mounted) Navigator.of(context).pop(investigationToSave);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save investigation: $e')),
          );
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.investigation != null;
    return SafeArea(
      child: AlertDialog(
        title: Text(isEditing ? 'Edit Investigation' : 'Add New Investigation'),
        content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Investigation Name (English)', border: OutlineInputBorder()),
              validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
            )
        ),
        actions: [
          TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveInvestigation,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isEditing ? Icons.save : Icons.add),
            label: Text(_isSaving ? 'Saving...' : (isEditing ? 'Save' : 'Create')),
          ),
        ],
      ),
    );
  }
}