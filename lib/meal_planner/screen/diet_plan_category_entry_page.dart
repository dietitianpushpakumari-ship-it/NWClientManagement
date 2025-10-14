// lib/screens/diet_plan_category_entry_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/meal_planner/models/diet_plan_category.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_category_service.dart';
import 'package:provider/provider.dart';

class DietPlanCategoryEntryPage extends StatefulWidget {
  final DietPlanCategory? itemToEdit;

  const DietPlanCategoryEntryPage({super.key, this.itemToEdit});

  @override
  State<DietPlanCategoryEntryPage> createState() => _DietPlanCategoryEntryPageState();
}

class _DietPlanCategoryEntryPageState extends State<DietPlanCategoryEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    }
  }

  void _initializeLocalizedControllers() {
    // Dynamically create controllers for all supported languages (excluding English)
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(DietPlanCategory item) {
    _enNameController.text = item.enName;
    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = Provider.of<DietPlanCategoryService>(context, listen: false);

    // Collect localized names
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });

    final itemToSave = DietPlanCategory(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: localizedNames,
      isDeleted: widget.itemToEdit?.isDeleted ?? false,
      createdDate: widget.itemToEdit?.createdDate,
    );

    try {
      await service.save(itemToSave);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${itemToSave.enName} saved!')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.itemToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Diet Plan Category' : 'Add New Category'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Core Field ---
              TextFormField(
                controller: _enNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name (English) *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Weight Loss, Muscle Gain',
                ),
                validator: (value) => value!.isEmpty ? 'English Name is required' : null,
              ),
              const SizedBox(height: 30),

              // --- Localization Section ---
              Text(
                'Translations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
              ),
              const Divider(),

              // Localization Fields
              ...supportedLanguageCodes.map((code) {
                if (code == 'en') return const SizedBox.shrink();
                final languageName = supportedLanguages[code]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: TextFormField(
                    controller: _localizedControllers[code],
                    decoration: InputDecoration(
                      labelText: 'Name ($languageName)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.translate),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 40),

              // --- Save Button ---
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveItem,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save),
                label: Text(isEdit ? 'Update Category' : 'Save Category'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}