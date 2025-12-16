import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart';

import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';

class DietPlanCategoryEntryPage extends ConsumerStatefulWidget {
  final DietPlanCategory? itemToEdit;
  const DietPlanCategoryEntryPage({super.key, this.itemToEdit});

  @override
  ConsumerState<DietPlanCategoryEntryPage> createState() => _DietPlanCategoryEntryPageState();
}

class _DietPlanCategoryEntryPageState extends ConsumerState<DietPlanCategoryEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _enController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  bool _isLoading = false;
  bool _isTranslating = false;
  final AiTranslationService _translationService = AiTranslationService();

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }

    if (widget.itemToEdit != null) {
      _enController.text = widget.itemToEdit!.name;
      widget.itemToEdit!.nameLocalized.forEach((code, name) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = name;
        }
      });
    }
  }

  @override
  void dispose() {
    _enController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _performAutoTranslation() async {
    final text = _enController.text.trim();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final service = ref.read(dietPlanCategoryServiceProvider);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });

    final itemToSave = DietPlanCategory(
      id: widget.itemToEdit?.id ?? '',
      name: _enController.text.trim(),
      nameLocalized: localizedNames,
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
    final isEdit = widget.itemToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(isEdit ? "Edit Category" : "New Category", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPremiumCard(
                          title: "Category Name",
                          icon: Icons.category,
                          color: Colors.blueAccent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField(_enController, "Name (English)", Icons.label, isRequired: true)),
                              const SizedBox(width: 8),
                              _buildTranslateButton(),
                            ],
                          ),
                        ),

                        // 🎯 Localization Card (Optional)
                        _buildPremiumCard(
                          title: "Translations (Optional)",
                          icon: Icons.language,
                          color: Colors.purple,
                          child: Column(
                            children: supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language, isRequired: false),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildTranslateButton() {
    return InkWell(
      onTap: _isTranslating ? null : _performAutoTranslation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56, width: 56,
        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.withOpacity(0.2))),
        child: _isTranslating
            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.translate, color: Colors.indigo, size: 20), Text("Auto", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.bold))]),
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.blueAccent, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {bool isRequired = true}) => TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50),
      validator: (v) => isRequired && v!.isEmpty ? "Required" : null
  );
}