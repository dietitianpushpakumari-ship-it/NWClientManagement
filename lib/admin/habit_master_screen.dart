import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/habit_master_model.dart';
import 'package:nutricare_client_management/admin/habit_master_service.dart';

class HabitMasterScreen extends StatefulWidget {
  const HabitMasterScreen({super.key});

  @override
  State<HabitMasterScreen> createState() => _HabitMasterScreenState();
}

class _HabitMasterScreenState extends State<HabitMasterScreen> {
  final HabitMasterService _service = HabitMasterService();

  void _addEditHabit([HabitMasterModel? habit]) {
    // Note: Assuming a dialog logic exists or simple add here.
    // For premium flow, we usually use the bottom sheet we built earlier or a dialog.
    // Stub for now as the logic was mainly in the widget in previous steps.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // floatingActionButton: FloatingActionButton(onPressed: () => _addEditHabit(), backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.add, color: Colors.white)),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Habit Master"),
            Expanded(
              child: StreamBuilder<List<HabitMasterModel>>(
                stream: _service.streamAllHabits(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final list = snapshot.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                        child: ListTile(
                          leading: Icon(item.iconData, color: Theme.of(context).colorScheme.primary),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(item.category.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, size: 24)),
        const SizedBox(width: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}