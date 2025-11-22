import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/meal_planner/service/Dependancy_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both Category and Serving Unit.')));
      return;
    }

    setState(() => _isLoading = true);
    final service = Provider.of<FoodItemService>(context, listen: false);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) localizedNames[code] = text;
    });

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${itemToSave.enName} saved successfully!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving item: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Helper: Standard Input Decoration ---
  InputDecoration _inputDecoration(String label, {String? hint, String? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  // --- Helper: Section Header ---
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.itemToEdit != null;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: Text(isEdit ? 'Edit Food Item' : 'Add Food Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveItem,
            tooltip: 'Save Item',
          )
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          // Wait for both dependencies to load
          future: Future.wait([_categoriesFuture, _unitsFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading data: ${snapshot.error}'));
            }

            final List<FoodCategory> categories =
            snapshot.data![0] as List<FoodCategory>;
            final List<ServingUnit> units =
            snapshot.data![1] as List<ServingUnit>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CARD 1: BASIC DETAILS ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSectionHeader('Basic Details', Icons.info_outline, Colors.indigo),
                            TextFormField(
                              controller: _enNameController,
                              decoration: _inputDecoration('Item Name (English)', hint: 'e.g., Brown Rice'),
                              validator: (value) => value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCategoryDropdown(categories),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildUnitDropdown(units),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- CARD 2: NUTRITIONAL PROFILE ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildSectionHeader('Nutritional Profile', Icons.restaurant_menu, Colors.green.shade700),

                            // Serving & Calories Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _stdServingController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                    decoration: _inputDecoration('Std Serving', suffix: 'g/ml'),
                                    validator: (value) => (value!.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _kcalController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                    decoration: _inputDecoration('Energy', suffix: 'Kcal'),
                                    validator: (value) => (value!.isEmpty) ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // MACROS SECTION
                            const Text("Macros per standard serving", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildMacroField(_proteinController, 'Protein', Colors.blue)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildMacroField(_carbsController, 'Carbs', Colors.green)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildMacroField(_fatController, 'Fat', Colors.orange)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- CARD 3: LOCALIZATION (Collapsible) ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: const Text('Translations / Localization', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                        leading: const Icon(Icons.translate, color: Colors.teal),
                        childrenPadding: const EdgeInsets.all(16),
                        children: [
                          ...supportedLanguageCodes.map((code) {
                            if (code == 'en') return const SizedBox.shrink();
                            final languageName = supportedLanguages[code]!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: TextFormField(
                                controller: _localizedControllers[code],
                                decoration: _inputDecoration('Name in $languageName'),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SAVE BUTTON (Big Bottom Button)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveItem,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded),
                      label: Text(isEdit ? 'Update Food Item' : 'Save to Master List'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildCategoryDropdown(List<FoodCategory> categories) {
    return DropdownButtonFormField<String>(
      // 🎯 FIX: Added isExpanded to prevent overflow
      isExpanded: true,
      decoration: _inputDecoration('Category'),
      value: _selectedCategoryId,
      items: categories.map((cat) => DropdownMenuItem(
        value: cat.id,
        child: Text(cat.enName, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (String? newValue) => setState(() => _selectedCategoryId = newValue),
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildUnitDropdown(List<ServingUnit> units) {
    return DropdownButtonFormField<String>(
      // 🎯 FIX: Added isExpanded to prevent overflow
      isExpanded: true,
      decoration: _inputDecoration('Unit'),
      value: _selectedServingUnitId,
      items: units.map((unit) => DropdownMenuItem(
        value: unit.id,
        child: Text('${unit.enName} (${unit.abbreviation})', overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (String? newValue) => setState(() => _selectedServingUnitId = newValue),
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildMacroField(TextEditingController controller, String label, Color accentColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: accentColor.withOpacity(0.8)),
          decoration: InputDecoration(
            hintText: '0.0',
            suffixText: 'g',
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
            filled: true,
            fillColor: accentColor.withOpacity(0.05),
          ),
          validator: (value) => (value!.isEmpty) ? 'Req' : null,
        ),
      ],
    );
  }
}