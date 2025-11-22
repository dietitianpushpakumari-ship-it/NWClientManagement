import 'package:flutter/material.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/model/food_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/meal_planner/screen/food_item_entry_page.dart';
import 'package:nutricare_client_management/modules/master/service/food_category_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/serving_unit_service.dart';
import 'package:provider/provider.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';

class FoodItemListPage extends StatefulWidget {
  const FoodItemListPage({super.key});

  @override
  State<FoodItemListPage> createState() => _FoodItemListPageState();
}

class _FoodItemListPageState extends State<FoodItemListPage> {
  // Lookup maps for readable names
  Map<String, String> _categoryNameMap = {};
  Map<String, String> _unitNameMap = {};
  bool _isLoadingReferenceData = true;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  // Fetch Categories and Units once to populate lookup maps
  Future<void> _loadReferenceData() async {
    final catService = Provider.of<FoodCategoryService>(context, listen: false);
    final unitService = Provider.of<ServingUnitService>(context, listen: false);

    final cats = await catService.streamAllActive().first;
    final units = await unitService.streamAllActiveUnits().first;

    if (mounted) {
      setState(() {
        _categoryNameMap = {for (var c in cats) c.id: c.enName};
        _unitNameMap = {for (var u in units) u.id: '${u.enName} (${u.abbreviation})'};
        _isLoadingReferenceData = false;
      });
    }
  }

  void _navigateToEntry(BuildContext context, FoodItem? item) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (c) => FoodItemEntryPage(itemToEdit: item))
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Mark '$name' as deleted?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _softDelete(BuildContext context, FoodItem item) async {
    await Provider.of<FoodItemService>(context, listen: false).softDelete(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.enName} marked as deleted.')),
      );
    }
  }

  // 🎯 REVAMPED CARD BUILDER
  Widget _buildFoodItemCard(FoodItem item) {
    final categoryName = _categoryNameMap[item.categoryId] ?? 'Unknown Category';
    final unitName = _unitNameMap[item.servingUnitId] ?? 'Unit';

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context, item.enName),
      onDismissed: (_) => _softDelete(context, item),
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToEntry(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header: Name & Calories ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.enName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(
                        '${item.caloriesPerStandardServing.toStringAsFixed(0)} Kcal',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // --- Subtitle: Category & Unit (FIXED OVERFLOW) ---
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible( // 🎯 Changed from Text to Flexible
                      child: Text(
                        categoryName,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.scale_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Flexible( // 🎯 Changed from Text to Flexible
                      child: Text(
                        '${item.standardServingSizeG} $unitName',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis, // Handle overflow
                      ),
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1),
                ),

                // --- Footer: Macro Nutrients Strip ---
                Row(
                  children: [
                    _buildMacroPill('Protein', '${item.proteinG}g', Colors.blue),
                    const SizedBox(width: 8),
                    _buildMacroPill('Carbs', '${item.carbsG}g', Colors.green),
                    const SizedBox(width: 8),
                    _buildMacroPill('Fat', '${item.fatG}g', Colors.orange),
                    const Spacer(),
                    const Icon(Icons.edit, size: 18, color: Colors.indigo),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<FoodItemService>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomGradientAppBar(
        title: const Text('Master Food Items'),
      ),
      body: SafeArea(
        child: _isLoadingReferenceData
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<List<FoodItem>>(
          stream: service.streamAllActive(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(child: Text("No food items found. Tap '+' to create."));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), // Space for FAB
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildFoodItemCard(items[index]);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEntry(context, null),
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Item", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}