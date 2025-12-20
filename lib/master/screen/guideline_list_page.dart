import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/guidelines.dart';
import 'package:nutricare_client_management/master/screen/guideline_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart'; // Import for categories
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart'; // Service for categories

class GuidelineListPage extends ConsumerStatefulWidget {
  const GuidelineListPage({super.key});

  @override
  ConsumerState<GuidelineListPage> createState() => _GuidelineListPageState();
}

class _GuidelineListPageState extends ConsumerState<GuidelineListPage> {

  String? _selectedCategoryId;
  late Future<List<DietPlanCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future for dropdown options
    _categoriesFuture = ref.read(dietPlanCategoryServiceProvider).fetchAllActiveCategories();
  }

  // Helper to check if a guideline matches the selected filter
  bool _filterGuideline(Guideline guideline) {
    if (_selectedCategoryId == null) {
      return true;
    }
    // Check if the guideline's dietPlanCategoryIds list contains the selected ID
    return guideline.dietPlanCategoryIds.contains(_selectedCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    final _service = ref.read(guidelineServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          // 1. Ambient Glow
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),

          SafeArea(
            child: Column(
              children: [
                // 2. Ultra Premium Header
                _buildHeader(context),

                // 3. Filter Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildFilterSection(),
                ),

                // 4. List Content
                Expanded(
                  child: StreamBuilder<List<Guideline>>(
                    stream: _service.streamAllActive(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final allItems = snapshot.data!;
                      // Apply client-side filtering based on selected category ID
                      final filteredItems = allItems.where(_filterGuideline).toList();

                      if(filteredItems.isEmpty) return const Center(child: Text("No guidelines found."));

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildGuidelineCard(context, item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuidelineEntryPage())),
        backgroundColor: Colors.blueGrey,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Rule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 🎯 NEW: Filter Dropdown Section
  Widget _buildFilterSection() {
    return FutureBuilder<List<DietPlanCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)],
              border: Border.all(color: Colors.grey.shade200)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Filter by Goal Category",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('Show All Guidelines')),
                // Note: The value needs to be the category ID string for filtering the guideline list
                ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
        );
      },
    );
  }


  // 🎯 MODIFIED: Guideline List Card (Premium Style)
  Widget _buildGuidelineCard(BuildContext context, Guideline item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.blueGrey.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.rule, color: Colors.blueGrey, size: 20)),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
            "Applies to: ${item.dietPlanCategoryIds.isEmpty ? 'General' : item.dietPlanCategoryIds.join(', ')}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuidelineEntryPage(guidelineToEdit: item))),
        ),
      ),
    );
  }

  // 🎯 ULTRA PREMIUM HEADER (Glassmorphic)
  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Text("Guidelines Master", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(.1), shape: BoxShape.circle),
                child: const Icon(Icons.rule, color: Colors.blueGrey),
              )
            ],
          ),
        ),
      ),
    );
  }
}