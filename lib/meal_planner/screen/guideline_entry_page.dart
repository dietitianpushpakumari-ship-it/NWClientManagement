// lib/screens/guideline_entry_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:provider/provider.dart';

import '../service/Dependancy_service.dart';


class GuidelineEntryPage extends StatefulWidget {
  final Guideline? itemToEdit;

  const GuidelineEntryPage({super.key, this.itemToEdit});

  @override
  State<GuidelineEntryPage> createState() => _GuidelineEntryPageState();
}

class _GuidelineEntryPageState extends State<GuidelineEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enTitleController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  Set<String> _selectedCategoryIds = {};
  bool _isLoading = false;

  late Future<List<DietPlanCategory>> _categoriesFuture;
  final DependencyService _dependencyService = DependencyService(); // Use DependencyService for fetching master data

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _dependencyService.fetchAllActiveDietPlanCategories();
    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(Guideline item) {
    _enTitleController.text = item.enTitle;
    _selectedCategoryIds = Set<String>.from(item.dietPlanCategoryIds);

    item.titleLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enTitleController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one Diet Plan Category.')));
      return;
    }

    setState(() => _isLoading = true);
    final service = Provider.of<GuidelineService>(context, listen: false);

    final Map<String, String> localizedTitles = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedTitles[code] = text;
    });

    final itemToSave = Guideline(
      id: widget.itemToEdit?.id ?? '',
      enTitle: _enTitleController.text.trim(),
      titleLocalized: localizedTitles,
      isDeleted: widget.itemToEdit?.isDeleted ?? false,
      dietPlanCategoryIds: _selectedCategoryIds.toList(),
      createdDate: widget.itemToEdit?.createdDate,
    );

    try {
      await service.save(itemToSave);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guideline saved: ${itemToSave.enTitle}')));
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
        title: Text(isEdit ? 'Edit Guideline' : 'Add New Guideline'),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<DietPlanCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading categories: ${snapshot.error}'));
          }

          final List<DietPlanCategory> categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('No Diet Plan Categories found. Please create one first.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Core Field ---
                  TextFormField(
                    controller: _enTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Guideline Title (English) *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Drink at least 3L of water per day.',
                    ),
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),

                  // --- Diet Plan Category Multi-Select ---
                  _buildCategoryMultiSelect(categories),
                  const SizedBox(height: 30),

                  // --- Localization Section ---
                  Text(
                    'Translations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
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
                          labelText: 'Title ($languageName)',
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
                    label: Text(isEdit ? 'Update Guideline' : 'Save Guideline'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method for the Diet Plan Category Multi-Select
  Widget _buildCategoryMultiSelect(List<DietPlanCategory> categories) {
    final selectedCategoryNames = categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.enName)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applies to Diet Plan Categories *',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.fromLTRB(12.0, 10.0, 20.0, 10.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: null, // Always null for multi-select
              hint: Text(_selectedCategoryIds.isEmpty
                  ? 'Select one or more categories'
                  : selectedCategoryNames.join(', ')),
              items: categories.map((cat) {
                final isSelected = _selectedCategoryIds.contains(cat.id);
                return DropdownMenuItem<String>(
                  value: cat.id,
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: isSelected ? Colors.indigo : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(cat.enName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newId) {
                if (newId != null) {
                  setState(() {
                    if (_selectedCategoryIds.contains(newId)) {
                      _selectedCategoryIds.remove(newId);
                    } else {
                      _selectedCategoryIds.add(newId);
                    }
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

