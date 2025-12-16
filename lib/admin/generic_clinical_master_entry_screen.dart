import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/admin/labvital/clinical_model.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

class GenericClinicalMasterEntryScreen extends ConsumerStatefulWidget {
  final String entityName;     // e.g., 'Complaint'
  final String? documentIdToEdit;

  const GenericClinicalMasterEntryScreen({
    super.key,
    required this.entityName,
    this.documentIdToEdit,
  });

  @override
  ConsumerState<GenericClinicalMasterEntryScreen> createState() => _GenericClinicalMasterEntryScreenState();
}

class _GenericClinicalMasterEntryScreenState extends ConsumerState<GenericClinicalMasterEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _enController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};

  ClinicalItemModel? _itemToEdit; // 🎯 Item fetched in initState if in edit mode
  bool _isLoading = false;
  bool _isTranslating = false;
  final AiTranslationService _aiService = AiTranslationService();

  String get collection_path => MasterCollectionMapper.getPath(widget.entityName);

  @override
  void initState() {
    super.initState();
    // Initialize translation controllers for ALL supported languages (excluding English)
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }

    // 🎯 NEW: Fetch item data if in edit mode
    if (widget.documentIdToEdit != null) {
      _fetchItemToEdit();
    }
  }

  @override
  void dispose() {
    _enController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  // 🎯 NEW: Logic to fetch item details for editing
  Future<void> _fetchItemToEdit() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(clinicalMasterServiceProvider);
      final item = await service.getItemById(
        collection_path,
        widget.documentIdToEdit!,
      );

      if (mounted) {
        setState(() {
          _itemToEdit = item;
          _enController.text = item.name;
          // Pre-fill translations
          item.nameLocalized.forEach((code, val) {
            if (_localizedControllers.containsKey(code)) {
              _localizedControllers[code]!.text = val;
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading item: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // 🎯 AI Translation Logic (Remains the same)
  Future<void> _performAutoTranslation() async {
    final text = _enController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter English name first")));
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final translations = await _aiService.translateContent(text);
      translations.forEach((code, val) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = val;
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ Auto-Translation Complete!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Error: $e")));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Map<String, String> locMap = {};
    _localizedControllers.forEach((key, ctrl) {
      if (ctrl.text.isNotEmpty) locMap[key] = ctrl.text.trim();
    });

    final item = ClinicalItemModel(
      // 🎯 Use documentIdToEdit for update/save or empty for new
      id: widget.documentIdToEdit ?? '',
      name: _enController.text.trim(),
      nameLocalized: locMap,
    );

    try {
      // 🎯 Use widget.collectionPath
      await ref.read(clinicalMasterServiceProvider).saveItem(collection_path, item);
      if (mounted) Navigator.pop(context, true); // Pop with result
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving ${widget.entityName}: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🎯 NEW: Delete logic
  Future<void> _delete() async {
    if (widget.documentIdToEdit == null || _itemToEdit == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "${_itemToEdit!.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(clinicalMasterServiceProvider).deleteItem(collection_path, widget.documentIdToEdit!);
        if (mounted) Navigator.pop(context, true); // Pop after successful delete
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting item: $e")));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isEdit = widget.documentIdToEdit != null;
    final displayTitle = isEdit ? "Edit ${widget.entityName}" : "New ${widget.entityName}";

    // Show loading for initial fetch in edit mode
    if (isEdit && _itemToEdit == null && !_isLoading) {
      // Show a message if fetching failed or data is null
      return Scaffold(appBar: AppBar(title: Text(displayTitle)), body: const Center(child: Text("Item not found or failed to load.")));
    }
    if (isEdit && _itemToEdit == null && _isLoading) {
      return Scaffold(appBar: AppBar(title: Text(displayTitle)), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          Column(
            children: [
              // 1. Custom Glass Header
              _buildHeader(displayTitle, onSave: _save, onDelete: isEdit ? _delete : null, isLoading: _isLoading), // 🎯 Added onDelete option

              // 2. Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // --- ENGLISH INPUT CARD ---
                        _buildPremiumCard(
                          title: "Primary Name",
                          icon: Icons.label,
                          color: Colors.indigo,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildField(_enController, "Name (English)", Icons.title)),
                              const SizedBox(width: 10),
                              _buildTranslateButton(),
                            ],
                          ),
                        ),

                        // --- LOCALIZED INPUTS CARD (Translated Values) ---
                        if (supportedLanguageCodes.length > 1)
                          _buildPremiumCard(
                            title: "Translations",
                            icon: Icons.language,
                            color: Colors.purple,
                            child: Column(
                              children: supportedLanguageCodes.where((c) => c != 'en').map((code) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildField(_localizedControllers[code]!, "Name in ${supportedLanguages[code]}", Icons.language),
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 30),
                        // SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                                : Text("SAVE ${widget.entityName.toUpperCase()}"),
                          ),
                        ),

                        // 🎯 Delete button for edit mode
                        if(isEdit)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                onPressed: _isLoading ? null : _delete,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.red.shade200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("DELETE ITEM"),
                              ),
                            ),
                          ),
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

  Widget _buildTranslateButton() {
    return InkWell(
      onTap: _isTranslating ? null : _performAutoTranslation,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56, width: 56,
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

  // 🎯 Custom Header (Updated to include Delete button)
  Widget _buildHeader(String title, {required VoidCallback onSave, VoidCallback? onDelete, required bool isLoading}) {
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

            // 🎯 DELETE ICON
            if (onDelete != null)
              IconButton(onPressed: isLoading ? null : onDelete, icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28)),

            // SAVE ICON
            IconButton(onPressed: isLoading ? null : onSave, icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.check_circle, color: Colors.indigo, size: 28))
          ]),
        ),
      ),
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))), child: Column(children: [Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))]), const SizedBox(height: 16), child]));
  }

  Widget _buildField(TextEditingController c, String l, IconData i) => TextFormField(controller: c, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, size: 18), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), validator: (v) => v!.isEmpty && l.contains('English') ? "Required" : null);
}