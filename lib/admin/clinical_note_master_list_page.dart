// lib/master/screen/clinical_notes_master_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
// 🎯 Using correct services
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/admin/simple_item_master_model.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';

import 'clinical_notes_master_service.dart';

class ClinicalNotesMasterListPage extends ConsumerStatefulWidget {
  const ClinicalNotesMasterListPage({super.key});

  @override
  ConsumerState<ClinicalNotesMasterListPage> createState() => _ClinicalNotesMasterListPageState();
}

class _ClinicalNotesMasterListPageState extends ConsumerState<ClinicalNotesMasterListPage> {
  final TextEditingController _searchController = TextEditingController();
  // Search query is local state for stability
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to navigate to the generic entry screen for CRUD
  void navigateToEntryScreen(BuildContext context, {String? documentIdToEdit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenericClinicalMasterEntryScreen(
          entityName: MasterEntity.entity_Clinicalnotes,
          documentIdToEdit: documentIdToEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 FIX: Reading the correct services provider
    final service = ref.read(clinicalNotesMasterServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToEntryScreen(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Note Structure (SOAP/ADIME)"),

            // Search Bar logic using local setState
            _buildSearchBar(),
            const SizedBox(height: 16),

            Expanded(
              // 🎯 FIX: Expecting List<SimpleMasterItemModel> from the correct service stream
              child: StreamBuilder<List<SimpleMasterItemModel>>(
                stream: service.getClinicalNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const Center(child: Text("No clinical notes structure found."));
                  }

                  final allList = snapshot.data!;

                  // Filter Logic using local _searchQuery
                  final filteredList = _searchQuery.isEmpty
                      ? allList
                      : allList.where((item) =>
                      item.name.toLowerCase().contains(_searchQuery)
                  ).toList();

                  if(filteredList.isEmpty && allList.isNotEmpty) {
                    return Center(child: Text("No results found for \"${_searchQuery}\"."));
                  }

                  if(filteredList.isEmpty && allList.isEmpty) {
                    return const Center(child: Text("No clinical notes structure found. Tap '+' to add one."));
                  }


                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildNoteCard(context, item);
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

  // Search Bar UI
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
          // FIX: Use setState directly on change
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          decoration: InputDecoration(
            hintText: "Search notes structure...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            // Add clear button functionality using the local state
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

  // Card Style
  Widget _buildNoteCard(BuildContext context, SimpleMasterItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notes, color: Colors.blue)),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("ID: ${item.id}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
            icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: () => navigateToEntryScreen(context, documentIdToEdit: item.id)
        ),
      ),
    );
  }

  // Header Style
  Widget _buildHeader(BuildContext context, String title) {
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
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.notes, color: Colors.blueAccent)),
            ],
          ),
        ),
      ),
    );
  }
}