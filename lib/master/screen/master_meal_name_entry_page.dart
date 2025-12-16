import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';


class MasterMealNameEntryPage extends ConsumerStatefulWidget {
  final MasterMealName? itemToEdit;
  const MasterMealNameEntryPage({super.key, this.itemToEdit});

  @override
  ConsumerState<MasterMealNameEntryPage> createState() => _MasterMealNameEntryPageState();
}

class _MasterMealNameEntryPageState extends ConsumerState<MasterMealNameEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _enNameController = TextEditingController();
  final _displayOrderController = TextEditingController();
  final _startTimeController = TextEditingController(); // 🎯 NEW
  final _endTimeController = TextEditingController();   // 🎯 NEW
  final Map<String, TextEditingController> _localizedControllers = {};

  // State
  bool _isLoading = false;
  bool _isTranslating = false;
  final AiTranslationService _translationService = AiTranslationService();

  @override
  void initState() {
    super.initState();
    _initializeLocalizedControllers();

    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    } else {
      _displayOrderController.text = '0';
    }
  }

  void _initializeLocalizedControllers() {
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }
  }

  void _initializeForEdit(MasterMealName item) {
    _enNameController.text = item.name;
    _displayOrderController.text = item.order.toString();
    _startTimeController.text = item.startTime ?? ''; // 🎯 PREFILL TIME
    _endTimeController.text = item.endTime ?? '';     // 🎯 PREFILL TIME
    item.nameLocalized.forEach((code, name) {
      if (_localizedControllers.containsKey(code)) _localizedControllers[code]!.text = name;
    });
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _displayOrderController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _pickTime(TextEditingController controller) async {
    final now = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.tryParse('2023-01-01 ${controller.text}') ?? DateTime.now()),
    );
    if (picked != null) {
      // Format as HH:mm string for simple storage/comparison
      controller.text = MaterialLocalizations.of(context).formatTimeOfDay(picked, alwaysUse24HourFormat: true);
    }
  }

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
    if (!_formKey.currentState!.validate()) return;
    if (_startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start time and End time are required.')));
      return;
    }

    setState(() => _isLoading = true);
    final service = ref.read(masterMealNameServiceProvider);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });

    final itemToSave = MasterMealName(
      id: widget.itemToEdit?.id ?? '',
      name: _enNameController.text.trim(),
      order: int.tryParse(_displayOrderController.text) ?? 0,
      startTime: _startTimeController.text.trim(), // 🎯 SAVING TIME
      endTime: _endTimeController.text.trim(),     // 🎯 SAVING TIME
      nameLocalized: localizedNames,
    );

    try {
      await service.save(itemToSave);
      if (mounted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal Name Saved!')));
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
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
      
            Column(
              children: [
                // 🎯 CUSTOM ULTRA PREMIUM HEADER
                _buildHeader(
                    isEdit ? 'Edit Meal Name' : 'New Meal Name',
                    actions: [
                      IconButton(
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle, color: Colors.blueAccent, size: 28),
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
                          // --- 1. BASIC INFO & ORDER ---
                          _buildPremiumCard(
                            title: "Basic Details",
                            icon: Icons.restaurant_menu,
                            color: Colors.blueAccent,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(flex: 3, child: _buildTextField(_enNameController, "Meal Name (English)", Icons.title)),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 1, child: _buildTextField(_displayOrderController, "Order", Icons.format_list_numbered, isNumber: true)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 🎯 START/END TIME INPUTS
                                Row(
                                  children: [
                                    Expanded(child: _buildTimeField(_startTimeController, "Start Time", Icons.access_time)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildTimeField(_endTimeController, "End Time", Icons.access_time)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
      
                          // --- 2. LOCALIZATION & AI ---
                          _buildPremiumCard(
                            title: "Localization",
                            icon: Icons.translate,
                            color: Colors.purple,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Translated Names", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    // 🎯 Translation Button
                                    _buildTranslateButton(),
                                  ],
                                ),
                                const Divider(height: 25),
      
                                // Localized Inputs
                                ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildTextField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language),
                                )).toList(),
                              ],
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

  // 🎯 CUSTOM HEADER (Ultra Premium Style)
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

  Widget _buildTimeField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickTime(ctrl),
      decoration: _inputDec(label, icon),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: false) : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _inputDec(label, icon),
      validator: (v) => v!.isEmpty && label.contains('English') ? "Required" : null,
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