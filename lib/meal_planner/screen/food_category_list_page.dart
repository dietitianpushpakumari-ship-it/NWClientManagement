// lib/screens/food_category_list_page.dart

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
      appBar: AppBar(
        title: const Text('Food Category Master'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<FoodCategory>>(
        stream: service.streamAllActive(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];

          return ReorderableListView.builder( // Use ReorderableListView for ordering capability
            itemCount: items.length,
            onReorder: (int oldIndex, int newIndex) {
              // NOTE: Implementing persistent drag-and-drop reordering requires
              // updating the 'displayOrder' field for multiple documents in Firestore.
              // For a simple implementation, we'll just show the currently sorted list.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reordering logic requires Firestore batch update.')),
              );
              // If you were implementing the reorder, you would update the database here.
            },
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id), // Use ValueKey for ReorderableListView compatibility
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
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text('${item.displayOrder}', style: TextStyle(color: Colors.orange.shade800)),
                    ),
                    title: Text(
                      item.enName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Translations: ${item.nameLocalized.length}'),
                    trailing: const Icon(Icons.edit, color: Colors.blue),
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
        backgroundColor: Colors.orange,
        tooltip: 'Add New Food Category',
      ),
    );
  }

  void _navigateToEntry(BuildContext context, FoodCategory? item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => FoodCategoryEntryPage(itemToEdit: item)));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Mark category '$name' as deleted?"),
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

  void _softDelete(BuildContext context, FoodCategory item) async {
    await Provider.of<FoodCategoryService>(context, listen: false).softDelete(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.enName} marked as deleted.')),
    );
  }
}