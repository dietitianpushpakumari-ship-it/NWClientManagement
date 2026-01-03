import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/generic_master_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';

class FoodItemEntryPage extends ConsumerStatefulWidget {
  final FoodItem? itemToEdit;
  const FoodItemEntryPage({super.key, this.itemToEdit});

  @override
  ConsumerState<FoodItemEntryPage> createState() => _FoodItemEntryPageState();
}

class _FoodItemEntryPageState extends ConsumerState<FoodItemEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _enNameController = TextEditingController();
  final _stdServingController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  // State
  String? _selectedCategoryId;
  String? _selectedServingUnitId;
  bool _isLoading = false;
  bool _isTranslating = false;

  // Services
  Future<List<dynamic>>? _dependenciesFuture;
  final AiTranslationService _translationService = AiTranslationService();

  @override
  void initState() {
    super.initState();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesFuture == null) {
      final foodCategoryService = ref.read(foodCategoryProvider);
      final serviceUnitService = ref.read(serviceUnitMasterServiceProvider);
      _dependenciesFuture = Future.wait([
        foodCategoryService.fetchActiveItems(),
        serviceUnitService.fetchActiveItems(),
      ]);
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }
  }

  void _initializeForEdit(FoodItem item) {
    _enNameController.text = item.name;
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

  // --- ACTIONS ---

  Future<void> _performAutoTranslation() async {
    final text = _enNameController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter English name first")));
      return;
    }

    setState(() => _isTranslating = true);

    try {
      final translations = await _translationService.translateContent(text);
      translations.forEach((code, translatedText) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = translatedText;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ Translation Complete!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Failed: $e")));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedServingUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Category & Unit')));
      return;
    }
    setState(() => _isLoading = true);

    final service = ref.read(foodItemServiceProvider);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });
    double parseDouble(TextEditingController c) => double.tryParse(c.text) ?? 0.0;

    final itemToSave = FoodItem(
      id: widget.itemToEdit?.id ?? '',
      name: _enNameController.text.trim(),
      categoryId: _selectedCategoryId!,
      servingUnitId: _selectedServingUnitId!,
      nameLocalized: localizedNames,
      standardServingSizeG: parseDouble(_stdServingController),
      caloriesPerStandardServing: parseDouble(_kcalController),
      proteinG: parseDouble(_proteinController),
      carbsG: parseDouble(_carbsController),
      fatG: parseDouble(_fatController),
      createdDate: widget.itemToEdit?.createdDate,
      // 🎯 CRITICAL FIX: Was 'true' (deleted), now 'false' (active)
      isDeleted: false,
    );

    try {
      await service.save(itemToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food Item Saved!')));
        // Return the saved item to the previous screen
        Navigator.of(context).pop(itemToSave);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemToEdit != null;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Stack(
          children: [
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

            Column(
              children: [
                _buildHeader(
                    isEdit ? 'Edit Food Item' : 'Add Food Item',
                    actions: [
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 28),
                        onPressed: _isLoading ? null : _saveItem,
                      )
                    ]
                ),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _dependenciesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Error: Failed to load master data.'));
                      }

                      final categories = snapshot.data![0] as List<GenericMasterModel>;
                      final units = snapshot.data![1] as List<GenericMasterModel>;

                      // Validate Dropdowns
                      if (_selectedCategoryId != null && !categories.any((c) => c.id == _selectedCategoryId)) {
                        _selectedCategoryId = null;
                      }
                      if (_selectedServingUnitId != null && !units.any((u) => u.id == _selectedServingUnitId)) {
                        _selectedServingUnitId = null;
                      }

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
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildTextField(_enNameController, "Food Name", Icons.fastfood)),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: _isTranslating ? null : _performAutoTranslation,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            height: 56,
                                            width: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                                            ),
                                            child: _isTranslating
                                                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                                                : const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.translate, color: Colors.indigo, size: 20),
                                                Text("Auto", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.bold))
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedCategoryId,
                                            isExpanded: true,
                                            decoration: _inputDec("Category", Icons.category),
                                            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedServingUnitId,
                                            isExpanded: true,
                                            decoration: _inputDec("Unit", Icons.scale),
                                            items: units.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
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
      ),
    );
  }

  // ... Helpers match your existing code ...
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
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _inputDec(label, icon, color: color),
      validator: (v) => v!.isEmpty && label.contains("Food Name") ? "Required" : null,
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