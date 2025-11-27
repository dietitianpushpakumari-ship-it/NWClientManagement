import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart';

class PremiumHabitSelectSheet extends StatefulWidget {
  final List<String> initialSelectedIds;

  const PremiumHabitSelectSheet({super.key, required this.initialSelectedIds});

  @override
  State<PremiumHabitSelectSheet> createState() => _PremiumHabitSelectSheetState();
}

class _PremiumHabitSelectSheetState extends State<PremiumHabitSelectSheet> {
  final HabitMasterService _service = HabitMasterService();
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  void _showAddEditDialog({HabitMasterModel? habit}) {
    final titleCtrl = TextEditingController(text: habit?.title ?? '');
    final descCtrl = TextEditingController(text: habit?.description ?? '');
    String selectedIcon = habit?.iconCode ?? 'check';
    HabitCategory selectedCat = habit?.category ?? HabitCategory.morning;

    final Map<String, IconData> iconOptions = {
      'sunny': Icons.wb_sunny, 'water': Icons.water_drop, 'book': Icons.menu_book,
      'walk': Icons.directions_walk, 'sleep': Icons.bedtime, 'phone': Icons.phonelink_erase,
      'food': Icons.restaurant, 'yoga': Icons.self_improvement, 'check': Icons.check_circle_outline,
      'run': Icons.directions_run, 'meditate': Icons.spa,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(habit == null ? "Add New Habit" : "Edit Habit"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                const Align(alignment: Alignment.centerLeft, child: Text("Category & Icon")),
                const SizedBox(height: 8),
                DropdownButtonFormField<HabitCategory>(
                  value: selectedCat,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: HabitCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => selectedCat = v!),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: iconOptions.keys.map((key) {
                    final bool isSel = selectedIcon == key;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isSel ? Colors.indigo : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(iconOptions[key], color: isSel ? Colors.white : Colors.grey, size: 20),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  _service.saveHabit(HabitMasterModel(
                    id: habit?.id ?? '',
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    iconCode: selectedIcon,
                    category: selectedCat,
                  ));
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  void _confirmDelete(HabitMasterModel habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Habit?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { _service.deleteHabit(habit.id); Navigator.pop(ctx); },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Select Daily Habits", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                FloatingActionButton.small(
                  onPressed: () => _showAddEditDialog(),
                  backgroundColor: Colors.indigo,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<HabitMasterModel>>(
              stream: _service.streamAllHabits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final habits = snapshot.data!;
                if (habits.isEmpty) return const Center(child: Text("No habits found. Add one!"));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    final habit = habits[index];
                    final isSelected = _selectedIds.contains(habit.id);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: isSelected ? Colors.green.shade50 : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(habit.iconData, color: isSelected ? Colors.green : Colors.grey),
                      ),
                      title: Text(habit.title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey.shade700)),
                      subtitle: Text(habit.category.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.indigo)),
                      trailing: PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (v) => v == 'edit' ? _showAddEditDialog(habit: habit) : _confirmDelete(habit),
                        itemBuilder: (c) => [const PopupMenuItem(value: 'edit', child: Text("Edit")), const PopupMenuItem(value: 'del', child: Text("Delete", style: TextStyle(color: Colors.red)))],
                      ),
                      onTap: () => setState(() => isSelected ? _selectedIds.remove(habit.id) : _selectedIds.add(habit.id)),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
            child: SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedIds.toList()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("CONFIRM SELECTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )),
          )
        ],
      ),
    );
  }
}