import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class DiseaseMasterEntryScreen extends StatefulWidget {
  final DiseaseMasterModel? diseaseToEdit;

  const DiseaseMasterEntryScreen({super.key, this.diseaseToEdit});

  @override
  State<DiseaseMasterEntryScreen> createState() =>
      _DiseaseMasterEntryScreenState();
}

class _DiseaseMasterEntryScreenState extends State<DiseaseMasterEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final DiseaseMasterService _service = DiseaseMasterService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.diseaseToEdit != null) {
      _enNameController.text = widget.diseaseToEdit!.enName;
    }
  }

  @override
  void dispose() {
    _enNameController.dispose();
    super.dispose();
  }

  void _saveDisease() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final isEditing = widget.diseaseToEdit != null;
    final diseaseId = isEditing ? widget.diseaseToEdit!.id : '';

    // Create the model
    final newDisease = DiseaseMasterModel(
      id: diseaseId,
      enName: _enNameController.text.trim(),
      // Keep existing localization for simplicity in this screen
      nameLocalized: isEditing ? widget.diseaseToEdit!.nameLocalized : {},
      isDeleted: false,
    );

    try {
      if (isEditing) {
        await _service.updateDisease(newDisease);
      } else {
        await _service.addDisease(newDisease);
      }
      if (mounted) {
        Navigator.of(context).pop(true); // Pop and indicate success
      }
    } catch (e) {
      _showSnackbar('Failed to save disease: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(
          widget.diseaseToEdit != null ? 'Edit Disease' : 'Add New Disease',
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveDisease,
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : const Icon(Icons.save),
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _enNameController,
              decoration: const InputDecoration(
                labelText: 'Disease Name (English)*',
                hintText: 'e.g., Type 2 Diabetes Mellitus',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Disease name is required.';
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }
}