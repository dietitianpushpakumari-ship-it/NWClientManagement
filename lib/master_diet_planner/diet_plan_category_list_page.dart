import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_category_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
// 🎯 Ensure entry page import is correct


class DietPlanCategoryListPage extends ConsumerWidget {
  const DietPlanCategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access the service via ref.watch()
    final service = ref.watch(dietPlanCategoryServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // 🎯 FLOATING ACTION BUTTON IS THE ADD BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DietPlanCategoryEntryPage())),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Plan Categories"),
                Expanded(
                  child: StreamBuilder<List<DietPlanCategory>>(
                    stream: service.streamAllActive(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                      final items = snapshot.data ?? [];

                      if(items.isEmpty) return _buildEmptyState(context);

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildCategoryCard(context, item);
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
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildEmptyState(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("No plan categories found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Tap the '+' button below to add your first goal type.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        )
    );
  }


  Widget _buildCategoryCard(BuildContext context, DietPlanCategory item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border(left: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.category, color: Colors.blueAccent),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('ID: ${item.id}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DietPlanCategoryEntryPage(itemToEdit: item))),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
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
              Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.category, color: Colors.blueAccent)),
            ],
          ),
        ),
      ),
    );
  }
}