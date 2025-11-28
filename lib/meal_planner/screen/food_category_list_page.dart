import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_category_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:provider/provider.dart';

class FoodCategoryListPage extends StatelessWidget {
  const FoodCategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FoodCategoryService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<FoodCategory>>(
                    stream: service.streamAllActive(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final items = snapshot.data!;

                      if(items.isEmpty) return const Center(child: Text("No food categories found."));

                      return ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: items.length,
                        onReorder: (oldIndex, newIndex) {}, // Add logic if needed
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                child: Text("${item.displayOrder}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                              ),
                              title: Text(item.enName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: IconButton(
                                icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FoodCategoryEntryPage(itemToEdit: item))),
                              ),
                            ),
                          );
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodCategoryEntryPage())),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              const Text("Food Categories", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }
}