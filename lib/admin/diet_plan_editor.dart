import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/premium_food_detail_sheet.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/client/screen/premium_meal_entry_list.dart';

class DietPlanEditor extends StatefulWidget {
  final List<MasterDayPlanModel> days;
  final List<FoodItem> allFoodItems;
  final double targetCalories;
  final Function(List<MasterDayPlanModel>) onDaysChanged;
  final bool isWeekly;
  final List<MasterMealName> allMealNames;

  const DietPlanEditor({
    super.key,
    required this.days,
    required this.allFoodItems,
    required this.targetCalories,
    required this.onDaysChanged,
    required this.isWeekly,
    required this.allMealNames,
  });

  @override
  State<DietPlanEditor> createState() => _DietPlanEditorState();
}

class _DietPlanEditorState extends State<DietPlanEditor> with TickerProviderStateMixin {
  TabController? _dayTabController;
  TabController? _mealTabController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant DietPlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.days.length != oldWidget.days.length) {
      _initControllers();
    }
  }

  void _initControllers() {
    if (widget.days.isEmpty) return;
    _dayTabController = TabController(length: widget.days.length, vsync: this);

    _dayTabController?.addListener(() {
      if (_dayTabController!.indexIsChanging) return;
      if (mounted) {
        setState(() {
          final meals = widget.days[_dayTabController!.index].meals;
          _mealTabController = TabController(length: meals.length, vsync: this);
        });
      }
    });

    if (widget.days.isNotEmpty && widget.days.first.meals.isNotEmpty) {
      _mealTabController = TabController(length: widget.days.first.meals.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _dayTabController?.dispose();
    _mealTabController?.dispose();
    super.dispose();
  }

  List<DietPlanMealModel> _getSortedMeals(List<DietPlanMealModel> meals) {
    final orderMap = { for (var m in widget.allMealNames) m.id : m.order };
    final sorted = List<DietPlanMealModel>.from(meals);
    sorted.sort((a, b) {
      final orderA = orderMap[a.mealNameId] ?? 999;
      final orderB = orderMap[b.mealNameId] ?? 999;
      return orderA.compareTo(orderB);
    });
    return sorted;
  }

  // --- LOGIC ---

  void _updateMealItems(String mealId, List<DietPlanItemModel> items) {
    final dayIndex = _dayTabController?.index ?? 0;
    if (dayIndex >= widget.days.length) return;

    final day = widget.days[dayIndex];
    final mealIndex = day.meals.indexWhere((m) => m.id == mealId);
    if (mealIndex == -1) return;

    final updatedMeals = List<DietPlanMealModel>.from(day.meals);
    updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(items: items);

    final updatedDays = List<MasterDayPlanModel>.from(widget.days);
    updatedDays[dayIndex] = day.copyWith(meals: updatedMeals);

    widget.onDaysChanged(updatedDays);
  }

  void _updateSingleItemInMeal(String mealId, DietPlanItemModel updatedItem) {
    final dayIndex = _dayTabController?.index ?? 0;
    final day = widget.days[dayIndex];
    final meal = day.meals.firstWhere((m) => m.id == mealId);

    final updatedItems = meal.items.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();

    _updateMealItems(mealId, updatedItems);
  }

  // --- ACTIONS ---

  // 1. Remove Alternative
  void _removeAlternative(DietPlanItemModel parent, String altId, String mealId) {
    final updatedAlts = parent.alternatives.where((a) => a.id != altId).toList();
    final updatedParent = parent.copyWith(alternatives: updatedAlts);
    _updateSingleItemInMeal(mealId, updatedParent);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alternative removed"), duration: Duration(seconds: 1))
    );
  }

  // 2. Clone Day
  void _cloneDay(int targetIndex) {
    final sourceIndex = _dayTabController?.index ?? 0;
    if (sourceIndex == targetIndex) return;

    final sourceDay = widget.days[sourceIndex];
    final targetDay = widget.days[targetIndex];

    final clonedMeals = sourceDay.meals.map((meal) {
      final clonedItems = meal.items.map((item) => item.copyWith(
          alternatives: item.alternatives.map((alt) => alt).toList()
      )).toList();
      return meal.copyWith(items: clonedItems);
    }).toList();

    final updatedDays = List<MasterDayPlanModel>.from(widget.days);
    updatedDays[targetIndex] = targetDay.copyWith(meals: clonedMeals);

    widget.onDaysChanged(updatedDays);
    _dayTabController?.animateTo(targetIndex);

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Copied ${sourceDay.dayName} to ${targetDay.dayName}"))
    );
  }

  // --- POPUPS ---

  void _onFoodItemTapped(DietPlanItemModel currentItem, String mealId) {
    final masterFood = widget.allFoodItems.firstWhere(
          (f) => f.id == currentItem.foodItemId,
      orElse: () => FoodItem(
        id: currentItem.foodItemId,
        name: currentItem.foodItemName,
        categoryId: '',
        servingUnitId: '',
        caloriesPerStandardServing: currentItem.calories,
        standardServingSizeG: currentItem.quantity,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumFoodDetailSheet(
        foodItem: masterFood,
        currentEntry: currentItem,
        onSave: (updatedItem) {
          final itemPreservingAlternatives = updatedItem.copyWith(alternatives: currentItem.alternatives);
          _updateSingleItemInMeal(mealId, itemPreservingAlternatives);
        },
      ),
    );
  }

  void _onAlternativeTapped(DietPlanItemModel tempAltItem, DietPlanItemModel parentItem, String mealId) {
    debugPrint("Opening Alternative: ${tempAltItem.foodItemName}");

    final masterFood = widget.allFoodItems.firstWhere(
          (f) => f.id == tempAltItem.foodItemId,
      orElse: () => FoodItem(
        id: tempAltItem.foodItemId,
        name: tempAltItem.foodItemName,
        categoryId: 'unknown',
        servingUnitId: 'g',
        caloriesPerStandardServing: tempAltItem.calories,
        standardServingSizeG: tempAltItem.quantity,
        proteinG: tempAltItem.protein,
        carbsG: tempAltItem.carbs,
        fatG: tempAltItem.fat,
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumFoodDetailSheet(
        foodItem: masterFood,
        currentEntry: tempAltItem,
        onSave: (updatedTempAlt) {
          // Reconstruct as Alternative
          final updatedAlternative = FoodItemAlternative(
            id: tempAltItem.id,
            foodItemId: updatedTempAlt.foodItemId,
            foodItemName: updatedTempAlt.foodItemName,
            quantity: updatedTempAlt.quantity,
            unit: updatedTempAlt.unit,
            calories: updatedTempAlt.calories,
            protein: updatedTempAlt.protein,
            carbs: updatedTempAlt.carbs,
            fat: updatedTempAlt.fat,
          );

          // Update parent's alternative list
          final updatedAlternativesList = parentItem.alternatives.map((alt) {
            return alt.id == tempAltItem.id ? updatedAlternative : alt;
          }).toList();

          // Save Parent
          final updatedParent = parentItem.copyWith(alternatives: updatedAlternativesList);
          _updateSingleItemInMeal(mealId, updatedParent);
        },
      ),
    );
  }

  // --- MACRO WIDGET ---
  Widget _buildDayMacroSummary() {
    final currentDayIndex = _dayTabController?.index ?? 0;
    if (widget.days.isEmpty || currentDayIndex >= widget.days.length) return const SizedBox();

    final currentDay = widget.days[currentDayIndex];
    double totalCal = 0;

    for (var meal in currentDay.meals) {
      for (var item in meal.items) {
        totalCal += item.calories;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daily Energy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
              Text("${totalCal.toInt()} / ${widget.targetCalories.toInt()} kcal",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (totalCal / (widget.targetCalories == 0 ? 1 : widget.targetCalories)).clamp(0.0, 1.0),
              backgroundColor: Colors.indigo.withOpacity(0.05),
              color: totalCal > widget.targetCalories ? Colors.redAccent : Colors.indigoAccent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.days.isEmpty || _dayTabController == null || _mealTabController == null) {
      return const Center(child: Text("No meals configured"));
    }

    final currentDayIndex = _dayTabController!.index;

    // Sort meals before displaying
    final rawMeals = widget.days[currentDayIndex].meals;
    final currentDayMeals = _getSortedMeals(rawMeals);

    return Column(
      children: [
        _buildDayMacroSummary(),

        // --- DAY TABS ---
        if (widget.isWeekly)
          Container(
            color: Colors.teal,
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _dayTabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: widget.days.map((d) => Tab(text: d.dayName.substring(0, 3))).toList(),
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.copy_all, color: Colors.white),
                  onSelected: _cloneDay,
                  itemBuilder: (ctx) => widget.days.asMap().entries
                      .where((e) => e.key != currentDayIndex)
                      .map((e) => PopupMenuItem(value: e.key, child: Text("Clone to ${e.value.dayName}")))
                      .toList(),
                ),
              ],
            ),
          ),

        // --- MEAL TABS ---
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            controller: _mealTabController,
            isScrollable: true,
            indicator: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(20)),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: currentDayMeals.map((m) => Tab(text: m.mealName)).toList(),
          ),
        ),

        // --- LIST ---
        Expanded(
          child: TabBarView(
            controller: _mealTabController,
            children: currentDayMeals.map((meal) => PremiumMealEntryList(
              meal: meal,
              allFoodItems: widget.allFoodItems,
              onUpdate: (items) => _updateMealItems(meal.id, items),

              // 🎯 FIX: Correctly handle taps for Main and Alternative items
              onItemTapped: (item, parent) {
                if (parent == null) {
                  _onFoodItemTapped(item, meal.id);
                } else {
                  _onAlternativeTapped(item, parent, meal.id);
                }
              },

              // 🎯 FIX: Connect remove callback
              onRemoveAlternative: (parent, altId) {
                _removeAlternative(parent, altId, meal.id);
              },
            )).toList(),
          ),
        ),
      ],
    );
  }
}