import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_entry_page.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_list_screen.dart';

// Assuming PlanCycleType enum is available globally or defined in entry_page.dart
// enum PlanCycleType { singleDay, weekly }

class DietPlanCycleSelectorScreen extends ConsumerWidget {
  const DietPlanCycleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, "Choose Plan Type"),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSelectorCard(
                        context,
                        "Single Day Cycle",
                        "Design one day (Fixed Day) for simplicity. Suitable for static plans.",
                        Icons.today,
                        Colors.teal,
                            () => _navigateToEntry(context, PlanCycleType.singleDay),
                      ),
                      const SizedBox(height: 30),
                      _buildSelectorCard(
                        context,
                        "Weekly Cycle (7 Days)",
                        "Design separate meals for Monday to Sunday. Requires more detail.",
                        Icons.calendar_view_week,
                        Colors.indigo,
                            () => _navigateToEntry(context, PlanCycleType.weekly),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEntry(BuildContext context, PlanCycleType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MasterDietPlanEntryPage(
          initialCycleType: type, // Pass the chosen type
          planId: null, // Always null when creating
        ),
      ),
    );
  }

  Widget _buildSelectorCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: color.withOpacity(0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 15),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 15),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    // Reusing premium header structure
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
          ]),
        ),
      ),
    );
  }
}