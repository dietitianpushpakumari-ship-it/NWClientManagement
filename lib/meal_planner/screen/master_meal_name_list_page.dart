
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/models/meal_master_name.dart';
import 'package:nutricare_client_management/meal_planner/screen/master_meal_name_entry_page.dart';
import 'package:nutricare_client_management/meal_planner/service/master_meal_name_service.dart';
import 'package:provider/provider.dart';


class MasterMealNameListPage extends StatelessWidget {
  const MasterMealNameListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming the service is provided higher up the widget tree
    final service = Provider.of<MasterMealNameService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Meal Names'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: StreamBuilder<List<MasterMealName>>(
        stream: service.streamAllActive(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                    leading: const Icon(Icons.rice_bowl, color: Colors.orange),
                    title: Text(
                      item.enName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ID: ${item.id} | Translations: ${item.nameLocalized.length}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
        backgroundColor: Colors.orange.shade700,
        tooltip: 'Add New Meal Name',
      ),
    );
  }

  void _navigateToEntry(BuildContext context, MasterMealName? item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => MasterMealNameEntryPage(itemToEdit: item)));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Mark Meal Name '$name' as deleted?"),
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

  void _softDelete(BuildContext context, MasterMealName item) async {
    await Provider.of<MasterMealNameService>(context, listen: false).softDelete(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.enName} marked as deleted.')),
    );
  }
}