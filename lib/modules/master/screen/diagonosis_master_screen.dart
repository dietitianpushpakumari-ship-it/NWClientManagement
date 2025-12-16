import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/screen/DiagonosisEntryPage.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';

class DiagnosisListPage extends ConsumerStatefulWidget {
  const DiagnosisListPage({super.key});

  @override
  ConsumerState<DiagnosisListPage> createState() => _DiagnosisListPageState();
}

class _DiagnosisListPageState extends ConsumerState<DiagnosisListPage> {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _service = ref.read(diagnosisMasterServiceProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosisEntryPage())),
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Diagnosis Master"),

            // 🎯 NEW: Search Bar
            _buildSearchBar(),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<List<DiagnosisMasterModel>>(
                stream: _service.getDiagnoses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final allList = snapshot.data!;

                  // 🎯 Filter Logic
                  final filteredList = _searchQuery.isEmpty
                      ? allList
                      : allList.where((item) =>
                      item.enName.toLowerCase().contains(_searchQuery)
                  ).toList();

                  if(filteredList.isEmpty) return const Center(child: Text("No diagnosis found."));

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildDiagnosisCard(context, item);
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

  // 🎯 NEW: Search Bar UI
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
          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          decoration: InputDecoration(
            hintText: "Search diagnosis by name...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // 🎯 MODIFIED: Card Style
  Widget _buildDiagnosisCard(BuildContext context, DiagnosisMasterModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_hospital, color: Colors.red)),
        title: Text(item.enName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: item.nameLocalized.isNotEmpty ? Text("Translated: ${item.nameLocalized.values.join(', ')}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis) : null,
        trailing: IconButton(icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiagnosisEntryPage(itemToEdit: item)))),
      ),
    );
  }

  // 🎯 MODIFIED: Header Style
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
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.local_hospital, color: Colors.redAccent)),
            ],
          ),
        ),
      ),
    );
  }
}