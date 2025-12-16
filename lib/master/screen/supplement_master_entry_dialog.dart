// lib/widgets/SupplementationMasterEntryDialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/modules/client/screen/Suppliment_master_service.dart';
import 'package:nutricare_client_management/modules/client/screen/suppliment_master_model.dart';

class SupplementationMasterEntryDialog extends ConsumerStatefulWidget {
  final SupplimentMasterModel? supplementation; // Null for Add, Not null for Edit

  const SupplementationMasterEntryDialog({super.key, this.supplementation});

  @override
  ConsumerState<SupplementationMasterEntryDialog> createState() => _SupplementationMasterEntryDialogState();
}

class _SupplementationMasterEntryDialogState extends ConsumerState<SupplementationMasterEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplementation != null) {
      _nameController.text = widget.supplementation!.enName;
    }
  }

  void _saveSupplementation() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final supplementationToSave = (widget.supplementation ?? const SupplimentMasterModel(id: '', enName: '')).copyWith(
        enName: _nameController.text.trim(),id:   DateTime.now().microsecondsSinceEpoch.toString()
      );

      try {
        final savedRecord = await ref.read(supplimentMasterServiceProvider).addOrUpdateSupplimentMaster(supplementationToSave);
        if (mounted) Navigator.of(context).pop(supplementationToSave);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save supplementation: $e')),
          );
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplementation != null;
    return SafeArea(
      child: AlertDialog(
        title: Text(isEditing ? 'Edit Supplementation' : 'Add New Supplementation'),
        content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Supplementation Name (English)', border: OutlineInputBorder()),
              validator: (value) => value!.trim().isEmpty ? 'Name cannot be empty' : null,
            )
        ),
        actions: [
          TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSupplementation,
            icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isEditing ? Icons.save : Icons.add),
            label: Text(_isSaving ? 'Saving...' : (isEditing ? 'Save' : 'Create')),
          ),
        ],
      ),
    );
  }
}