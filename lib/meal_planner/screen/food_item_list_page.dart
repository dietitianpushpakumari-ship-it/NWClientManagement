import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_item_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:provider/provider.dart';

class FoodItemListPage extends StatelessWidget {
  const FoodItemListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FoodItemService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<FoodItem>>(
                    stream: service.streamAllActive(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final items = snapshot.data!;

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item.enName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                      child: Text("${item.caloriesPerStandardServing.toInt()} Kcal", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildMacro("Pro", item.proteinG, Colors.blue),
                                    const SizedBox(width: 8),
                                    _buildMacro("Carb", item.carbsG, Colors.green),
                                    const SizedBox(width: 8),
                                    _buildMacro("Fat", item.fatG, Colors.red),
                                    const Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FoodItemEntryPage(itemToEdit: item))),
                                    )
                                  ],
                                )
                              ],
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
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodItemEntryPage())),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Food", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMacro(String label, double val, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text("$label ${val.toStringAsFixed(1)}g", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
              const Text("Food Database", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }
}