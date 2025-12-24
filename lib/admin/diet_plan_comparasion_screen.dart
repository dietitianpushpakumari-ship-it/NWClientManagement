import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';

class DietPlanComparisonScreen extends ConsumerStatefulWidget {
  final ClientDietPlanModel oldPlan;
  final ClientDietPlanModel activePlan;
  final String clientId;

  const DietPlanComparisonScreen({
    super.key,
    required this.oldPlan,
    required this.activePlan,
    required this.clientId,
  });

  @override
  ConsumerState<DietPlanComparisonScreen> createState() => _DietPlanComparisonScreenState();
}

class _DietPlanComparisonScreenState extends ConsumerState<DietPlanComparisonScreen> {

  @override
  Widget build(BuildContext context) {
    // 1. Fetch Masters
    final investigationsAsync = ref.watch(investigationMasterProvider);
    final guidelinesAsync = ref.watch(guidelineMasterProvider);
    final supplementsAsync = ref.watch(supplementMasterProvider);

    // 2. Convert to Maps
    final Map<String, String> investigationsMaster = investigationsAsync.maybeWhen(
      data: (list) => {for (var item in list) item.id: item.name},
      orElse: () => {},
    );

    final Map<String, String> guidelinesMaster = guidelinesAsync.maybeWhen(
      data: (list) => {for (var item in list) item.id: item.name},
      orElse: () => {},
    );

    final Map<String, String> supplementsMaster = supplementsAsync.maybeWhen(
      data: (list) => {for (var item in list) item.id: item.name},
      orElse: () => {},
    );

    // 3. Resolve Data
    final oldLabs = _resolveNames((widget.oldPlan.investigationIds as List?) ?? [], investigationsMaster);
    final newLabs = _resolveNames((widget.activePlan.investigationIds as List?) ?? [], investigationsMaster);

    final oldGuidelines = _resolveNames((widget.oldPlan.guidelineIds as List?) ?? [], guidelinesMaster);
    final newGuidelines = _resolveNames((widget.activePlan.guidelineIds as List?) ?? [], guidelinesMaster);

    final oldSupplements = _resolveMapToNames(widget.oldPlan.suplimentIdsMap, supplementsMaster);
    final newSupplements = _resolveMapToNames(widget.activePlan.suplimentIdsMap, supplementsMaster);

    // 🎯 NEW: Get Multi-Day Comparisons
    final mealComparisons = _getMealComparisons(widget.oldPlan, widget.activePlan);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Plan Evolution Audit"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComparisonHeader(),
            const SizedBox(height: 32),

            _buildSectionHeader("INVESTIGATIONS & GUIDELINES"),
            _buildDualListComparison("Investigations", oldLabs, newLabs, Icons.biotech),
            const SizedBox(height: 16),
            _buildDualListComparison("Guidelines", oldGuidelines, newGuidelines, Icons.gavel_rounded, color: Colors.blueGrey),

            const SizedBox(height: 32),
            _buildSectionHeader("SUPPLEMENTATION STRATEGY"),
            _buildDualListComparison("Supplements", oldSupplements, newSupplements, Icons.vaccines_outlined, color: Colors.teal),

            const SizedBox(height: 32),
            _buildSectionHeader("NUTRITION SCHEDULE SHIFTS"),
            _buildFoodPlanAdjustmentNotice(),

            const SizedBox(height: 32),
            _buildSectionHeader("MEAL PLAN ADJUSTMENTS"),
            // 🎯 NEW: Enhanced Table Builder
            _buildMealComparisonTable(mealComparisons),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 🎯 CORE LOGIC UPDATES ---

  List<Map<String, String>> _getMealComparisons(ClientDietPlanModel oldPlan, ClientDietPlanModel activePlan) {
    List<Map<String, String>> comparisons = [];

    // Loop through every day in the ACTIVE (New) plan
    for (int i = 0; i < activePlan.days.length; i++) {
      final activeDay = activePlan.days[i];

      // 🎯 Smart Match Logic:
      // If Old Plan has 7 days, match index (Mon vs Mon).
      // If Old Plan has 1 day (Fixed), compare that 1 day against ALL new days.
      dynamic oldDay;
      if (i < oldPlan.days.length) {
        oldDay = oldPlan.days[i];
      } else if (oldPlan.days.length == 1) {
        oldDay = oldPlan.days.first; // Fallback to "Fixed Day" base
      }

      if (oldDay == null) continue;

      for (var activeMeal in activeDay.meals) {
        final oldMeal = (oldDay.meals as List).firstWhereOrNull((m) => m.mealName == activeMeal.mealName);

        String oldItems = oldMeal?.items.map((i) => "${i.foodItemName} (${i.quantity}${i.unit})").join(", ") ?? "Not prescribed";
        String newItems = activeMeal.items.map((i) => "${i.foodItemName} (${i.quantity}${i.unit})").join(", ");

        // Only add if there is a change
        if (oldItems != newItems) {
          comparisons.add({
            'day': activeDay.dayName, // 🎯 Track the Day Name
            'meal': activeMeal.mealName,
            'old': oldItems,
            'new': newItems,
          });
        }
      }
    }
    return comparisons;
  }

  Widget _buildMealComparisonTable(List<Map<String, String>> comparisons) {
    if (comparisons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text("No nutrition adjustments made in this version.", style: TextStyle(fontSize: 11))),
      );
    }

    List<TableRow> rows = [];
    String? currentDay;

    // Header Row
    rows.add(
      TableRow(
        decoration: BoxDecoration(color: Colors.indigo.shade50),
        children: [
          _cell("MEAL", isBold: true),
          _cell("PREVIOUS VERSION", isBold: true),
          _cell("CURRENT ADJUSTMENT", isBold: true),
        ],
      ),
    );

    for (var comp in comparisons) {
      // 🎯 Add Section Header if Day Changes
      if (comp['day'] != currentDay) {
        currentDay = comp['day'];
        rows.add(
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Text(
                  currentDay!.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(),
              const SizedBox(),
            ],
          ),
        );
      }

      // Data Row
      rows.add(
        TableRow(
          children: [
            _cell(comp['meal']!, isBold: true, color: Colors.indigo),
            _cell(comp['old']!, color: Colors.grey.shade600),
            _cell(comp['new']!, color: Colors.black87, isNew: true),
          ],
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
      children: rows,
    );
  }

  // --- UI Helpers (Kept Same) ---

  Widget _buildDualListComparison(String title, List<String> oldList, List<String> newList, IconData icon, {Color color = Colors.indigo}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildListCard("Previous $title", oldList, Colors.blueGrey, icon),
        const SizedBox(width: 12),
        _buildListCard("Current $title", newList, color, icon, comparison: oldList),
      ],
    );
  }

  Widget _buildListCard(String title, List<String> items, Color color, IconData icon, {List<String>? comparison}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text("None assigned", style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic))
            else
              ...items.map((item) {
                final bool isNew = comparison != null && !comparison.contains(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(isNew ? Icons.add_circle : Icons.check_circle, size: 10, color: isNew ? Colors.green : color),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item, style: TextStyle(fontSize: 10, fontWeight: isNew ? FontWeight.bold : FontWeight.normal))),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _headerInfo("PAST SESSION", widget.oldPlan.name, widget.oldPlan.assignedDate?.toDate()),
        const Icon(Icons.compare_arrows, color: Colors.indigo, size: 20),
        _headerInfo("ACTIVE SESSION", widget.activePlan.name, widget.activePlan.assignedDate?.toDate()),
      ],
    );
  }

  Widget _headerInfo(String label, String name, DateTime? date) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (date != null) Text(DateFormat('dd MMM yy').format(date), style: const TextStyle(fontSize: 9, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.indigo, letterSpacing: 1)));
  }

  Widget _buildFoodPlanAdjustmentNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(children: const [Icon(Icons.restaurant_menu, color: Colors.indigo, size: 18), SizedBox(width: 12), Expanded(child: Text("Detailed food item swaps are mapped in the Nutrition Schedule for each session.", style: TextStyle(fontSize: 10, color: Colors.indigo)))]),
    );
  }

  List<String> _resolveMapToNames(Map<String, String> idMap, Map<String, String> masterData) {
    return idMap.entries.map((entry) {
      final String name = masterData[entry.key] ?? entry.key;
      final String dosage = entry.value;
      return "$name ($dosage)";
    }).toList();
  }

  List<String> _resolveNames(List<dynamic> ids, Map<String, String> masterData) {
    return ids.map((id) => masterData[id.toString()] ?? id.toString()).toList();
  }

  static Widget _cell(String text, {bool isBold = false, Color? color, bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : (isNew ? FontWeight.w600 : FontWeight.normal), color: color)),
    );
  }
}