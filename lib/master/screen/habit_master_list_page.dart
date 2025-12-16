import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/screen/habit_master_entry_page.dart';

class HabitMasterListPage extends ConsumerStatefulWidget {
  const HabitMasterListPage({super.key});

  @override
  ConsumerState<HabitMasterListPage> createState() => _HabitMasterListPageState();
}

class _HabitMasterListPageState extends ConsumerState<HabitMasterListPage> {

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _deleteHabit(HabitMasterModel habit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete the habit: '${habit.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(habitMasterServiceProvider);
              await service.delete(habit.id);
              if (mounted) Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete"),
          )
        ],
      ),
    );
    if (confirm == true) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Habit Deleted.")));
    }
  }


  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // 🎯 Use ref.watch() for the stream
    final service = ref.watch(habitMasterServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        // 🎯 FAB navigates to the dedicated Entry Page for adding
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitMasterEntryPage())),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Habit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Habits Master"),

                // 🎯 Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<List<HabitMasterModel>>(
                    stream: service.streamActiveHabits(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                      final allHabits = snapshot.data ?? [];

                      // 🎯 Filter Logic
                      final filteredHabits = allHabits.where((habit) =>
                      habit.title.toLowerCase().contains(_searchQuery) ||
                          habit.description.toLowerCase().contains(_searchQuery)
                      ).toList();

                      if (filteredHabits.isEmpty) return Center(child: Text("No habits found."));

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: filteredHabits.length,
                        itemBuilder: (context, index) {
                          final habit = filteredHabits[index];
                          return _buildHabitCard(context, habit);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: "Search habit by title or description...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, HabitMasterModel habit) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.teal.withOpacity(0.4), width: 1)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(habit.iconData, color: Colors.teal)),
        title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${habit.category.name}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            if (habit.description.isNotEmpty)
              Text(habit.description, style: TextStyle(color: Colors.grey.shade700, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // 🎯 Navigate to the dedicated Entry Page for editing
              Navigator.push(context, MaterialPageRoute(builder: (_) => HabitMasterEntryPage(itemToEdit: habit)));
            } else if (value == 'delete') {
              _deleteHabit(habit);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text("Edit")),
            const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.teal.withOpacity(.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Colors.teal)),
          ]),
        ),
      ),
    );
  }
}