// lib/screens/food_item_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/meal_planner/service/Dependancy_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:provider/provider.dart';
// For localization fields

class FoodItemEntryPage extends StatefulWidget {
  final FoodItem? itemToEdit;

  const FoodItemEntryPage({super.key, this.itemToEdit});

  @override
  State<FoodItemEntryPage> createState() => _FoodItemEntryPageState();
}

class _FoodItemEntryPageState extends State<FoodItemEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enNameController = TextEditingController();
  final _stdServingController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  String? _selectedCategoryId;
  String? _selectedServingUnitId;

  bool _isLoading = false;

  // Futures to hold the dependency data for dropdowns
  late Future<List<FoodCategory>> _categoriesFuture;
  late Future<List<ServingUnit>> _unitsFuture;
  final DependencyService _dependencyService = DependencyService();


  @override
  void initState() {
    super.initState();
    _categoriesFuture = _dependencyService.fetchAllActiveFoodCategories();
    _unitsFuture = _dependencyService.fetchAllActiveServingUnits();

    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    } else {
      // Set default values for new entry
      _stdServingController.text = '100.0';
      _kcalController.text = '0.0';
      _proteinController.text = '0.0';
      _carbsController.text = '0.0';
      _fatController.text = '0.0';
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') {
        _localizedControllers[code] = TextEditingController();
      }
    }
  }

  void _initializeForEdit(FoodItem item) {
    _enNameController.text = item.enName;
    _stdServingController.text = item.standardServingSizeG.toStringAsFixed(1);
    _kcalController.text = item.caloriesPerStandardServing.toStringAsFixed(1);
    _proteinController.text = item.proteinG.toStringAsFixed(1);
    _carbsController.text = item.carbsG.toStringAsFixed(1);
    _fatController.text = item.fatG.toStringAsFixed(1);

    _selectedCategoryId = item.categoryId;
    _selectedServingUnitId = item.servingUnitId;

    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) {
        _localizedControllers[code]!.text = name;
      }
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _stdServingController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedServingUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both Category and Serving Unit.')));
      return;
    }

    setState(() => _isLoading = true);
    final service = Provider.of<FoodItemService>(context, listen: false);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });

    // Parse numerical values
    double parseDouble(TextEditingController controller) {
      return double.tryParse(controller.text) ?? 0.0;
    }

    final itemToSave = FoodItem(
      id: widget.itemToEdit?.id ?? '',
      enName: _enNameController.text.trim(),
      categoryId: _selectedCategoryId!,
      servingUnitId: _selectedServingUnitId!,
      nameLocalized: localizedNames,
      standardServingSizeG: parseDouble(_stdServingController),
      caloriesPerStandardServing: parseDouble(_kcalController),
      proteinG: parseDouble(_proteinController),
      carbsG: parseDouble(_carbsController),
      fatG: parseDouble(_fatController),
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
        title: Text(isEdit ? 'Edit Food Item' : 'Add Food Item'),
        backgroundColor: Colors.lightGreen,
      ),
      body: FutureBuilder<List<dynamic>>(
        // Wait for both dependencies to load
        future: Future.wait([_categoriesFuture, _unitsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading dependencies: ${snapshot.error}'));
          }

          final List<FoodCategory> categories = snapshot.data![0] as List<FoodCategory>;
          final List<ServingUnit> units = snapshot.data![1] as List<ServingUnit>;

          return SingleChildScrollView(
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
                      labelText: 'Food Item Name (English) *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Brown Rice, Chicken Breast',
                    ),
                    validator: (value) => value!.isEmpty ? 'English Name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // --- Dependency Dropdowns ---
                  Row(
                    children: [
                      Expanded(child: _buildCategoryDropdown(categories)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildUnitDropdown(units)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Nutritional Information Section ---
                  Text(
                    'Nutritional Information (Per Standard Serving)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreen.shade700),
                  ),
                  const Divider(),

                  // Standard Serving Size
                  TextFormField(
                    controller: _stdServingController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Standard Serving Size (g/ml) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value!.isEmpty || double.tryParse(value) == null) ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Calories
                  TextFormField(
                    controller: _kcalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Calories (Kcal) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value!.isEmpty || double.tryParse(value) == null) ? 'Required' : null,
                  ),
                  const SizedBox(height: 15),

                  // Macros: Protein, Carbs, Fat
                  Row(
                    children: [
                      Expanded(child: _buildMacroField(_proteinController, 'Protein (g)')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMacroField(_carbsController, 'Carbs (g)')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildMacroField(_fatController, 'Fat (g)')),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- Localization Section ---
                  Text(
                    'Translations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreen.shade700),
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
                    label: Text(isEdit ? 'Update Food Item' : 'Save Food Item'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.lightGreen.shade700,
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

  // Helper method for the Category Dropdown
  Widget _buildCategoryDropdown(List<FoodCategory> categories) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Food Category *',
        border: OutlineInputBorder(),
      ),
      value: _selectedCategoryId,
      hint: const Text('Select Category'),
      items: categories.map((cat) => DropdownMenuItem(
        value: cat.id,
        child: Text(cat.enName),
      )).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategoryId = newValue;
        });
      },
      validator: (value) => value == null ? 'Category is required' : null,
    );
  }

  // Helper method for the Serving Unit Dropdown
  Widget _buildUnitDropdown(List<ServingUnit> units) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Serving Unit *',
        border: OutlineInputBorder(),
      ),
      value: _selectedServingUnitId,
      hint: const Text('Select Unit'),
      items: units.map((unit) => DropdownMenuItem(
        value: unit.id,
        child: Text('${unit.enName} (${unit.abbreviation})'),
      )).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedServingUnitId = newValue;
        });
      },
      validator: (value) => value == null ? 'Unit is required' : null,
    );
  }

  // Helper method for Macro TextFields
  Widget _buildMacroField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => (value!.isEmpty || double.tryParse(value) == null) ? 'Required' : null,
    );
  }
}