// lib/screens/guideline_list_page.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:provider/provider.dart';

class GuidelineListPage extends StatelessWidget {
  const GuidelineListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<GuidelineService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Guidelines'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<List<Guideline>>(
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
                confirmDismiss: (direction) => _showDeleteConfirmation(context, item.enTitle),
                onDismissed: (direction) => _softDelete(context, item),
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () => _navigateToEntry(context, item),
                    leading: const Icon(Icons.check_circle_outline, color: Colors.indigo),
                    title: Text(
                      item.enTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Applies to ${item.dietPlanCategoryIds.length} categories.'),
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
        backgroundColor: Colors.indigo,
        tooltip: 'Add New Guideline',
      ),
    );
  }

  void _navigateToEntry(BuildContext context, Guideline? item) {
    Navigator.of(context).push(MaterialPageRoute(builder: (c) => GuidelineEntryPage(itemToEdit: item)));
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Mark guideline '$name' as deleted?"),
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

  void _softDelete(BuildContext context, Guideline item) async {
    await Provider.of<GuidelineService>(context, listen: false).softDelete(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.enTitle} marked as deleted.')),
    );
  }
}