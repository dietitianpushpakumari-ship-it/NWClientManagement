import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/meal_planner/screen/guideline_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class GuidelineListPage extends StatelessWidget {
  const GuidelineListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<GuidelineService>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Master Guidelines'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Guideline>>(
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
                    Icon(Icons.rule_folder_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text(
                      'No guidelines found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToEntry(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Guideline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildGuidelineCard(context, item);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEntry(context, null),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Guideline", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGuidelineCard(BuildContext context, Guideline item) {
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
      confirmDismiss: (direction) => _showDeleteConfirmation(context, item.enTitle),
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
                // Leading Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.rule, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.enTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Applies to ${item.dietPlanCategoryIds.length} Categories',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("DELETE"),
          ),
        ],
      ),
    ) ?? false;
  }

  void _softDelete(BuildContext context, Guideline item) async {
    await Provider.of<GuidelineService>(context, listen: false).softDelete(item.id);
    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.enTitle} marked as deleted.')),
      );
    }
  }
}