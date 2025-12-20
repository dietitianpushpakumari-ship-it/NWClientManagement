import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';

class HabitMasterEntryPage extends ConsumerStatefulWidget {
  final HabitMasterModel? itemToEdit;
  const HabitMasterEntryPage({super.key, this.itemToEdit});

  @override
  ConsumerState<HabitMasterEntryPage> createState() => _HabitMasterEntryPageState();
}

class _HabitMasterEntryPageState extends ConsumerState<HabitMasterEntryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _enTitleController = TextEditingController();
  final TextEditingController _enDescController = TextEditingController();

  final Map<String, TextEditingController> _localizedTitleControllers = {};
  final Map<String, TextEditingController> _localizedDescControllers = {};

  final AiTranslationService _translationService = AiTranslationService();
  bool _isLoading = false;
  bool _isTranslatingTitle = false;
  bool _isTranslatingDesc = false;

  late HabitCategory _selectedCategory;
  late String _selectedIconCode;

  @override
  void initState() {
    super.initState();
    _selectedCategory = HabitCategory.morning;
    _selectedIconCode = 'sunny';

    for (var code in supportedLanguageCodes.where((c) => c != 'en')) {
      _localizedTitleControllers[code] = TextEditingController();
      _localizedDescControllers[code] = TextEditingController();
    }

    if (widget.itemToEdit != null) {
      _initializeForEdit(widget.itemToEdit!);
    }
  }

  void _initializeForEdit(HabitMasterModel habit) {
    _enTitleController.text = habit.name;
    _enDescController.text = habit.description;

    habit.titleLocalized.forEach((code, name) {
      if (_localizedTitleControllers.containsKey(code)) {
        _localizedTitleControllers[code]!.text = name;
      }
    });
    habit.descriptionLocalized.forEach((code, desc) {
      if (_localizedDescControllers.containsKey(code)) {
        _localizedDescControllers[code]!.text = desc;
      }
    });

    _selectedCategory = habit.category;
    _selectedIconCode = habit.iconCode;
  }

  @override
  void dispose() {
    _enTitleController.dispose();
    _enDescController.dispose();
    _localizedTitleControllers.values.forEach((c) => c.dispose());
    _localizedDescControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _performAutoTranslation({required bool isTitle}) async {
    final sourceController = isTitle ? _enTitleController : _enDescController;
    final targetControllers = isTitle ? _localizedTitleControllers : _localizedDescControllers;

    final text = sourceController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter English ${isTitle ? 'Title' : 'Description'} first")));
      return;
    }

    setState(() => isTitle ? _isTranslatingTitle = true : _isTranslatingDesc = true);

    try {
      final translations = await _translationService.translateContent(text);
      translations.forEach((code, translatedText) {
        if (targetControllers.containsKey(code)) {
          targetControllers[code]!.text = translatedText;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✨ ${isTitle ? 'Title' : 'Description'} Translated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Error: $e")));
    } finally {
      if (mounted) setState(() => isTitle ? _isTranslatingTitle = false : _isTranslatingDesc = false);
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = ref.read(habitMasterServiceProvider);

    final Map<String, String> localizedTitles = {};
    _localizedTitleControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedTitles[code] = controller.text.trim();
    });

    final Map<String, String> localizedDescriptions = {};
    _localizedDescControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedDescriptions[code] = controller.text.trim();
    });

    final itemToSave = HabitMasterModel(
      id: widget.itemToEdit?.id ?? '',
      name: _enTitleController.text.trim(),
      description: _enDescController.text.trim(),
      category: _selectedCategory,
      iconCode: _selectedIconCode,
      titleLocalized: localizedTitles,
      descriptionLocalized: localizedDescriptions,
    );

    try {
      await service.save(itemToSave);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(isEditing ? "Edit Habit" : "New Habit", onSave: _saveHabit, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. Basic Info ---
                        _buildPremiumCard(
                          "Basic Info", Icons.info_outline, Colors.indigo,
                          Column(
                            children: [
                              DropdownButtonFormField<HabitCategory>(
                                value: _selectedCategory,
                                decoration: _inputDec("Category", Icons.category),
                                items: HabitCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v!),
                              ),
                              const SizedBox(height: 12),
                              _buildIconSelector(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),

                        // --- 2. Title Input ---
                        _buildPremiumCard(
                          "Habit Title", Icons.title, Colors.teal,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField(_enTitleController, "Title (English)", Icons.title)),
                              const SizedBox(width: 8),
                              _buildTranslateButton(isTitle: true),
                            ],
                          ),
                        ),

                        // --- 3. Description Input ---
                        _buildPremiumCard(
                          "Habit Description", Icons.description, Colors.blue,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildMultiLineField(_enDescController, "Description (English)")),
                              const SizedBox(width: 8),
                              _buildTranslateButton(isTitle: false),
                            ],
                          ),
                        ),

                        // --- 4. Localization ---
                        _buildPremiumCard(
                          "Translations (Optional)", Icons.language, Colors.purple,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Title Localization:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildField(_localizedTitleControllers[code]!, "Title in ${supportedLanguages[code]}", Icons.language, isRequired: false),
                              )).toList(),

                              const SizedBox(height: 20),
                              const Text("Description Localization:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildMultiLineField(_localizedDescControllers[code]!, "Description in ${supportedLanguages[code]}", isRequired: false),
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
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildIconSelector() {
    final iconMap = {
      'sunny': Icons.wb_sunny, 'water': Icons.water_drop, 'book': Icons.menu_book,
      'walk': Icons.directions_walk, 'sleep': Icons.bedtime, 'phone': Icons.phonelink_erase,
      'food': Icons.restaurant, 'yoga': Icons.self_improvement, 'check': Icons.check_circle_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Icon:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: iconMap.entries.map((entry) {
            final isSelected = _selectedIconCode == entry.key;
            return GestureDetector(
              onTap: () => setState(() => _selectedIconCode = entry.key),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? Colors.indigo : Colors.transparent),
                ),
                child: Icon(entry.value, color: isSelected ? Colors.indigo : Colors.grey.shade600, size: 24),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTranslateButton({required bool isTitle}) {
    final bool isLoaderActive = isTitle ? _isTranslatingTitle : _isTranslatingDesc;

    return InkWell(
      onTap: isLoaderActive ? null : () => _performAutoTranslation(isTitle: isTitle),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigo.withOpacity(0.2)),
        ),
        child: isLoaderActive
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.translate, color: Colors.indigo, size: 20),
            Padding(padding: EdgeInsets.symmetric(horizontal: 2.0), child: FittedBox(child: Text("Auto", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.save, color: Colors.indigo, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {bool isRequired = true}) => TextFormField(
      controller: c,
      decoration: _inputDec(l, i),
      validator: (v) => isRequired && v!.isEmpty ? "Required" : null
  );

  Widget _buildMultiLineField(TextEditingController c, String l, {bool isRequired = true}) => TextFormField(
    controller: c,
    decoration: _inputDec(l, Icons.text_fields),
    maxLines: 3,
    validator: (v) => isRequired && v!.isEmpty ? "Required" : null,
  );

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}