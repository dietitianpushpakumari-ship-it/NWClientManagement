import 'package:flutter/material.dart';

import 'habit_master_model.dart';
import 'habit_master_service.dart';

class HabitMasterScreen extends StatefulWidget {
  const HabitMasterScreen({super.key});

  @override
  State<HabitMasterScreen> createState() => _HabitMasterScreenState();
}

class _HabitMasterScreenState extends State<HabitMasterScreen> {
  final HabitMasterService _service = HabitMasterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Habit Library")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<HabitMasterModel>>(
        stream: _service.streamAllHabits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No habits defined yet."));
          }

          final habits = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: habits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(habit.iconData, color: Colors.teal),
                  ),
                  title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(habit.description),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _showEntryDialog(context, habit: habit),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- ENTRY DIALOG ---
  void _showEntryDialog(BuildContext context, {HabitMasterModel? habit}) {
    final titleCtrl = TextEditingController(text: habit?.title ?? '');
    final descCtrl = TextEditingController(text: habit?.description ?? '');
    String selectedIcon = habit?.iconCode ?? 'check';
    HabitCategory selectedCat = habit?.category ?? HabitCategory.morning;

    final Map<String, IconData> iconOptions = {
      'sunny': Icons.wb_sunny,
      'water': Icons.water_drop,
      'book': Icons.menu_book,
      'walk': Icons.directions_walk,
      'sleep': Icons.bedtime,
      'phone': Icons.phonelink_erase,
      'food': Icons.restaurant,
      'yoga': Icons.self_improvement,
      'check': Icons.check_circle_outline,
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(habit == null ? "Add New Habit" : "Edit Habit"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Habit Title (e.g. Morning Sun)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: "Short Description"),
                    ),
                    const SizedBox(height: 20),

                    // Icon Selector
                    const Align(alignment: Alignment.centerLeft, child: Text("Select Icon:", style: TextStyle(fontSize: 12, color: Colors.grey))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: iconOptions.keys.map((key) {
                        final bool isSel = selectedIcon == key;
                        return InkWell(
                          onTap: () => setState(() => selectedIcon = key),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.teal : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(iconOptions[key], color: isSel ? Colors.white : Colors.grey, size: 20),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),
                    // Category Dropdown
                    DropdownButtonFormField<HabitCategory>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: HabitCategory.values.map((c) => DropdownMenuItem(
                        value: c, child: Text(c.name.toUpperCase()),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedCat = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isEmpty) return;

                    final newHabit = HabitMasterModel(
                      id: habit?.id ?? '',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      iconCode: selectedIcon,
                      category: selectedCat,
                    );

                    _service.saveHabit(newHabit);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Save"),
                )
              ],
            );
          }
      ),
    );
  }
}