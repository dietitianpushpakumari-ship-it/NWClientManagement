import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/ai_translation_service.dart';
import 'package:nutricare_client_management/core/localization/language_config.dart';

// --- NEW COMPONENT: Dedicated Dialog for Editing/Adding with Translations ---

class _MasterEntryDialog<T> extends ConsumerStatefulWidget {
  final String itemLabel;
  final T? itemToEdit;
  final String Function(T) getName;
  final Future<void> Function(String name, Map<String, String> localizedNames) onAdd;
  final Future<void> Function(T item, String newName, Map<String, String> localizedNames) onEdit;

  const _MasterEntryDialog({
    required this.itemLabel,
    this.itemToEdit,
    required this.getName,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  ConsumerState<_MasterEntryDialog<T>> createState() => _MasterEntryDialogState<T>();
}

class _MasterEntryDialogState<T> extends ConsumerState<_MasterEntryDialog<T>> {
  final TextEditingController _enNameController = TextEditingController();
  final Map<String, TextEditingController> _localizedControllers = {};
  final AiTranslationService _translationService = AiTranslationService();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    // Initialize localized controllers
    for (var code in supportedLanguageCodes) {
      if (code != 'en') _localizedControllers[code] = TextEditingController();
    }

    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit as dynamic; // Use dynamic to access name properties
      _enNameController.text = widget.getName(widget.itemToEdit as T);

      // Pre-fill existing translations (assuming the master model has a `nameLocalized` map)
      final existingLocalized = item.nameLocalized ?? {};
      existingLocalized.forEach((code, name) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = name;
        }
      });
    }
  }

  @override
  void dispose() {
    _enNameController.dispose();
    _localizedControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _performAutoTranslation() async {
    final text = _enNameController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTranslating = true);
    try {
      final translations = await _translationService.translateContent(text);
      translations.forEach((code, translatedText) {
        if (_localizedControllers.containsKey(code)) {
          _localizedControllers[code]!.text = translatedText;
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ Translation Complete!"), duration: Duration(milliseconds: 1000)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Translation Failed: $e")));
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final String name = _enNameController.text.trim();
    final Map<String, String> localizedNames = {
      for (var entry in _localizedControllers.entries)
        if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim()
    };

    try {
      if (widget.itemToEdit != null) {
        await widget.onEdit(widget.itemToEdit as T, name, localizedNames);
      } else {
        await widget.onAdd(name, localizedNames);
      }
      if (mounted) Navigator.pop(context); // Success: Close dialog
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemToEdit != null;
    return AlertDialog(
      title: Text(isEdit ? "Edit ${widget.itemLabel}" : "Add New ${widget.itemLabel}"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. English Input + Translate
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _enNameController,
                      autofocus: true,
                      decoration: InputDecoration(labelText: "${widget.itemLabel} Name (English)", border: const OutlineInputBorder()),
                      validator: (v) => v!.trim().isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isTranslating ? null : _performAutoTranslation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.indigo.withOpacity(0.2))),
                      child: _isTranslating
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.translate, color: Colors.indigo, size: 20), Text("Auto", style: TextStyle(fontSize: 9, color: Colors.indigo, fontWeight: FontWeight.bold))]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Localized Inputs
              ...supportedLanguageCodes.where((c) => c != 'en').map((code) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _localizedControllers[code],
                  decoration: InputDecoration(labelText: "${widget.itemLabel} in ${supportedLanguages[code]}"),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isEdit ? "Save Changes" : "Add"),
        ),
      ],
    );
  }
}

// --- MASTER SELECT SHEET (Parent) ---

/// A reusable premium sheet for multi-selecting items from a master list.
/// Supports Add, Edit, Delete, Search, and Multi-select.
class PremiumMasterSelectSheet<T> extends StatefulWidget {
  final String title;
  final String itemLabel; // e.g. "Diagnosis", "Complaint"

  // Data Source
  final Stream<List<T>> stream;

  // Mappers
  final String Function(T) getName;
  final String Function(T) getId;

  // Actions (Updated to accept localized names map)
  final Future<void> Function(String name, Map<String, String> localizedNames) onAdd;
  final Future<void> Function(T item, String newName, Map<String, String> localizedNames) onEdit;
  final Future<void> Function(T item) onDelete;

  // Initial State
  final List<String> selectedIds; // IDs of currently selected items

  const PremiumMasterSelectSheet({
    super.key,
    required this.title,
    required this.itemLabel,
    required this.stream,
    required this.getName,
    required this.getId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.selectedIds,
  });

  @override
  State<PremiumMasterSelectSheet<T>> createState() => _PremiumMasterSelectSheetState<T>();
}

class _PremiumMasterSelectSheetState<T> extends State<PremiumMasterSelectSheet<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  Set<String> _selectedIds = {};
  String _query = "";

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedIds);
  }

  void _showAddEditDialog({T? item}) {
    showDialog(
      context: context,
      builder: (ctx) => _MasterEntryDialog<T>(
        itemLabel: widget.itemLabel,
        itemToEdit: item,
        getName: widget.getName,
        onAdd: widget.onAdd,
        onEdit: widget.onEdit,
      ),
    ).then((_) {
      // Clear search after add/edit to ensure the new item appears
      if (_searchCtrl.text.isNotEmpty) {
        _searchCtrl.clear();
        setState(() => _query = "");
      }
    });
  }

  void _confirmDelete(T item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete '${widget.getName(item)}' from master list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await widget.onDelete(item);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  // Pass back the final list of selected IDs
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                ),
              ],
            ),
          ),

          // 2. Search & Add Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search or Add...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: () => _showAddEditDialog(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. List
          Expanded(
            child: StreamBuilder<List<T>>(
              stream: widget.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final allItems = snapshot.data ?? [];
                final filtered = _query.isEmpty
                    ? allItems
                    : allItems.where((i) => widget.getName(i).toLowerCase().contains(_query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text("No ${widget.itemLabel} found.", style: const TextStyle(color: Colors.grey)),
                        if (_query.isNotEmpty)
                          TextButton(onPressed: () => _showAddEditDialog(), child: Text("Create '$_query'"))
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final id = widget.getId(item);
                    final name = widget.getName(item);
                    final isSelected = _selectedIds.contains(id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                            onSelected: (v) => v == 'edit' ? _showAddEditDialog(item: item) : _confirmDelete(item),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text("Edit")),
                              const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) _selectedIds.remove(id);
                          else _selectedIds.add(id);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 4. Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedIds.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Done (${_selectedIds.length} Selected)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}