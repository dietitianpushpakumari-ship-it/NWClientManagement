import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/helper/language_config.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/meal_planner/service/Dependancy_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:provider/provider.dart';

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

  late Future<List<dynamic>> _dependenciesFuture;
  final DependencyService _dependencyService = DependencyService();

  @override
  void initState() {
    super.initState();
    _dependenciesFuture = Future.wait([
      _dependencyService.fetchAllActiveFoodCategories(),
      _dependencyService.fetchAllActiveServingUnits(),
    ]);

    _initializeLocalizedControllers();
    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    } else {
      _stdServingController.text = '100.0';
      _kcalController.text = '0.0';
      _proteinController.text = '0.0';
      _carbsController.text = '0.0';
      _fatController.text = '0.0';
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
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
      if (_localizedControllers.containsKey(code)) _localizedControllers[code]!.text = name;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Category & Unit')));
      return;
    }

    setState(() => _isLoading = true);
    final service = Provider.of<FoodItemService>(context, listen: false);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });

    double parseDouble(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food Item Saved!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // Glow
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          Column(
            children: [
              // Custom Header
              _buildHeader(isEdit ? 'Edit Food Item' : 'Add Food Item', actions: [
                IconButton(
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                  onPressed: _isLoading ? null : _saveItem,
                )
              ]),

              // Content
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _dependenciesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                    final categories = snapshot.data![0] as List<FoodCategory>;
                    final units = snapshot.data![1] as List<ServingUnit>;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildPremiumCard(
                              title: "Basic Info",
                              icon: Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              child: Column(
                                children: [
                                  _buildTextField(_enNameController, "Food Name", Icons.fastfood),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedCategoryId,
                                          isExpanded: true,
                                          decoration: _inputDec("Category", Icons.category),
                                          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.enName))).toList(),
                                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedServingUnitId,
                                          isExpanded: true,
                                          decoration: _inputDec("Unit", Icons.scale),
                                          items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.abbreviation))).toList(),
                                          onChanged: (v) => setState(() => _selectedServingUnitId = v),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            _buildPremiumCard(
                              title: "Nutrition Facts",
                              icon: Icons.pie_chart_outline,
                              color: Colors.teal,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_stdServingController, "Serving Size", Icons.straighten, isNumber: true)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField(_kcalController, "Calories", Icons.local_fire_department, isNumber: true, color: Colors.deepOrange)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _buildTextField(_proteinController, "Protein (g)", Icons.fitness_center, isNumber: true, color: Colors.blue)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField(_carbsController, "Carbs (g)", Icons.grain, isNumber: true, color: Colors.brown)),
                                      const SizedBox(width: 12),
                                      Expanded(child: _buildTextField(_fatController, "Fat (g)", Icons.opacity, isNumber: true, color: Colors.amber)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            _buildPremiumCard(
                              title: "Localization",
                              icon: Icons.translate,
                              color: Colors.purple,
                              child: Column(
                                children: supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildTextField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language),
                                )).toList(),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildHeader(String title, {List<Widget>? actions}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              if (actions != null) ...actions
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: color.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, Color? color}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _inputDec(label, icon, color: color),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  InputDecoration _inputDec(String label, IconData icon, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: c.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}