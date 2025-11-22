import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_category_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class FoodCategoryListPage extends StatelessWidget {
  const FoodCategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FoodCategoryService>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Food Categories'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<FoodCategory>>(
          stream: service.streamAllActive(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No categories found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToEntry(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10),
              itemCount: items.length,
              onReorder: (int oldIndex, int newIndex) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reordering requires Firestore batch update implementation.')),
                );
              },
              itemBuilder: (context, index) {
                final item = items[index];
                // 🎯 WRAP CARD IN KEY FOR REORDERABLE LIST
                return KeyedSubtree(
                  key: ValueKey(item.id),
                  child: _buildCategoryCard(context, item),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEntry(context, null),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, FoodCategory item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.red, size: 30),
      ),
      confirmDismiss: (direction) => _showDeleteConfirmation(context, item.enName),
      onDismissed: (direction) => _softDelete(context, item),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToEntry(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Leading Order Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${item.displayOrder}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.enName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${item.nameLocalized.length} Translations',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                  onPressed: () => _navigateToEntry(context, item),
                ),
              ],
            ),
          ),
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("DELETE"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _softDelete(BuildContext context, FoodCategory item) async {
    await Provider.of<FoodCategoryService>(context, listen: false).softDelete(item.id);
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.enName} marked as deleted.')),
      );
    }
  }
}