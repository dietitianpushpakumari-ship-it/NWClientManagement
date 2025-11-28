import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';

class MasterDietPlanListScreen extends StatefulWidget {
  const MasterDietPlanListScreen({super.key});

  @override
  State<MasterDietPlanListScreen> createState() => _MasterDietPlanListScreenState();
}

class _MasterDietPlanListScreenState extends State<MasterDietPlanListScreen> {
  final MasterDietPlanService _service = MasterDietPlanService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterDietPlanEntryPage())),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Template", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, "Diet Templates"),
                Expanded(
                  child: StreamBuilder<List<MasterDietPlanModel>>(
                    stream: _service.streamAllPlans(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      final list = snapshot.data ?? [];
                      if (list.isEmpty) return const Center(child: Text("No templates found."));

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final plan = list[index];
                          return Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.description, color: Colors.teal)),
                              title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(plan.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterDietPlanEntryPage(initialPlan: plan)))),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}