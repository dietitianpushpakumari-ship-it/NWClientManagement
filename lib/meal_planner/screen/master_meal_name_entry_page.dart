// lib/screens/master_meal_name_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:provider/provider.dart';

// NOTE: Assuming this file contains supportedLanguageCodes and supportedLanguages map
// You should ensure this file exists in your project structure (e.g., lib/config/language_config.dart)
// Placeholder for demonstration:

final List<String> supportedLanguageCodes = supportedLanguages.keys.toList();


class MasterMealNameEntryPage extends StatefulWidget {
  final MasterMealName? itemToEdit;

  const MasterMealNameEntryPage({super.key, this.itemToEdit});

  @override
  State<MasterMealNameEntryPage> createState() => _MasterMealNameEntryPageState();
}

class _MasterMealNameEntryPageState extends State<MasterMealNameEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _orderController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    } else {
      // 🎯 Initialize for new item: default order to 1 or a sensible starting number
      _orderController.text = '1';
    }
  }

  void _initializeLocalizedControllers() {
    // Create controllers for all supported languages except English
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(MasterMealName item) {
    _enNameController.text = item.enName;
    _orderController.text = item.order.toString();

    // Populate localized fields
    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _orderController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final service = Provider.of<MasterMealNameService>(context, listen: false);

    // Collect all localized names
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });
    // 🎯 FIX 6: Parse the order safely
    final int orderValue = int.tryParse(_orderController.text.trim()) ?? 99;
    final itemToSave = MasterMealName(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: localizedNames,
      isDeleted: widget.itemToEdit?.isDeleted ?? false,
      createdDate: widget.itemToEdit?.createdDate,
      order: orderValue,
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
        title: Text(isEdit ? 'Edit Meal Name' : 'Add New Meal Name'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Core Field: English Name ---
              TextFormField(
                controller: _enNameController,
                decoration: const InputDecoration(
                  labelText: 'Meal Name (English) *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Breakfast, Mid-Morning Snack',
                ),
                validator: (value) => value!.isEmpty ? 'English Name is required' : null,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Display Order *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 1 for Breakfast, 2 for Lunch',
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Order is required';
                  if (int.tryParse(value) == null) return 'Must be a whole number';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // --- Localization Section Header ---
              Text(
                'Translations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
              ),
              const Divider(),

              // Dynamically generate translation fields
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
                label: Text(isEdit ? 'Update Meal Name' : 'Save Meal Name'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.orange.shade700,
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