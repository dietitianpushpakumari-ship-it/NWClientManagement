import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nutricare_client_management/helper/meal_planner/Alternative_manager.dart';
import 'package:nutricare_client_management/helper/meal_planner/food_item_entry_form.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';

class MealEntryList extends StatelessWidget {
  final DietPlanMealModel meal;
  final List<FoodItem> allFoodItems;
  final void Function(DietPlanItemModel) addItemToMeal;
  final void Function(DietPlanItemModel, FoodItemAlternative)
  addAlternativeToItem;
  final void Function(DietPlanItemModel, FoodItemAlternative)
  removeAlternativeFromItem;
  final void Function(DietPlanItemModel) removeItemFromMeal;

  const MealEntryList({
    super.key,
    required this.meal,
    required this.allFoodItems,
    required this.addItemToMeal,
    required this.addAlternativeToItem,
    required this.removeAlternativeFromItem,
    required this.removeItemFromMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: meal.items.isEmpty
              ? Center(
            child: Text(
              'No items added to ${meal.mealName}.',
              style: const TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.only(top: 8.0),
            itemCount: meal.items.length,
            itemBuilder: (context, index) {
              final item = meal.items[index];
              return _buildItemEditor(context, item);
            },
          ),
        ),
        _buildAddItemButton(context),
      ],
    );
  }

  // --- UI Builders for this section ---

  Widget _buildAddItemButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: Text('Add Food Item to ${meal.mealName}'),
        onPressed: () => _showAddItemModal(context),
        style: TextButton.styleFrom(
          foregroundColor: Colors.teal.shade600,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  Widget _buildItemEditor(BuildContext context, DietPlanItemModel item) {
    return ListTile(
      tileColor: item.alternatives.isNotEmpty ? Colors.orange.shade50 : null,
      leading: const Icon(Icons.arrow_right, color: Colors.blueGrey),
      title: Text(item.foodItemName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.quantity.toStringAsFixed(1)} ${item.unit}'),
          if (item.alternatives.isNotEmpty)
            Text(
              '${item.alternatives.length} Alternatives defined',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.repeat, color: Colors.orange.shade600),
            tooltip: 'Manage Alternatives',
            onPressed: () => _showManageAlternativesModal(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Remove Item',
            onPressed: () => removeItemFromMeal(item),
          ),
        ],
      ),
    );
  }

  // --- MODAL LAUNCHERS ---

  void _showAddItemModal(BuildContext context) async {
    final newItem = await showModalBottomSheet<DietPlanItemModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => FoodItemEntryForm(foodItems: allFoodItems),
    );

    if (newItem != null) {
      addItemToMeal(newItem);
    }
  }

  // Launch the new Manager Modal
  void _showManageAlternativesModal(BuildContext context,
      DietPlanItemModel item,) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) =>
          AlternativeManagerModal(
            item: item,
            allFoodItems: allFoodItems,
            // Pass the necessary callbacks from the main state
            onAddAlternative: (alternative) =>
                addAlternativeToItem(item, alternative),
            onRemoveAlternative: (alternative) =>
                removeAlternativeFromItem(item, alternative),
          ),
    );
  }
}
