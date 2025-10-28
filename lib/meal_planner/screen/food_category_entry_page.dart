// lib/screens/food_category_entry_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../helper/language_config.dart' show supportedLanguageCodes, supportedLanguages;

class FoodCategoryEntryPage extends StatefulWidget {
  final FoodCategory? itemToEdit;

  const FoodCategoryEntryPage({super.key, this.itemToEdit});

  @override
  State<FoodCategoryEntryPage> createState() => _FoodCategoryEntryPageState();
}

class _FoodCategoryEntryPageState extends State<FoodCategoryEntryPage> {
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
      // Default new item to a high order number (you'd typically fetch the max + 1)
      _orderController.text = '100';
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(FoodCategory item) {
    _enNameController.text = item.enName;
    _orderController.text = item.displayOrder.toString();
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
    final service = Provider.of<FoodCategoryService>(context, listen: false);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });

    final itemToSave = FoodCategory(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      nameLocalized: localizedNames,
      displayOrder: int.tryParse(_orderController.text) ?? 0,
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
        title: Text(isEdit ? 'Edit Food Category' : 'Add Food Category'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Core Fields ---
              TextFormField(
                controller: _enNameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name (English) *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Protein, Vegetable',
                ),
                validator: (value) => value!.isEmpty ? 'English Name is required' : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Display Order (Lower number appears first)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 10',
                ),
                validator: (value) => (value == null || int.tryParse(value) == null) ? 'Valid number required' : null,
              ),
              const SizedBox(height: 30),

              // --- Localization Section ---
              Text(
                'Translations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
              ),
              const Divider(),

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
                  backgroundColor: Colors.orange,
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