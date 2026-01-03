import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/screen/food_item_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';

class PremiumMealEntryList extends StatelessWidget {
  final DietPlanMealModel meal;
  final List<FoodItem> allFoodItems;
  final Function(List<DietPlanItemModel>) onUpdate;
  final Function(DietPlanItemModel item, DietPlanItemModel? parent) onItemTapped;
  final Function(DietPlanItemModel parent, String alternativeId) onRemoveAlternative;

  const PremiumMealEntryList({
    super.key,
    required this.meal,
    required this.allFoodItems,
    required this.onUpdate,
    required this.onItemTapped,
    required this.onRemoveAlternative,
  });

  void _addItem(FoodItem food) {
    final newItem = DietPlanItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: food.id,
      foodItemName: food.name,
      quantity: food.standardServingSizeG,
      unit: "g",
      alternatives: [],
      calories: food.caloriesPerStandardServing,
      protein: food.proteinG,
      carbs: food.carbsG,
      fat: food.fatG,
    );
    onUpdate([...meal.items, newItem]);
  }

  void _removeItem(int index) {
    final updatedList = List<DietPlanItemModel>.from(meal.items);
    updatedList.removeAt(index);
    onUpdate(updatedList);
  }

  void _showQuickSearch(BuildContext context, {DietPlanItemModel? parentItem}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickFoodSearchSheet(
        allFoods: allFoodItems,
        onSelect: (food) {
          Navigator.pop(context); // Close sheet when user manually selects an item
          if (parentItem != null) {
            final newAlternative = FoodItemAlternative(
              id: "${DateTime.now().millisecondsSinceEpoch}_alt",
              foodItemId: food.id,
              foodItemName: food.name,
              quantity: food.standardServingSizeG,
              unit: "g",
              calories: food.caloriesPerStandardServing,
              protein: food.proteinG,
              carbs: food.carbsG,
              fat: food.fatG,
            );

            final updatedParent = parentItem.copyWith(
              alternatives: [...parentItem.alternatives, newAlternative],
            );

            final updatedList = meal.items.map((item) {
              return item.id == parentItem.id ? updatedParent : item;
            }).toList();

            onUpdate(updatedList);
          } else {
            _addItem(food);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: meal.items.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: meal.items.length + 1,
            itemBuilder: (context, index) {
              if (index == meal.items.length) {
                return _buildAddButton(context);
              }
              final item = meal.items[index];
              return _buildPremiumFoodCard(context, item, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFoodCard(BuildContext context, DietPlanItemModel item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 30),
      ),
      confirmDismiss: (direction) async {
        return true;
      },
      onDismissed: (direction) {
        _removeItem(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${item.foodItemName} removed"), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            _buildFoodRow(item, isAlternative: false, parent: null),
            if (item.alternatives.isNotEmpty) ...[
              ...item.alternatives.asMap().entries.map((entry) {
                final alt = entry.value;
                final tempAltItem = DietPlanItemModel(
                  id: alt.id,
                  foodItemId: alt.foodItemId,
                  foodItemName: alt.foodItemName,
                  quantity: alt.quantity,
                  unit: alt.unit,
                  calories: alt.calories,
                  protein: alt.protein,
                  carbs: alt.carbs,
                  fat: alt.fat,
                  alternatives: [],
                );

                return Column(
                  children: [
                    _buildOrDivider(),
                    Dismissible(
                      key: Key(alt.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent.withOpacity(0.1),
                        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) {
                        onRemoveAlternative(item, alt.id);
                      },
                      child: _buildFoodRow(tempAltItem, isAlternative: true, parent: item),
                    ),
                  ],
                );
              }).toList(),
            ],
            _buildAddAlternativeAction(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodRow(DietPlanItemModel item, {required bool isAlternative, required DietPlanItemModel? parent}) {
    // 🎯 FIX: Wrap in Material to ensure InkWell works correctly on top of the white container
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print("DEBUG: Tapped on ${item.foodItemName} (Alt: $isAlternative)");
          onItemTapped(item, parent);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildMonogram(item.foodItemName, isSmall: isAlternative),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.foodItemName,
                        style: TextStyle(
                            fontWeight: isAlternative ? FontWeight.w600 : FontWeight.w800,
                            fontSize: isAlternative ? 14 : 16,
                            color: isAlternative ? Colors.grey.shade700 : Colors.black87)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniMacroLabel("P", "${item.protein.toStringAsFixed(1)}g", Colors.purple),
                        _miniMacroLabel("C", "${item.carbs.toStringAsFixed(1)}g", Colors.blue),
                        _miniMacroLabel("F", "${item.fat.toStringAsFixed(1)}g", Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${item.calories.toInt()} kcal",
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isAlternative ? Colors.grey : Colors.indigo,
                          fontSize: 15)),
                  Text("${item.quantity.toInt()}${item.unit}",
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildOrDivider() {
    return Row(
      children: [
        const SizedBox(width: 28),
        Container(width: 2, height: 20, color: Colors.indigo.withOpacity(0.1)),
        const SizedBox(width: 12),
        Text("OR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.indigo.withOpacity(0.05), thickness: 1)),
      ],
    );
  }

  Widget _buildAddAlternativeAction(BuildContext context, DietPlanItemModel parentItem) {
    return InkWell(
      onTap: () => _showQuickSearch(context, parentItem: parentItem),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.grey.shade50.withOpacity(0.5), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text("ADD ALTERNATIVE OPTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _miniMacroLabel(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [Text("$label:", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)), const SizedBox(width: 2), Text(value, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)))]),
    );
  }

  Widget _buildMonogram(String name, {bool isSmall = false}) {
    double size = isSmall ? 32 : 48;
    double fontSize = isSmall ? 14 : 20;
    double radius = isSmall ? 10 : 14;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Colors.indigo)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text("No food items added", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showQuickSearch(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text("Add First Item"),
          )
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: OutlinedButton.icon(
        onPressed: () => _showQuickSearch(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("ADD FOOD ITEM", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 54), side: BorderSide(color: Colors.indigo.withOpacity(0.3)), foregroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🎯 UPDATED QUICK SEARCH SHEET
// -----------------------------------------------------------------------------

class _QuickFoodSearchSheet extends ConsumerStatefulWidget {
  final List<FoodItem> allFoods;
  final Function(FoodItem) onSelect;

  const _QuickFoodSearchSheet({required this.allFoods, required this.onSelect});

  @override
  ConsumerState<_QuickFoodSearchSheet> createState() => _QuickFoodSearchSheetState();
}

class _QuickFoodSearchSheetState extends ConsumerState<_QuickFoodSearchSheet> {
  String _query = "";
  List<FoodItem> _filtered = [];
  // 🎯 1. Local copy of the list to support updates without closing
  List<FoodItem> _localAllFoods = [];

  @override
  void initState() {
    super.initState();
    // Initialize local copy from widget prop
    _localAllFoods = List.from(widget.allFoods);
    _filtered = _localAllFoods;
  }

  void _filter(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? _localAllFoods
          : _localAllFoods
          .where((f) => f.name.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<void> _navigateToCreatePage() async {
    // Navigate to the full entry page and wait for result
    final newItem = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodItemEntryPage(), // No itemToEdit = Create Mode
      ),
    );

    // If an item was returned (saved successfully)
    if (newItem != null && mounted) {
      // 🎯 2. Add to local list and update UI (DO NOT POP)
      setState(() {
        _localAllFoods.add(newItem);
        // Optional: Sort to keep list tidy
        _localAllFoods.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });

      // Refresh filter so the new item shows up if it matches search
      _filter(_query);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newItem.name} added to list"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: Column(
        children: [
          Center(
              child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search Food Items...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: const Color(0xFFF8F9FE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: _filter,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
            child: InkWell(
              onTap: _navigateToCreatePage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo.withOpacity(0.1))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                        "Can't find '$_query'? Create New Food",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final food = _filtered[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  tileColor: const Color(0xFFF8F9FE),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${food.caloriesPerStandardServing.toInt()} kcal per ${food.standardServingSizeG}g", style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.add_circle, color: Colors.indigo),
                  // This is the selection tap, which will close the sheet
                  onTap: () => widget.onSelect(food),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}