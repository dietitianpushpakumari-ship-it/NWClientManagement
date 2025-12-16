import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/master/screen/master_meal_name_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
// 🎯 FIX 2: Import the global provider file (assuming masterMealNameServiceProvider is defined here)
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';


// 🎯 FIX 3: Convert to ConsumerWidget
class MasterMealNameListPage extends ConsumerWidget {
  const MasterMealNameListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎯 FIX 4: Access the service via ref.watch()
    final service = ref.watch(masterMealNameServiceProvider);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Stack(
          children: [
            Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
            SafeArea(
              child: Column(
                children: [
                  // 🎯 ULTRA PREMIUM HEADER
                  _buildHeader(context),
                  Expanded(
                    child: StreamBuilder<List<MasterMealName>>(
                      stream: service.streamAllActive(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
      
                        final items = snapshot.data ?? [];
                        // Sort by start time for logical order
                        items.sort((a, b) => (a.startTime ?? "").compareTo(b.startTime ?? ""));
      
                        if(items.isEmpty) return const Center(child: Text("No meal names found."));
      
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildMealNameCard(context, item);
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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterMealNameEntryPage())),
          backgroundColor: Colors.blueAccent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("New Meal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // 🎯 ULTRA PREMIUM CARD WIDGET (FIXED SUBTITLE)
  Widget _buildMealNameCard(BuildContext context, MasterMealName item) {
    final timeRange = "${item.startTime ?? 'N/A'} - ${item.endTime ?? 'N/A'}";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        // Left border accent
        border: Border(left: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10)
          ),
          child: Center(
            child: Text(
              item.order.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16),
            ),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        // 🎯 FIX: Display both start and end time
        subtitle: Text('Time: $timeRange', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MasterMealNameEntryPage(itemToEdit: item))),
        ),
      ),
    );
  }

  // 🎯 CUSTOM HEADER (Ultra Premium Glassmorphic)
  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: const Icon(Icons.arrow_back, size: 20)),
              ),
              const SizedBox(width: 16),
              const Expanded(child: Text("Meal Names", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)))),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(.1), shape: BoxShape.circle),
                child: const Icon(Icons.restaurant_menu, color: Colors.blueAccent),
              )
            ],
          ),
        ),
      ),
    );
  }
}