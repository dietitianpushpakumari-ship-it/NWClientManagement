import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/food_category.dart';
import 'package:nutricare_client_management/master/screen/food_category_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';


// 🎯 FIX 1: Convert to ConsumerStatefulWidget to manage reorder state
class FoodCategoryListPage extends ConsumerStatefulWidget {
  const FoodCategoryListPage({super.key});

  @override
  ConsumerState<FoodCategoryListPage> createState() => _FoodCategoryListPageState();
}

// 🎯 FIX 2: Convert State to ConsumerState
class _FoodCategoryListPageState extends ConsumerState<FoodCategoryListPage> {
  // State to hold and manage the reorderable list
  List<FoodCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // We defer the loading and initialization of _categories to the StreamBuilder
    // to ensure the provider context is available.
  }

  // 🎯 FIX 3: Reorder logic that updates local state
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);

      // TODO: Implement actual service call here:
      // final service = ref.read(foodCategoryServiceProvider);
      // service.updateOrder(_categories.map((c) => c.id).toList());
    });
  }


  @override
  Widget build(BuildContext context) {
    // 🎯 FIX 4: Access the service via ref.watch()
    final service = ref.watch(foodCategoryServiceProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodCategoryEntryPage())),
          backgroundColor: Colors.green,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Stack(
          children: [
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
            SafeArea(
              child: Column(
                children: [
                  // 🎯 ULTRA PREMIUM HEADER
                  _buildHeader(context),
                  Expanded(
                    child: StreamBuilder<List<FoodCategory>>(
                      stream: service.streamAllActive(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      
                        final items = snapshot.data ?? [];
      
                        // 🎯 FIX 5: Initialize local state once data loads
                        if (_categories.isEmpty && items.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              _categories = items; // Initialize local state
                            });
                          });
                        }
      
                        // Use stream data if state is not initialized or when stream provides fewer items
                        final listToDisplay = _categories.isNotEmpty ? _categories : items;
      
      
                        if(listToDisplay.isEmpty) return const Center(child: Text("No food categories found."));
      
                        return ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: listToDisplay.length,
                          onReorder: _onReorder, // Use the state-managing method
                          itemBuilder: (context, index) {
                            final item = listToDisplay[index];
                            return _buildCategoryCard(context, item, index);
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
      ),
    );
  }

  // 🎯 ULTRA PREMIUM CARD (Refined for List)
  Widget _buildCategoryCard(BuildContext context, FoodCategory item, int index) {
    return Container(
      key: ValueKey(item.id), // Required for ReorderableListView
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        // Left border accent
        border: Border(left: BorderSide(color: Colors.green.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10)
          ),
          child: Center(
            child: Text(
              "${index + 1}", // Use index for display order clarity
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16),
            ),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("Order: ${item.displayOrder}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)), // Show persisted order
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FoodCategoryEntryPage(itemToEdit: item))),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 CUSTOM HEADER (Ultra Premium Glassmorphic)
  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Text("Food Categories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(.1), shape: BoxShape.circle),
                child: const Icon(Icons.category, color: Colors.green),
              )
            ],
          ),
        ),
      ),
    );
  }
}