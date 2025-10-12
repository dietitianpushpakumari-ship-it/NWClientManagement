// lib/screens/food_item_list_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/models/food_item.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_item_entry_page.dart';
import 'package:nutricare_client_management/meal_planner/service/food_item_service.dart';
import 'package:provider/provider.dart';


class FoodItemListPage extends StatelessWidget {
  const FoodItemListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FoodItemService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Food Items'),
        backgroundColor: Colors.lightGreen,
      ),
      body: StreamBuilder<List<FoodItem>>(
        stream: service.streamAllActive(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.shade700,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                ),
                confirmDismiss: (direction) => _showDeleteConfirmation(context, item.enName),
                onDismissed: (direction) => _softDelete(context, item),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () => _navigateToEntry(context, item),
                    leading: const Icon(Icons.restaurant_menu, color: Colors.lightGreen),
                    title: Text(
                      item.enName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Category ID: ${item.categoryId} | Unit ID: ${item.servingUnitId}'),
                    trailing: Text('${item.caloriesPerStandardServing.toStringAsFixed(0)} Kcal'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEntry(context, null),
        child: const Icon(Icons.add),
        backgroundColor: Colors.lightGreen,
        tooltip: 'Add New Food Item',
      ),
    );
  }

  void _navigateToEntry(BuildContext context, FoodItem? item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => FoodItemEntryPage(itemToEdit: item)));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    // ... (Deletion Confirmation Logic - Same as previous examples)
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Mark '$name' as deleted?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _softDelete(BuildContext context, FoodItem item) async {
    await Provider.of<FoodItemService>(context, listen: false).softDelete(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.enName} marked as deleted.')),
    );
  }
}