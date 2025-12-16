import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🎯 FIX 1: Import Riverpod
// ❌ REMOVED: import 'package:provider/provider.dart';

// 🎯 NEW IMPORTS
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart'; // To get programFeatureServiceProvider
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';

// 🎯 MODELS
import 'package:nutricare_client_management/models/programme_feature_model.dart';

// 🎯 SERVICES
import 'package:nutricare_client_management/modules/package/service/program_feature_service.dart';

// 🎯 FIX 2: Convert to ConsumerStatefulWidget
class ProgramFeatureEntryForm extends ConsumerStatefulWidget {
  final ProgramFeatureModel? featureToEdit;
  const ProgramFeatureEntryForm({super.key, this.featureToEdit});

  @override
  ConsumerState<ProgramFeatureEntryForm> createState() => _ProgramFeatureEntryFormState();
}

// 🎯 FIX 3: Convert State to ConsumerState
class _ProgramFeatureEntryFormState extends ConsumerState<ProgramFeatureEntryForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();

  // 🎯 TRANSLATION STATE & CONTROLLERS
  final Map<String, TextEditingController> _localizedControllers = {};
  final AiTranslationService _translationService = AiTranslationService();
  bool _isLoading = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }

    if (widget.featureToEdit != null) {
      _nameController.text = widget.featureToEdit!.name;
      widget.featureToEdit!.nameLocalized.forEach((code, name) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = name;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // 🎯 AI Translation Logic
  Future<void> _performAutoTranslation() async {
    final text = _nameController.text.trim();
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

    // 🎯 FIX 4: Access service via ref.read(provider)
    final service = ref.read(programFeatureServiceProvider);

    final Map<String, String> localizedNames = {};
    _localizedControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedNames[code] = controller.text.trim();
    });

    final itemToSave = ProgramFeatureModel(
      id: widget.featureToEdit?.id ?? '',
      name: _nameController.text.trim(),
      nameLocalized: localizedNames, // 🎯 SAVE LOCALIZED NAMES
      // Default placeholder fields if not controlled in UI
      description: widget.featureToEdit?.description ?? '',
      featureType: widget.featureToEdit?.featureType ?? 'Dietary',
    );

    try {
      // 🎯 FIX 5: Use the unified save method which correctly uses the dynamic Firestore instance
      await service.save(itemToSave);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.featureToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(isEdit ? "Edit Feature" : "New Feature", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPremiumCard(
                          "Feature Name",
                          Icons.star_outline,
                          Colors.deepPurple,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField(_nameController, "Feature Name (English)", Icons.title)),
                              const SizedBox(width: 8),
                              _buildTranslateButton(), // 🎯 Translate Button
                            ],
                          ),
                        ),

                        // 🎯 Localization Card
                        _buildPremiumCard(
                          "Translations",
                          Icons.language,
                          Colors.purple,
                          Column(
                            children: supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language),
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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.deepPurple, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(String title, IconData icon, Color color, Widget child) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }

  Widget _buildField(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty ? "Required" : null);
}