import 'package:flutter/material.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_entry_screen.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_model.dart';
import 'package:nutricare_client_management/meal_planner/screen/disease_master_service.dart';

class DiseaseMasterListScreen extends StatefulWidget {
  const DiseaseMasterListScreen({super.key});

  @override
  State<DiseaseMasterListScreen> createState() => _DiseaseMasterListScreenState();
}

class _DiseaseMasterListScreenState extends State<DiseaseMasterListScreen> {
  final DiseaseMasterService _service = DiseaseMasterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiseaseMasterEntryScreen())),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Conditions & Diseases"),
            Expanded(
              child: StreamBuilder<List<DiseaseMasterModel>>(
                stream: _service.getActiveDiseases(),
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
                          leading: const Icon(Icons.coronavirus, color: Colors.deepOrange),
                          title: Text(item.enName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DiseaseMasterEntryScreen(diseaseToEdit: item)))),
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