import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';

// 🎯 NEW IMPORTS
import 'package:nutricare_client_management/core/localization/language_config.dart';

class GuidelineEntryPage extends StatefulWidget {
  final Guideline? guidelineToEdit;
  const GuidelineEntryPage({super.key, this.guidelineToEdit});

  @override
  State<GuidelineEntryPage> createState() => _GuidelineEntryPageState();
}

class _GuidelineEntryPageState extends State<GuidelineEntryPage> {
  final _formKey = GlobalKey<FormState>();
  // 🎯 Single content controller, used as the Title/Content field
  final _enContentController = TextEditingController();

  // 🎯 TRANSLATION STATE now manages localized titles
  final Map<String, TextEditingController> _localizedTitleControllers = {};
  final AiTranslationService _translationService = AiTranslationService();
  bool _isLoading = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedTitleControllers[code] = TextEditingController();
    }

    if (widget.guidelineToEdit != null) {
      // Assuming enTitle now holds the primary content
      _enContentController.text = widget.guidelineToEdit!.name;

      // Assuming translations are now stored in 'titleLocalized'
      widget.guidelineToEdit!.nameLocalized.forEach((code, title) {
        if (_localizedTitleControllers.containsKey(code)) {
          _localizedTitleControllers[code]!.text = title;
        }
      });
    }
  }

  @override
  void dispose() {
    _enContentController.dispose();
    _localizedTitleControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // 🎯 AI Translation Logic
  Future<void> _performAutoTranslation() async {
    final text = _enContentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter English content first")));
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final translations = await _translationService.translateContent(text);
      translations.forEach((code, translatedText) {
        if (_localizedTitleControllers.containsKey(code)) {
          _localizedTitleControllers[code]!.text = translatedText;
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
    // Note: Provider.of is used here as this widget is still a StatefulWidget
    final service = Provider.of<GuidelineService>(context, listen: false);

    // Gather localized names
    final Map<String, String> localizedTitles = {};
    _localizedTitleControllers.forEach((code, controller) {
      if (controller.text.trim().isNotEmpty) localizedTitles[code] = controller.text.trim();
    });

    final itemToSave = Guideline(
      id: widget.guidelineToEdit?.id ?? '',
      name: _enContentController.text.trim(),
      nameLocalized: localizedTitles,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.guidelineToEdit != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(isEdit ? "Edit Guideline" : "New Guideline", onSave: _save, isLoading: _isLoading),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [

                        // 🎯 English Content Input (MANDATORY)
                        _buildPremiumCard(
                          "Guideline Content (Title)",
                          Icons.rule,
                          Colors.blueGrey,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🎯 Primary Content is REQUIRED
                                  Expanded(child: _buildMultiLineField(_enContentController, "Content (English)", isRequired: true)),
                                  const SizedBox(width: 8),
                                  _buildTranslateButton(),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 🎯 Localization Card (OPTIONAL)
                        _buildPremiumCard(
                          "Localized Content (Optional)",
                          Icons.language,
                          Colors.purple,
                          Column(
                            children: supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              // 🎯 Localization fields are NOT required
                              child: _buildMultiLineField(_localizedTitleControllers[code]!, "Content in ${supportedLanguages[code]}", isRequired: false),
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

  // 🎯 FIX: Added isRequired parameter
  Widget _buildMultiLineField(TextEditingController c, String l, {bool isRequired = true}) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: l, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50),
    maxLines: 5,
    // 🎯 FIX: Conditional validation
    validator: (v) => isRequired && v!.isEmpty ? "Required" : null,
  );

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
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.blueGrey, size: 28))
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