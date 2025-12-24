import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';

// REQUIRED IMPORTS
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/database_provider.dart'; // 🎯 Needed for Firestore operations

// 🎯 1. HYBRID STREAM PROVIDER
// Accepts (CollectionPath, FieldName) to handle both Collection-based and Array-based masters.
final genericMasterListProvider = FutureProvider.family
    .autoDispose<Map<String, String>, ({String path, String field})>((ref, params) async {

  // A. SPECIAL HANDLING: Staff Master (Array in Single Doc)
  if (params.path == 'configurations/staff_master') {
    final firestore = ref.read(firestoreProvider);

    // Stream the specific document
    final stream = firestore.doc(params.path).snapshots();

    // Convert the stream to a Future (for the provider) or return stream if we used StreamProvider
    // Here we wrap the snapshot listener logic
    final doc = await stream.first;
    if (!doc.exists) return {};

    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> list = data[params.field] ?? [];

    // Convert Array ["A", "B"] -> Map {"A": "A", "B": "B"} (Key=Value for arrays)
    return {for (var e in list) e.toString(): e.toString()};
  }

  // B. STANDARD HANDLING: Collection-based Masters
  else {
    final masterService = ref.watch(masterDataServiceProvider);
    // Use the existing service to fetch collection stream (converted to Future for this example, or use StreamProvider)
    final stream = masterService.fetchMasterStream(params.path);
    return await stream.first;
  }
});

// 🎯 ALTERNATIVE: Use StreamProvider (Recommended for Real-time)
final genericMasterStreamProvider = StreamProvider.family
    .autoDispose<Map<String, String>, ({String path, String field})>((ref, params) {

  // A. SPECIAL HANDLING: Staff Master
  if (params.path == 'configurations/staff_master') {
    final firestore = ref.read(firestoreProvider);
    return firestore.doc(params.path).snapshots().map((doc) {
      if (!doc.exists) return {};
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> list = data[params.field] ?? [];
      return {for (var e in list) e.toString(): e.toString()};
    });
  }

  // B. STANDARD HANDLING
  else {
    final masterService = ref.watch(masterDataServiceProvider);
    return masterService.fetchMasterStream(params.path);
  }
});


class GenericListPageV2 extends ConsumerStatefulWidget {
  final String title;
  final String entityName;     // For Staff: Field Name (e.g. 'designations'). For Others: 'name' key.
  final String collectionPath; // For Staff: 'configurations/staff_master'.

  const GenericListPageV2({
    super.key,
    required this.title,
    required this.entityName,
    required this.collectionPath,
  });

  @override
  ConsumerState<GenericListPageV2> createState() => _GenericListPageV2State();
}

class _GenericListPageV2State extends ConsumerState<GenericListPageV2> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  bool get _isStaffMaster => widget.collectionPath == 'configurations/staff_master';

  // --- ACTIONS ---

  // 1. ADD ITEM
  void _handleAdd() {
    if (_isStaffMaster) {
      _showSimpleDialog(); // 🎯 Simple Dialog for Array String
    } else {
      _navigateToEntryScreen(); // 🎯 Full Screen for Documents
    }
  }

  // 2. EDIT ITEM
  void _handleEdit(String key, String value) {
    if (_isStaffMaster) {
      _showSimpleDialog(initialValue: value, oldVal: value);
    } else {
      _navigateToEntryScreen(documentIdToEdit: value); // For Docs, 'value' is usually the ID
    }
  }

  // 3. DELETE ITEM
  Future<void> _handleDelete(String key, String value) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete '$key'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      if (_isStaffMaster) {
        // 🎯 SPECIAL: Array Remove
        await ref.read(firestoreProvider).doc(widget.collectionPath).update({
          widget.entityName: FieldValue.arrayRemove([key]) // Key is the string value itself
        });
      } else {
        // 🎯 STANDARD: Document Delete
        // Ensure we delete by ID (passed as 'value' in the map)
        await ref.read(firestoreProvider).collection(widget.collectionPath).doc(value).delete();
      }
    }
  }

  // --- DIALOGS & NAVIGATION ---

  void _navigateToEntryScreen({String? documentIdToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenericClinicalMasterEntryScreen(
          entityName: widget.entityName, // Pass 'entity_giSymptom' etc.
          documentIdToEdit: documentIdToEdit,
        ),
      ),
    );
  }

  void _showSimpleDialog({String? initialValue, String? oldVal}) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initialValue == null ? "Add New" : "Edit Item"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: widget.title,
            border: const OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newVal = controller.text.trim();
              if (newVal.isEmpty) return;

              Navigator.pop(ctx);
              final docRef = ref.read(firestoreProvider).doc(widget.collectionPath);

              if (oldVal != null) {
                // 🎯 EDIT: Remove Old, Add New (Atomic Batch not strict req here)
                final batch = ref.read(firestoreProvider).batch();
                batch.update(docRef, {widget.entityName: FieldValue.arrayRemove([oldVal])});
                batch.update(docRef, {widget.entityName: FieldValue.arrayUnion([newVal])});
                await batch.commit();
              } else {
                // 🎯 ADD: Array Union
                await docRef.update({widget.entityName: FieldValue.arrayUnion([newVal])});
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    // 🎯 Use the Stream Provider
    final streamAsync = ref.watch(genericMasterStreamProvider((
    path: widget.collectionPath,
    field: widget.entityName
    )));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAdd,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, widget.title),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: streamAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Error: $err")),
                data: (allMap) {
                  final allEntries = allMap.entries.toList();

                  // Filter
                  final filteredEntries = _searchQuery.isEmpty
                      ? allEntries
                      : allEntries.where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                  if (filteredEntries.isEmpty) {
                    return Center(child: Text("No items found in ${widget.title}"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredEntries[index];
                      // For Staff Masters: Key=Name, Value=Name
                      // For Collections: Key=Name, Value=ID
                      return _buildGenericCard(context, item.key, item.value);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... [Keep _buildSearchBar and _buildHeader exactly as they were] ...

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: "Search ${widget.title}...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = "");
            })
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildGenericCard(BuildContext context, String itemName, String valueId) {
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: accentColor.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.label_important_outline, color: accentColor)
        ),
        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: !_isStaffMaster // Only show ID for collection docs
            ? Text("ID: $valueId", style: TextStyle(color: Colors.grey.shade600, fontSize: 10))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: accentColor),
              onPressed: () => _handleEdit(itemName, valueId),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _handleDelete(itemName, valueId),
            ),
          ],
        ),
      ),
    );
  }

  // Header Style (Cloned from working page)
  Widget _buildHeader(BuildContext context, String title) {
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accentColor.withOpacity(.1), shape: BoxShape.circle), child: Icon(Icons.list_alt, color: accentColor)),
            ],
          ),
        ),
      ),
    );
  }
}