import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🎯 Project Imports
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/master/model/ServingUnit.dart';

import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';

// 🎯 NEW: Define the allowed base units
const List<String> BASE_UNITS = ['G', 'ML', 'PC', 'UNIT', 'CUP'];


class ServingUnitEntryPage extends ConsumerStatefulWidget {
  final ServingUnit? itemToEdit;
  const ServingUnitEntryPage({super.key, this.itemToEdit});

  @override
  ConsumerState<ServingUnitEntryPage> createState() => _ServingUnitEntryPageState();
}

class _ServingUnitEntryPageState extends ConsumerState<ServingUnitEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _enNameController = TextEditingController();
  final _abbreviationController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  // State
  String? _selectedBaseUnit; // 🎯 State for selected base unit
  bool _isLoading = false;
  bool _isTranslating = false;
  final AiTranslationService _translationService = AiTranslationService();

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();

    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }
  }

  void _initializeForEdit(ServingUnit item) {
    _enNameController.text = item.name;
    _abbreviationController.text = item.abbreviation;

    // 🎯 FIX 1: Ensure selectedBaseUnit is NULL if the loaded value is empty or invalid
    final loadedBaseUnit = item.baseUnit?.toUpperCase();

    // Check if the loaded value is a non-empty string AND is in the allowed list
    if (loadedBaseUnit != null && loadedBaseUnit.isNotEmpty && BASE_UNITS.contains(loadedBaseUnit)) {
      _selectedBaseUnit = loadedBaseUnit;
    } else {
      // If null, empty string (""), or invalid, treat as unselected (null)
      _selectedBaseUnit = null;
    }

    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) _localizedControllers[code]!.text = name;
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _abbreviationController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _performAutoTranslation() async {
    final text = _enNameController.text.trim();
    if (text.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter English name first")));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ Translation Complete!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Failed: $e")));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _saveItem() async {
    // 🎯 FIX 4: Rely entirely on the Form Key validation.
    if (!_formKey.currentState!.validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields."), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final service = ref.read(servingUnitServiceProvider);

    // Gather localized names (they are not required to be non-empty)
    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });

    final itemToSave = ServingUnit(
      id: widget.itemToEdit?.id ?? '',
      name: _enNameController.text.trim(),
      abbreviation: _abbreviationController.text.trim().toUpperCase(),
      baseUnit: _selectedBaseUnit!, // Guaranteed non-null by validator
      nameLocalized: localizedNames,
    );

    try {
      await service.saveUnit(itemToSave);
      if (mounted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Serving Unit Saved!')));
        Navigator.of(context).pop();
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
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
      
            Column(
              children: [
                // 🎯 CUSTOM ULTRA PREMIUM HEADER
                _buildHeader(
                    isEdit ? 'Edit Serving Unit' : 'New Serving Unit',
                    actions: [
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle, color: Colors.pink, size: 28),
                        onPressed: _isLoading ? null : _saveItem,
                      )
                    ]
                ),
      
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // --- 1. BASIC INFO & ABBREVIATION ---
                          _buildPremiumCard(
                            title: "Basic Details",
                            icon: Icons.scale,
                            color: Colors.pink,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // 🎯 Mandatory English Name
                                    Expanded(child: _buildTextField(_enNameController, "Unit Name (English)", Icons.title, isRequired: true)),
                                    const SizedBox(width: 12),
                                    // 🎯 Mandatory Abbreviation
                                    Expanded(child: _buildTextField(_abbreviationController, "Abbreviation (e.g., g, pc)", Icons.tag, isRequired: true)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 🎯 Base Unit Dropdown (Mandatory by validation)
                                _buildBaseUnitDropdown(),
                                const SizedBox(height: 12),
      
                                // 🎯 Translation Button
                                _buildTranslateButton(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
      
                          // --- 2. LOCALIZATION ---
                          _buildPremiumCard(
                            title: "Localization (Optional)", // 🎯 UI Label Change
                            icon: Icons.translate,
                            color: Colors.purple,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // 🎯 ALL LOCALIZED FIELDS ARE NOW OPTIONAL
                              children: supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTextField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language, isRequired: false),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 NEW: Base Unit Dropdown Widget
  Widget _buildBaseUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedBaseUnit,
      decoration: _inputDec("Base Unit", Icons.bolt).copyWith(
        helperText: 'Required for conversion. Should be one of: ${BASE_UNITS.join(', ')}',
      ),
      items: [
        // Explicitly add a null item for the unselected state
        const DropdownMenuItem<String>(
          value: null,
          child: Text('--- Select Base Unit ---', style: TextStyle(color: Colors.grey)),
        ),
        ...BASE_UNITS.map((unit) {
          return DropdownMenuItem(
            value: unit,
            child: Text(unit),
          );
        }).toList(),
      ],
      onChanged: (v) => setState(() => _selectedBaseUnit = v),
      validator: (v) => v == null ? "Please select a base unit" : null,
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTranslateButton() {
    return InkWell(
      onTap: _isTranslating ? null : _performAutoTranslation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
        ),
        child: _isTranslating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Row(
          children: [
            Icon(Icons.translate, color: Colors.indigo, size: 20),
            SizedBox(width: 4),
            Text("Auto-Translate", style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }

  // 🎯 Custom Header (Ultra Premium Style)
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

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false, bool isRequired = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: false) : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _inputDec(label, icon),
      // 🎯 FIX 3: Use explicit isRequired flag
      validator: (v) => isRequired && v!.isEmpty ? "Required" : null,
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}