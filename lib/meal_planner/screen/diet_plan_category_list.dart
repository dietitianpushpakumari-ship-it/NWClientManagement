// lib/screens/diet_plan_category_list_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/models/diet_plan_category.dart';
import 'package:nutricare_client_management/meal_planner/screen/diet_plan_category_entry_page.dart';
import 'package:nutricare_client_management/meal_planner/service/diet_plan_category_service.dart';
import 'package:provider/provider.dart';


class DietPlanCategoryListPage extends StatelessWidget {
  const DietPlanCategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<DietPlanCategoryService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Plan Category Master'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<List<DietPlanCategory>>(
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
                    leading: const Icon(Icons.category, color: Colors.blue),
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
        backgroundColor: Colors.blue.shade800,
        tooltip: 'Add New Category',
      ),
    );
  }

  void _navigateToEntry(BuildContext context, DietPlanCategory? item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => DietPlanCategoryEntryPage(itemToEdit: item)));
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

  void _softDelete(BuildContext context, DietPlanCategory item) async {
    await Provider.of<DietPlanCategoryService>(context, listen: false).softDelete(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.enName} marked as deleted.')),
    );
  }
}