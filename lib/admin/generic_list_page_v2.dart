// lib/admin/generic_list_page_v2.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:async';

// REQUIRED IMPORTS FOR GENERIC FUNCTIONALITY
import 'package:nutricare_client_management/admin/services/master_data_service.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';


// 1. Master List Fetcher (StreamProvider) - Stable data source, parameterized
final genericMasterListProvider =
    (String collectionPath) => StreamProvider.autoDispose<Map<String, String>>((ref) {
  final masterService = ref.watch(masterDataServiceProvider);

  try {
    return masterService.fetchMasterStream(collectionPath);
  } catch (e) {
    throw Exception('Failed to initialize stream for $collectionPath: $e');
  }
});


class GenericListPageV2 extends ConsumerStatefulWidget {
  final String title;
  final String entityName;
  final String collectionPath;

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final newQuery = _searchController.text.toLowerCase();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
      }
    });
  }

  // Helper to navigate to the generic entry screen for CRUD
  void navigateToEntryScreen(BuildContext context, {String? documentIdToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenericClinicalMasterEntryScreen(
          entityName: widget.entityName,
          documentIdToEdit: documentIdToEdit,
        ),
      ),
    ).then((_) {
      ref.invalidate(genericMasterListProvider(widget.collectionPath));
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 CRITICAL FIX: Access the underlying stream via the provider's .stream property.
    // ref.watch(provider) returns AsyncValue, which does not have a .stream getter.
    final stream = ref.watch(genericMasterListProvider(widget.collectionPath).stream);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToEntryScreen(context),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, widget.title),

            // Search Bar logic using local setState
            _buildSearchBar(),
            const SizedBox(height: 16),

            Expanded(
              // Using standard StreamBuilder with the raw stream object
              child: StreamBuilder<Map<String, String>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error fetching data: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(child: Text("No ${widget.title} found."));
                  }

                  final allMap = snapshot.data!;
                  final allEntries = allMap.entries.toList();

                  // Filter Logic using local _searchQuery
                  final filteredEntries = _searchQuery.isEmpty
                      ? allEntries
                      : allEntries.where((entry) =>
                      entry.key.toLowerCase().contains(_searchQuery)
                  ).toList();

                  if(filteredEntries.isEmpty && allEntries.isNotEmpty) {
                    return Center(child: Text("No results found for \"$_searchQuery\"."));
                  }

                  if(filteredEntries.isEmpty && allEntries.isEmpty) {
                    return Center(child: Text("No ${widget.title} found. Tap '+' to add one."));
                  }


                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final itemEntry = filteredEntries[index];
                      return _buildGenericCard(context, itemEntry.key, itemEntry.value);
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

  // Search Bar UI (Cloned from working page)
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
          decoration: InputDecoration(
            hintText: "Search ${widget.title}...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            suffixIcon: _searchQuery.isNotEmpty ?
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ) : null,
          ),
        ),
      ),
    );
  }

  // Card Style (Generic version)
  Widget _buildGenericCard(BuildContext context, String itemName, String documentId) {
    final Color accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: accentColor.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.label_important_outline, color: accentColor)),
        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("ID: $documentId", style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () => navigateToEntryScreen(context, documentIdToEdit: documentId)
        ),
      ),
    );
  }

  // Header Style (Cloned from working page)
  Widget _buildHeader(BuildContext context, String title) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;

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