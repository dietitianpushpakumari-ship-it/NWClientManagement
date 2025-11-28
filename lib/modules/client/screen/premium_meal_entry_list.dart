import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';

class PremiumMealEntryList extends StatelessWidget {
  final DietPlanMealModel meal;
  final List<FoodItem> allFoodItems;
  final Function(List<DietPlanItemModel>) onUpdate;

  const PremiumMealEntryList({
    super.key,
    required this.meal,
    required this.allFoodItems,
    required this.onUpdate,
  });

  void _addItem(FoodItem food) {
    // Default 1 serving unit
    final newItem = DietPlanItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: food.id,
      foodItemName: food.enName,
      quantity: food.standardServingSizeG, // Default to standard
      unit: "g", // TODO: Use unit from food item
      alternatives: [],
    );
    onUpdate([...meal.items, newItem]);
  }

  void _updateItem(int index, DietPlanItemModel updated) {
    final newList = List<DietPlanItemModel>.from(meal.items);
    newList[index] = updated;
    onUpdate(newList);
  }

  void _removeItem(int index) {
    final newList = List<DietPlanItemModel>.from(meal.items);
    newList.removeAt(index);
    onUpdate(newList);
  }

  void _showQuickSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickFoodSearchSheet(
        allFoods: allFoodItems,
        onSelect: (food) {
          _addItem(food);
          Navigator.pop(context);
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: meal.items.length + 1, // +1 for Add Button at bottom
            itemBuilder: (context, index) {
              if (index == meal.items.length) {
                return _buildAddButton(context);
              }
              return _PremiumFoodCard(
                item: meal.items[index],
                allFoods: allFoodItems, // Pass all foods for alt search
                onUpdate: (updated) => _updateItem(index, updated),
                onDelete: () => _removeItem(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text("No food in ${meal.mealName}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showQuickSearch(context),
            icon: const Icon(Icons.add),
            label: const Text("Add First Item"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          )
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: OutlinedButton.icon(
        onPressed: () => _showQuickSearch(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("Add More Food"),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: Colors.teal.withOpacity(0.5)),
          foregroundColor: Colors.teal.shade700,
        ),
      ),
    );
  }
}

// --- PREMIUM FOOD CARD (The Magic Happens Here) ---

class _PremiumFoodCard extends StatefulWidget {
  final DietPlanItemModel item;
  final List<FoodItem> allFoods;
  final Function(DietPlanItemModel) onUpdate;
  final VoidCallback onDelete;

  const _PremiumFoodCard({
    required this.item,
    required this.allFoods,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_PremiumFoodCard> createState() => _PremiumFoodCardState();
}

class _PremiumFoodCardState extends State<_PremiumFoodCard> {
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _updateQuantity(String val) {
    final d = double.tryParse(val);
    if (d != null) {
      widget.onUpdate(widget.item.copyWith(quantity: d));
    }
  }

  void _addAlternative(FoodItem food) {
    final alt = FoodItemAlternative(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: food.id,
      foodItemName: food.enName,
      quantity: food.standardServingSizeG, // Smart default
      unit: "g",
    );
    final updatedAlts = List<FoodItemAlternative>.from(widget.item.alternatives)..add(alt);
    widget.onUpdate(widget.item.copyWith(alternatives: updatedAlts));
  }

  void _removeAlternative(int index) {
    final updatedAlts = List<FoodItemAlternative>.from(widget.item.alternatives)..removeAt(index);
    widget.onUpdate(widget.item.copyWith(alternatives: updatedAlts));
  }

  // Find macro info to display
  FoodItem? get _metaData => widget.allFoods.where((f) => f.id == widget.item.foodItemId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final meta = _metaData;
    // Calculate macros based on current quantity
    double ratio = widget.item.quantity / (meta?.standardServingSizeG ?? 100);
    if (ratio.isNaN || ratio.isInfinite) ratio = 0;

    final kCal = (meta?.caloriesPerStandardServing ?? 0) * ratio;
    final protein = (meta?.proteinG ?? 0) * ratio;

    return Dismissible(
      key: ValueKey(widget.item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Main Item Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.item.foodItemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMacroPill("${kCal.toStringAsFixed(0)} cal", Colors.orange),
                            const SizedBox(width: 6),
                            _buildMacroPill("${protein.toStringAsFixed(1)}g Pro", Colors.blue),
                          ],
                        )
                      ],
                    ),
                  ),
                  // Quantity Input
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                      decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          suffixText: widget.item.unit,
                          suffixStyle: const TextStyle(fontSize: 10, color: Colors.grey)
                      ),
                      onChanged: _updateQuantity,
                    ),
                  ),
                ],
              ),

              // 2. Alternatives Section (Inline)
              if (widget.item.alternatives.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.item.alternatives.asMap().entries.map((e) {
                    final index = e.key;
                    final alt = e.value;
                    return Chip(
                      label: Text("${alt.foodItemName} (${alt.quantity.toInt()})"),
                      backgroundColor: Colors.orange.shade50,
                      deleteIcon: const Icon(Icons.close, size: 16, color: Colors.orange),
                      onDeleted: () => _removeAlternative(index),
                      side: BorderSide(color: Colors.orange.shade100),
                      labelStyle: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    );
                  }).toList(),
                ),
              ],

              // 3. Add Alternative Button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => _QuickFoodSearchSheet(
                        allFoods: widget.allFoods,
                        onSelect: (food) {
                          _addAlternative(food);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Option"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

// --- INSTANT SEARCH SHEET (Fast!) ---

class _QuickFoodSearchSheet extends StatefulWidget {
  final List<FoodItem> allFoods;
  final Function(FoodItem) onSelect;

  const _QuickFoodSearchSheet({required this.allFoods, required this.onSelect});

  @override
  State<_QuickFoodSearchSheet> createState() => _QuickFoodSearchSheetState();
}

class _QuickFoodSearchSheetState extends State<_QuickFoodSearchSheet> {
  String _query = "";
  List<FoodItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.allFoods;
  }

  void _filter(String q) {
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _filtered = widget.allFoods;
      } else {
        _filtered = widget.allFoods.where((f) => f.enName.toLowerCase().contains(q.toLowerCase())).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(child: Container(margin: const EdgeInsets.only(top: 10), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                  hintText: "Search Food (e.g., Egg, Roti)...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16)
              ),
              onChanged: _filter,
            ),
          ),

          // List
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final food = _filtered[index];
                return ListTile(
                  title: Text(food.enName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("${food.caloriesPerStandardServing.toInt()} cal / ${food.standardServingSizeG}g", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
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