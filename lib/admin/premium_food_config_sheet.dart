import 'package:flutter/material.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';

class PremiumFoodConfigSheet extends StatefulWidget {
  final FoodItem foodItem;
  final DietPlanItemModel? currentEntry; // Existing entry if editing
  final Function(DietPlanItemModel) onSave;
  final VoidCallback? onAddAlternative; // Trigger to open food search for an 'OR' option

  const PremiumFoodConfigSheet({
    super.key,
    required this.foodItem,
    this.currentEntry,
    required this.onSave,
    this.onAddAlternative,
  });

  @override
  State<PremiumFoodConfigSheet> createState() => _PremiumFoodConfigSheetState();
}

class _PremiumFoodConfigSheetState extends State<PremiumFoodConfigSheet> {
  late double _quantity;
  late String _unitLabel;

  @override
  void initState() {
    super.initState();
    // 1. Initialize State from existing data or master defaults
    if (widget.currentEntry != null) {
      _quantity = widget.currentEntry!.quantity;
      _unitLabel = widget.currentEntry!.unit;
    } else {
      _quantity = widget.foodItem.standardServingSizeG;
      _unitLabel = "g"; // Default unit; can be mapped from master servingUnitId
    }
  }

  // 🎯 CORE CALCULATION ENGINE
  // Uses the logic defined in your FoodItem model
  Map<String, double> get _macros => widget.foodItem.calculateMacros(_quantity);

  @override
  Widget build(BuildContext context) {
    // Premium Color Palette
    const Color primaryColor = Color(0xFF3F51B5); // Indigo
    const Color accentColor = Color(0xFFFB8C00); // Orange for Calories

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💎 DRAG HANDLE
          Center(
            child: Container(
              width: 45, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),

          // 💎 HEADER: FOOD IDENTITY & CALORIE BADGE
          Row(
            children: [
              _buildMonogram(widget.foodItem.name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.foodItem.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    Text("Serving: ${widget.foodItem.standardServingSizeG.toInt()}g base",
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              _buildCalorieBadge(_macros['calories']!.toInt(), accentColor),
            ],
          ),

          const SizedBox(height: 32),

          // 💎 THE CALCULATOR: QUANTITY SELECTOR
          //
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE0E5F2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleActionButton(Icons.remove_rounded, () => _adjustQty(-10)),
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text("${_quantity.toInt()}",
                                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF1A1C1E))),
                            const SizedBox(width: 4),
                            Text(_unitLabel,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.indigo)),
                          ],
                        ),
                        const Text("ADJUST QUANTITY",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                      ],
                    ),
                    _circleActionButton(Icons.add_rounded, () => _adjustQty(10)),
                  ],
                ),
                const SizedBox(height: 20),
                // QUICK PRESETS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [0.5, 1.0, 1.5, 2.0].map((m) => _buildPresetChip(m)).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 💎 LIVE MACRO DASHBOARD
          Row(
            children: [
              _buildMacroTile("Protein", "${_macros['protein']!.toStringAsFixed(1)}g", const Color(0xFF7E57C2)),
              const SizedBox(width: 12),
              _buildMacroTile("Carbs", "${_macros['carbs']!.toStringAsFixed(1)}g", const Color(0xFF2196F3)),
              const SizedBox(width: 12),
              _buildMacroTile("Fats", "${_macros['fat']!.toStringAsFixed(1)}g", const Color(0xFFFFB300)),
            ],
          ),

          const SizedBox(height: 32),

          // 💎 FINAL ACTIONS
          Row(
            children: [
              if (widget.onAddAlternative != null)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onAddAlternative!();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Icon(Icons.alt_route_rounded, color: Colors.black87),
                  ),
                ),
              if (widget.onAddAlternative != null) const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    // Create the blueprint DietPlanItemModel for the final plan
                    final item = DietPlanItemModel(
                      id: widget.currentEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      foodItemId: widget.foodItem.id,
                      foodItemName: widget.foodItem.name,
                      quantity: _quantity,
                      unit: _unitLabel,
                      calories: _macros['calories']!,
                      protein: _macros['protein']!,
                      carbs: _macros['carbs']!,
                      fat: _macros['fat']!,
                      alternativeGroupId: widget.currentEntry?.alternativeGroupId,
                    );
                    widget.onSave(item);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text("ADD TO MEAL PLAN",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 🧩 WIDGET HELPERS ---

  void _adjustQty(double delta) {
    setState(() => _quantity = (_quantity + delta).clamp(0, 5000));
  }

  Widget _buildMonogram(String name) {
    String char = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return Container(
      width: 56, height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade700]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(char, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCalorieBadge(int val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text("$val", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1)),
          const Text("KCAL", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMacroTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _circleActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, size: 24, color: Colors.black87)),
      ),
    );
  }

  Widget _buildPresetChip(double multiplier) {
    double target = widget.foodItem.standardServingSizeG * multiplier;
    bool isSelected = _quantity == target;
    return GestureDetector(
      onTap: () => setState(() => _quantity = target),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade300),
        ),
        child: Text("${multiplier % 1 == 0 ? multiplier.toInt() : multiplier}x",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
      ),
    );
  }
}