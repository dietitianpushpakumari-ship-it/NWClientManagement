import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/meal_planner/screen/serving_unit_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:provider/provider.dart';

class ServingUnitListPage extends StatelessWidget {
  const ServingUnitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<ServingUnitService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<List<ServingUnit>>(
                    stream: service.streamAllActiveUnits(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final items = snapshot.data!;
                      if (items.isEmpty) return const Center(child: Text("No units found."));

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.scale, color: Colors.teal),
                              ),
                              title: Text("${item.enName} (${item.abbreviation})", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Type: ${item.baseUnit.toUpperCase()}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServingUnitEntryPage(unitToEdit: item))),
                              ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ServingUnitEntryPage())),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Unit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Icon(Icons.arrow_back, size: 20))),
              const SizedBox(width: 16),
              const Text("Serving Units", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ),
    );
  }
}