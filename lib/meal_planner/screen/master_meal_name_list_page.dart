import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/meal_planner/screen/master_meal_name_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class MasterMealNameListPage extends StatelessWidget {
  const MasterMealNameListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<MasterMealNameService>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Master Meal Names'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<MasterMealName>>(
          stream: service.streamAllActive(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('No meal names found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToEntry(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Meal'),
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
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
                  const SnackBar(content: Text('Reordering requires Firestore batch update.')),
                );
              },
              itemBuilder: (context, index) {
                final item = items[index];
                return KeyedSubtree(
                  key: ValueKey(item.id),
                  child: _buildMealNameCard(context, item),
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
        label: const Text("New Meal", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _navigateToEntry(BuildContext context, MasterMealName? item) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (c) => MasterMealNameEntryPage(itemToEdit: item))
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
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

  void _softDelete(BuildContext context, MasterMealName item) async {
    await Provider.of<MasterMealNameService>(context, listen: false).softDelete(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.enName} marked as deleted.')),
      );
    }
  }

  // 🎯 REVAMPED CARD BUILDER
  Widget _buildMealNameCard(BuildContext context, MasterMealName item) {
    // Helper to convert "HH:mm" 24h string to 12h format
    String formatTime(String? time) {
      if (time == null || time.isEmpty) return '';
      try {
        final parts = time.split(':');
        final dt = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        return dt.format(context);
      } catch (_) {
        return time;
      }
    }

    String timeRange = '';
    if (item.startTime != null && item.endTime != null) {
      timeRange = '${formatTime(item.startTime)} - ${formatTime(item.endTime)}';
    }

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
      confirmDismiss: (_) => _showDeleteConfirmation(context, item.enName),
      onDismissed: (_) => _softDelete(context, item),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToEntry(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Order Badge
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo.shade100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.order}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo.shade700),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.enName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (timeRange.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(timeRange, style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Edit Icon
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                  onPressed: () => _navigateToEntry(context, item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}