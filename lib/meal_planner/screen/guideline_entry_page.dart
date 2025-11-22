import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:provider/provider.dart';

import '../service/Dependancy_service.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

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
  final DependencyService _dependencyService = DependencyService();

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
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guideline saved successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.itemToEdit != null;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomGradientAppBar(
        title: Text(isEdit ? 'Edit Guideline' : 'Add New Guideline'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<DietPlanCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading categories: ${snapshot.error}'));
            }

            final List<DietPlanCategory> categories = snapshot.data ?? [];

            // Handle case with no categories
            if (categories.isEmpty) {
              return const Center(child: Text('No Diet Plan Categories found. Please create one first.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Card 1: Basic Details ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.description_outlined, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text('Guideline Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _enTitleController,
                              decoration: _inputDecoration(
                                'Guideline Title (English) *',
                                hint: 'e.g., Drink at least 3L of water per day.',
                              ),
                              validator: (value) => value!.isEmpty ? 'Title is required' : null,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Card 2: Applicability (Categories) ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.category_outlined, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text('Applicable Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildCategoryMultiSelect(categories),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- Card 3: Localization ---
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.translate, color: Colors.teal),
                                const SizedBox(width: 8),
                                Text('Translations (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...supportedLanguageCodes.map((code) {
                              if (code == 'en') return const SizedBox.shrink();
                              final languageName = supportedLanguages[code]!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: TextFormField(
                                  controller: _localizedControllers[code],
                                  decoration: _inputDecoration(
                                    'Title in $languageName',
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Save Button ---
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveItem,
                      icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                      label: Text(isEdit ? 'Update Guideline' : 'Save Guideline'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method for the Diet Plan Category Multi-Select
  Widget _buildCategoryMultiSelect(List<DietPlanCategory> categories) {
    final selectedCategoryNames = categories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.enName)
        .toList();

    return InputDecorator(
      decoration: _inputDecoration('Select Categories *'),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: null, // Always null for multi-select behavior
          hint: Text(
            _selectedCategoryIds.isEmpty
                ? 'Select one or more categories'
                : selectedCategoryNames.join(', '),
            style: TextStyle(
              color: _selectedCategoryIds.isEmpty ? Colors.grey : Colors.black87,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
                  Expanded(child: Text(cat.enName, overflow: TextOverflow.ellipsis)),
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
    );
  }
}