import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';

class DietPlanComparisonScreen extends StatelessWidget {
  final ClientDietPlanModel activePlan;
  final ClientDietPlanModel oldPlan;
  final String clientName;

  const DietPlanComparisonScreen({
    super.key,
    required this.activePlan,
    required this.oldPlan,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Comparison"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopSummary(),
          const SizedBox(height: 24),
          _buildSectionTitle("Daily Goals"),
          _buildComparisonRow("Water Goal", "${oldPlan.dailyWaterGoal}L", "${activePlan.dailyWaterGoal}L"),
          _buildComparisonRow("Step Goal", "${oldPlan.dailyStepGoal}", "${activePlan.dailyStepGoal}"),
          _buildComparisonRow("Sleep Goal", "${oldPlan.dailySleepGoal}h", "${activePlan.dailySleepGoal}h"),
          _buildComparisonRow("Target Weight", "${oldPlan.targetWeightKg ?? '--'}kg", "${activePlan.targetWeightKg ?? '--'}kg"),

          const SizedBox(height: 24),
          _buildSectionTitle("Supplements & Protocols"),
          _buildSupplementComparison(),
        ],
      ),
    );
  }

  Widget _buildTopSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Comparing previous strategy vs. current plan", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
    );
  }

  Widget _buildComparisonRow(String label, String oldVal, String newVal) {
    final bool isChanged = oldVal != newVal;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: isChanged ? Colors.orange.withOpacity(0.02) : null,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.black87))),
          Expanded(flex: 2, child: Text(oldVal, style: const TextStyle(color: Colors.grey))),
          Expanded(
            flex: 2,
            child: Text(
              newVal,
              style: TextStyle(
                fontWeight: isChanged ? FontWeight.bold : FontWeight.normal,
                color: isChanged ? Colors.green : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplementComparison() {
    // Combine all supplement IDs from both plans to check for changes
    final allIds = {...oldPlan.suplimentIdsMap.keys, ...activePlan.suplimentIdsMap.keys};

    if (allIds.isEmpty) return const Text("No supplements prescribed in either plan.");

    return Column(
      children: allIds.map((id) {
        final oldDosage = oldPlan.suplimentIdsMap[id] ?? "Not prescribed";
        final newDosage = activePlan.suplimentIdsMap[id] ?? "Discontinued";
        return _buildComparisonRow("ID: $id", oldDosage, newDosage);
      }).toList(),
    );
  }
}