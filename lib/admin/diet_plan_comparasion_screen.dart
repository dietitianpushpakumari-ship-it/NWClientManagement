import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/admin/plan_report_view_screen.dart'; // Imports habitMasterProvider
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';

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
    // 1. Fetch Masters (Only Habits are in Diet Plan now)
    final habitsAsync = ref.watch(habitMasterProvider);

    final Map<String, String> habitsMaster = habitsAsync.maybeWhen(
      data: (list) => {for (var item in list) item.id: item.name},
      orElse: () => {},
    );

    // 2. Resolve Data
    final oldHabits = _resolveNames(widget.oldPlan.assignedHabitIds, habitsMaster);
    final newHabits = _resolveNames(widget.activePlan.assignedHabitIds, habitsMaster);

    // 3. Get Meal Comparisons
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

            // 🎯 NEW: Goals Comparison
            _buildSectionHeader("TARGETS & LIFESTYLE GOALS"),
            _buildGoalsTable(),

            const SizedBox(height: 32),
            _buildSectionHeader("ASSIGNED HABITS"),
            _buildDualListComparison("Habits", oldHabits, newHabits, Icons.check_circle_outline, color: Colors.teal),

            const SizedBox(height: 32),
            _buildSectionHeader("NUTRITION SCHEDULE SHIFTS"),
            _buildFoodPlanAdjustmentNotice(),

            const SizedBox(height: 20),
            // 🎯 Meal Table
            _buildMealComparisonTable(mealComparisons),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 🎯 LOGIC ---

  List<String> _resolveNames(List<String> ids, Map<String, String> masterData) {
    return ids.map((id) => masterData[id] ?? "Unknown Habit").toList();
  }

  List<Map<String, String>> _getMealComparisons(ClientDietPlanModel oldPlan, ClientDietPlanModel activePlan) {
    List<Map<String, String>> comparisons = [];

    for (int i = 0; i < activePlan.days.length; i++) {
      final activeDay = activePlan.days[i];

      // Smart Match: Match index, or fallback to first day if old plan was single-day
      MasterDayPlanModel? oldDay;
      if (i < oldPlan.days.length) {
        oldDay = oldPlan.days[i];
      } else if (oldPlan.days.length == 1) {
        oldDay = oldPlan.days.first;
      }

      if (oldDay == null) continue;

      for (var activeMeal in activeDay.meals) {
        final oldMeal = IterableExtension(oldDay.meals).firstWhereOrNull((m) => m.mealName == activeMeal.mealName);

        // Format Items string
        String _formatItems(List<DietPlanItemModel> items) {
          if (items.isEmpty) return "Skipped";
          return items.map((i) => "${i.foodItemName} (${i.quantity.toStringAsFixed(0)}${i.unit})").join(", ");
        }

        String oldItems = oldMeal != null ? _formatItems(oldMeal.items) : "Not Prescribed";
        String newItems = _formatItems(activeMeal.items);

        if (oldItems != newItems) {
          comparisons.add({
            'day': activeDay.dayName,
            'meal': activeMeal.mealName,
            'old': oldItems,
            'new': newItems,
          });
        }
      }
    }
    return comparisons;
  }

  // --- 🎯 WIDGETS ---

  Widget _buildGoalsTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: [
            _cell("METRIC", isBold: true),
            _cell("PREVIOUS", isBold: true),
            _cell("CURRENT", isBold: true),
          ],
        ),
        _buildGoalRow("Target Weight", "${widget.oldPlan.targetWeightKg ?? '-'} kg", "${widget.activePlan.targetWeightKg ?? '-'} kg"),
        _buildGoalRow("Water Intake", "${widget.oldPlan.dailyWaterGoal} L", "${widget.activePlan.dailyWaterGoal} L"),
        _buildGoalRow("Sleep Goal", "${widget.oldPlan.dailySleepGoal} hrs", "${widget.activePlan.dailySleepGoal} hrs"),
        _buildGoalRow("Step Count", "${widget.oldPlan.dailyStepGoal}", "${widget.activePlan.dailyStepGoal}"),
      ],
    );
  }

  TableRow _buildGoalRow(String label, String oldVal, String newVal) {
    bool isChanged = oldVal != newVal;
    return TableRow(
      children: [
        _cell(label, isBold: true, color: Colors.indigo),
        _cell(oldVal, color: Colors.grey.shade600),
        _cell(newVal, color: isChanged ? Colors.green.shade800 : Colors.black87, isBold: isChanged),
      ],
    );
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

  static Widget _cell(String text, {bool isBold = false, Color? color, bool isNew = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : (isNew ? FontWeight.w600 : FontWeight.normal), color: color)),
    );
  }
}