import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';

class PremiumFoodDetailSheet extends StatefulWidget {
  final FoodItem foodItem;
  final DietPlanItemModel? currentEntry;
  final Function(DietPlanItemModel) onSave;
  final Function(String groupId)? onAddAlternative;
  const PremiumFoodDetailSheet({
    super.key,
    required this.foodItem,
    this.currentEntry,
    required this.onSave,
    this.onAddAlternative,
  });

  @override
  State<PremiumFoodDetailSheet> createState() => _PremiumFoodDetailSheetState();
}

class _PremiumFoodDetailSheetState extends State<PremiumFoodDetailSheet> {
  // Controllers for Bidirectional Input
  late TextEditingController _qtyController;
  late TextEditingController _calController;

  double _currentQty = 0;
  double _currentCal = 0;

  @override
  void initState() {
    super.initState();
    // Initialize values
    _currentQty = widget.currentEntry?.quantity ?? widget.foodItem.standardServingSizeG;
    _currentCal = widget.currentEntry?.calories ?? widget.foodItem.caloriesPerStandardServing;

    _qtyController = TextEditingController(text: _currentQty.toStringAsFixed(0));
    _calController = TextEditingController(text: _currentCal.toStringAsFixed(0));
  }

  // 🎯 MATH: Qty changed -> Update Calories & Macros
  void _updateByQty(String val) {
    double qty = double.tryParse(val) ?? 0;
    final macros = widget.foodItem.calculateMacros(qty);
    setState(() {
      _currentQty = qty;
      _currentCal = macros['calories']!;
      _calController.text = _currentCal.toStringAsFixed(0);
    });
  }

  // 🎯 MATH: Calories changed -> Update Qty & Macros
  void _updateByCal(String val) {
    double cal = double.tryParse(val) ?? 0;
    if (widget.foodItem.caloriesPerStandardServing > 0) {
      // Formula: (Target Cal * Standard Qty) / Standard Cal
      double qty = (cal * widget.foodItem.standardServingSizeG) / widget.foodItem.caloriesPerStandardServing;
      final macros = widget.foodItem.calculateMacros(qty);
      setState(() {
        _currentCal = cal;
        _currentQty = qty;
        _qtyController.text = _currentQty.toStringAsFixed(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final macros = widget.foodItem.calculateMacros(_currentQty);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, color: Colors.grey[300])),
          const SizedBox(height: 24),

          Text(widget.foodItem.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const Text("Bidirectional Nutritional Calculator", style: TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 30),

          // --- BIDIRECTIONAL INPUTS ---
          Row(
            children: [
              Expanded(child: _buildInputCard("Quantity (g)", _qtyController, _updateByQty, Icons.scale)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.sync_alt, color: Colors.indigo),
              ),
              Expanded(child: _buildInputCard("Calories (kcal)", _calController, _updateByCal, Icons.bolt)),
            ],
          ),

          const SizedBox(height: 30),

          // --- ALL THREE MACROS ---
          const Text("Nutritional Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMacroInfo("PROTEIN", "${macros['protein']!.toStringAsFixed(1)}g", Colors.purple),
              _buildMacroInfo("CARBS", "${macros['carbs']!.toStringAsFixed(1)}g", Colors.blue),
              _buildMacroInfo("FATS", "${macros['fat']!.toStringAsFixed(1)}g", Colors.orange),
            ],
          ),

          const SizedBox(height: 32),


          Row(
            children: [
              if (widget.onAddAlternative != null)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      // Generate or reuse Group ID
                      final groupId = widget.currentEntry?.alternativeGroupId ??
                          DateTime.now().millisecondsSinceEpoch.toString();

                      // 1. Save current item first to ensure it has the groupId
                      _handleSave(groupId);

                      // 2. Trigger search for the 'OR' option
                      widget.onAddAlternative!(groupId);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Icon(Icons.alt_route_rounded, color: Colors.indigo),
                  ),
                ),
              if (widget.onAddAlternative != null) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _handleSave(widget.currentEntry?.alternativeGroupId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("SAVE TO PLAN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  void _handleSave(String? groupId) {
    final macros = widget.foodItem.calculateMacros(_currentQty);
    final item = DietPlanItemModel(
      id: widget.currentEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      foodItemId: widget.foodItem.id,
      foodItemName: widget.foodItem.name,
      quantity: _currentQty,
      unit: widget.currentEntry?.unit ?? "g",
      calories: _currentCal,
      protein: macros['protein']!,
      carbs: macros['carbs']!,
      fat: macros['fat']!,
      alternativeGroupId: groupId, // 🎯 Link it to the group
    );
    widget.onSave(item);
    Navigator.pop(context);
  }

  Widget _buildInputCard(String label, TextEditingController controller, Function(String) onChanged, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))]),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInfo(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}