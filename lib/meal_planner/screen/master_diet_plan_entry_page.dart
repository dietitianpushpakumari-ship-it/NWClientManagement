// lib/screens/master_diet_plan_entry_page.dart

import 'package:flutter/material.dart';

import '../models/master_diet_plan_model.dart';

// Note: MasterDietPlanModel, FoodItem, MasterMealName are imported via their file

// --- PLACEHOLDER MODELS/SERVICES (From master_diet_plan_service.dart) ---
class DietPlanCategory { final String id; final String enName; DietPlanCategory({required this.id, required this.enName});}
class MasterDietPlanService {
  // Mock save method
  Future<void> savePlan(MasterDietPlanModel plan) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // print('Mock Save: ${plan.enName}');
  }
}
class DependencyServices {
  List<DietPlanCategory> fetchAllActiveCategories() => [DietPlanCategory(id: 'cat1', enName: 'Weight Loss')];
  Future<List<FoodItem>> fetchAllActiveFoodItems() async {
    return const [
      FoodItem(id: 'f1', enName: 'Oats', servingUnitId: 'g', standardServingSizeG: 40, caloriesPerStandardServing: 150, proteinG: 5, carbsG: 27, fatG: 3),
      FoodItem(id: 'f2', enName: 'Egg White', servingUnitId: 'pc', standardServingSizeG: 30, caloriesPerStandardServing: 17, proteinG: 3.5, carbsG: 0.3, fatG: 0.1),
      FoodItem(id: 'f3', enName: 'Whey Protein', servingUnitId: 'g', standardServingSizeG: 30, caloriesPerStandardServing: 120, proteinG: 25, carbsG: 3, fatG: 1.5),
    ];
  }
  Map<String, MasterMealName> getMealNameCache() => {
    'm1': const MasterMealName(id: 'm1', enName: 'Breakfast'),
    'm2': const MasterMealName(id: 'm2', enName: 'Lunch'),
  };
}


class MasterDietPlanEntryPage_old extends StatefulWidget {
  final MasterDietPlanModel? planToEdit;

  const MasterDietPlanEntryPage_old({super.key, this.planToEdit});

  @override
  State<MasterDietPlanEntryPage_old> createState() => _MasterDietPlanEntryPage_oldState();
}

class _MasterDietPlanEntryPage_oldState extends State<MasterDietPlanEntryPage_old> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategoryId;
  List<DietPlanCategory> _categories = [];
  List<MasterMealName> _masterMealNames = [];

  // Updated map structure to hold the new group model
  Map<String, List<MealFoodItemOptionGroup>> _mealPlanData = {}; // Key: MasterMealName.id
  bool _isLoading = true;

  late TabController _tabController;
  final MasterDietPlanService _service = MasterDietPlanService();
  final DependencyServices _deps = DependencyServices();


  @override
  void initState() {
    super.initState();
    _loadDependencies().then((_) {
      if (widget.planToEdit != null) {
        _initializeForEdit(widget.planToEdit!);
      } else {
        // Initialize map with empty lists for all meals
        for(var mealName in _masterMealNames) {
          _mealPlanData[mealName.id] = [];
        }
      }
      _setupTabController();
      setState(() => _isLoading = false);
    });
  }

  Future<void> _loadDependencies() async {
    _categories = _deps.fetchAllActiveCategories();
    _masterMealNames = _deps.getMealNameCache().values.toList();
  }

  void _initializeForEdit(MasterDietPlanModel plan) {
    _nameController.text = plan.enName;
    _descController.text = plan.description;
    _selectedCategoryId = plan.categoryId;

    // Populate _mealPlanData from the existing plan
    for (var slot in plan.dailyPlan) {
      _mealPlanData[slot.mealName.id] = List.from(slot.foodItemGroups);
    }
  }

  void _setupTabController() {
    _tabController = TabController(
      length: _masterMealNames.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;

    setState(() => _isLoading = true);

    // 1. Construct the MealPlanSlot list from _mealPlanData
    List<MealPlanSlot> dailyPlan = [];
    for (var mealName in _masterMealNames) {
      final groups = _mealPlanData[mealName.id] ?? [];
      // Only include meal slots that have at least one food option group
      if (groups.isNotEmpty) {
        dailyPlan.add(MealPlanSlot(mealName: mealName, foodItemGroups: groups));
      }
    }

    if (dailyPlan.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan must contain at least one food option group.')));
      return;
    }

    final newPlan = MasterDietPlanModel(
      id: widget.planToEdit?.id ?? '',
      categoryId: _selectedCategoryId!,
      enName: _nameController.text.trim(),
      description: _descController.text.trim(),
      // nameLocalized is simplified for this example
      nameLocalized: {'en': _nameController.text.trim()},
      dailyPlan: dailyPlan, isActive: true,
    );

    try {
      await _service.savePlan(newPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${newPlan.enName} saved successfully!'),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save plan: $e'),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Builder Methods ---

  Widget _buildMealTabContent(MasterMealName mealName) {
    // Ensure the list is initialized
    final groups = _mealPlanData[mealName.id] ?? [];

    // Calculate total macros based on the SUM of PRIMARY items in all groups
    final mealSlot = MealPlanSlot(mealName: mealName, foodItemGroups: groups);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Summary Card (Based on primary items) ---
          Card(
            color: Colors.teal.shade50,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroStat('KCal', mealSlot.totalCalories, Colors.red),
                  _buildMacroStat('Protein', mealSlot.totalProteinG, Colors.blue),
                  _buildMacroStat('Carbs', mealSlot.totalCarbsG, Colors.green),
                  _buildMacroStat('Fat', mealSlot.totalFatG, Colors.orange),
                ],
              ),
            ),
          ),

          // --- Food Item Groups List ---
          Expanded(
            child: ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildFoodItemOptionGroupCard(mealName.id, index, group);
              },
            ),
          ),

          // --- Add New Option Group Button ---
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddOptionGroupSheet(mealName.id),
              icon: const Icon(Icons.add),
              label: Text('Add New Option Group to ${mealName.enName}'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildFoodItemOptionGroupCard(String mealId, int index, MealFoodItemOptionGroup group) {
    final FoodItem primary = group.primaryItem.foodItem;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: () => _showEditOptionGroupSheet(mealId, index, group),

        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.menu_book, color: Colors.blue.shade800),
        ),
        title: Text(
          primary.enName,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blueGrey),
        ),
        subtitle: Text(
          'Qty: ${group.primaryItem.quantityValue.toStringAsFixed(1)} ${primary.servingUnitId} | Alternatives: ${group.alternativeItems.length}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          onPressed: () => _deleteOptionGroup(mealId, index),
        ),
      ),
    );
  }

  // --- Actions ---

  void _deleteOptionGroup(String mealId, int index) {
    setState(() {
      _mealPlanData[mealId]?.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Food option group removed.')));
  }

  void _showAddOptionGroupSheet(String mealId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _FoodItemSelectionForm(
          title: 'Add Primary Food Item',
          onSave: (foodItem, quantity) {
            final primaryItem = MealFoodItem(foodItem: foodItem, quantityValue: quantity);
            final newGroup = MealFoodItemOptionGroup(primaryItem: primaryItem);
            setState(() {
              _mealPlanData[mealId]!.add(newGroup);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditOptionGroupSheet(String mealId, int index, MealFoodItemOptionGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OptionGroupManagerSheet(
        initialGroup: group,
        // The callback updates the mealPlanData map
        onSave: (updatedGroup) {
          setState(() {
            _mealPlanData[mealId]![index] = updatedGroup;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planToEdit == null ? 'Create Master Diet Plan' : 'Edit Master Diet Plan'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _savePlan,
            icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
            tooltip: 'Save Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- Main Info Form ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Plan Name (EN) *', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category *', border: OutlineInputBorder()),
                    value: _selectedCategoryId,
                    items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.enName))).toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) => v == null ? 'Category is required' : null,
                  ),
                ],
              ),
            ),
          ),

          // --- Tab Bar (Meal Slots) ---
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            tabs: _masterMealNames.map((m) => Tab(text: m.enName)).toList(),
          ),

          // --- Tab Content ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _masterMealNames.map((m) => _buildMealTabContent(m)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW Component: Option Group Manager Sheet ---

class _OptionGroupManagerSheet extends StatefulWidget {
  final MealFoodItemOptionGroup initialGroup;
  final Function(MealFoodItemOptionGroup) onSave;

  const _OptionGroupManagerSheet({
    required this.initialGroup,
    required this.onSave,
  });

  @override
  State<_OptionGroupManagerSheet> createState() => _OptionGroupManagerSheetState();
}

class _OptionGroupManagerSheetState extends State<_OptionGroupManagerSheet> {
  late MealFoodItem _primaryItem;
  late List<MealFoodItem> _alternatives;

  @override
  void initState() {
    super.initState();
    _primaryItem = widget.initialGroup.primaryItem;
    // Create a deep copy of the list to allow local modification
    _alternatives = List.from(widget.initialGroup.alternativeItems);
  }

  // Helper function to show the food selection modal for adding/editing items
  void _showFoodSelectionModal({
    required String title,
    MealFoodItem? itemToEdit,
    required Function(FoodItem, double) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _FoodItemSelectionForm(
          title: title,
          foodItemToEdit: itemToEdit?.foodItem,
          initialQuantity: itemToEdit?.quantityValue ?? 1.0,
          onSave: onSave,
        ),
      ),
    );
  }

  void _addAlternative() {
    _showFoodSelectionModal(
      title: 'Add Alternative Item',
      onSave: (foodItem, quantity) {
        final newAlternative = MealFoodItem(foodItem: foodItem, quantityValue: quantity);
        setState(() {
          _alternatives.add(newAlternative);
        });
        Navigator.pop(context);
      },
    );
  }

  void _editPrimary() {
    _showFoodSelectionModal(
      title: 'Edit Primary Item',
      itemToEdit: _primaryItem,
      onSave: (foodItem, quantity) {
        setState(() {
          _primaryItem = MealFoodItem(foodItem: foodItem, quantityValue: quantity);
        });
        Navigator.pop(context);
      },
    );
  }

  void _editAlternative(int index, MealFoodItem item) {
    _showFoodSelectionModal(
      title: 'Edit Alternative Item',
      itemToEdit: item,
      onSave: (foodItem, quantity) {
        setState(() {
          _alternatives[index] = MealFoodItem(foodItem: foodItem, quantityValue: quantity);
        });
        Navigator.pop(context);
      },
    );
  }

  void _deleteAlternative(int index) {
    setState(() {
      _alternatives.removeAt(index);
    });
  }

  void _saveGroup() {
    final updatedGroup = MealFoodItemOptionGroup(
      primaryItem: _primaryItem,
      alternativeItems: _alternatives,
    );
    widget.onSave(updatedGroup);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Food Option Group',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const Divider(color: Colors.teal),

          // --- Primary Item Display ---
          _buildItemTile(
            'Primary Item',
            _primaryItem,
            Colors.blue,
            Icons.star,
            onEdit: _editPrimary,
          ),

          const SizedBox(height: 15),
          const Text('Alternatives (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 5),

          // --- Alternatives List ---
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _alternatives.length,
              itemBuilder: (context, index) {
                final item = _alternatives[index];
                return _buildItemTile(
                  'Alternative ${index + 1}',
                  item,
                  Colors.grey,
                  Icons.change_circle_outlined,
                  onDelete: () => _deleteAlternative(index),
                  onEdit: () => _editAlternative(index, item),
                );
              },
            ),
          ),

          // --- Add Alternative Button ---
          TextButton.icon(
            onPressed: _addAlternative,
            icon: const Icon(Icons.add_circle),
            label: const Text('Add Alternative Option'),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
          const SizedBox(height: 20),

          // --- Save Button ---
          ElevatedButton.icon(
            onPressed: _saveGroup,
            icon: const Icon(Icons.save),
            label: const Text('Done Managing Group'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(String type, MealFoodItem item, Color color, IconData icon, {VoidCallback? onEdit, VoidCallback? onDelete}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        '${item.foodItem.enName} (${item.foodItem.servingUnitId})',
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: Text('Qty: ${item.quantityValue.toStringAsFixed(1)} | KCal: ${item.calculatedCalories.toStringAsFixed(0)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null) IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: onEdit),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}

// --- Modified Food Item Selection Form (with the Dropdown Fix) ---

class _FoodItemSelectionForm extends StatefulWidget {
  final FoodItem? foodItemToEdit;
  final double initialQuantity;
  final Function(FoodItem, double) onSave;
  final String title;

  const _FoodItemSelectionForm({
    super.key,
    this.foodItemToEdit,
    this.initialQuantity = 1.0,
    required this.onSave,
    this.title = 'Add Primary Food Item',
  });

  @override
  State<_FoodItemSelectionForm> createState() => _FoodItemSelectionFormState();
}

class _FoodItemSelectionFormState extends State<_FoodItemSelectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  FoodItem? _selectedFoodItem;
  List<FoodItem> _allFoodItems = [];

  double _calculatedCalories = 0.0;
  double _calculatedProteinG = 0.0;
  double _calculatedCarbsG = 0.0;
  double _calculatedFatG = 0.0;

  final DependencyServices _deps = DependencyServices();


  @override
  void initState() {
    super.initState();
    _selectedFoodItem = widget.foodItemToEdit;
    _quantityController.text = widget.initialQuantity.toString();
    _quantityController.addListener(_calculateMacros);
    _calculateMacros();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateMacros);
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateMacros() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;

    if (_selectedFoodItem == null || quantity <= 0) {
      setState(() {
        _calculatedCalories = 0.0;
        _calculatedProteinG = 0.0;
        _calculatedCarbsG = 0.0;
        _calculatedFatG = 0.0;
      });
      return;
    }

    // Calculation: (Quantity / StandardServingSize) * NutrientValue
    final standardServingSize = _selectedFoodItem!.standardServingSizeG > 0 ? _selectedFoodItem!.standardServingSizeG : 100.0;
    final multiplier = quantity / standardServingSize;

    setState(() {
      _calculatedCalories = _selectedFoodItem!.caloriesPerStandardServing * multiplier;
      _calculatedProteinG = _selectedFoodItem!.proteinG * multiplier;
      _calculatedCarbsG = _selectedFoodItem!.carbsG * multiplier;
      _calculatedFatG = _selectedFoodItem!.fatG * multiplier;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFoodItem != null) {
      final quantity = double.parse(_quantityController.text);
      widget.onSave(_selectedFoodItem!, quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the ID of the selected item for the dropdown value
    final String? selectedFoodItemId = _selectedFoodItem?.id;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Divider(color: Colors.teal),
            const SizedBox(height: 10),

            // --- Food Item Dropdown ---
            FutureBuilder<List<FoodItem>>(
              future: _deps.fetchAllActiveFoodItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No food items available.');

                _allFoodItems = snapshot.data!;
                final foodItems = _allFoodItems;

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Food Item *', border: OutlineInputBorder()),
                  value: selectedFoodItemId,
                  isExpanded: true,
                  // Use String generic type and item.id for value (THE FIX)
                  items: foodItems.map((item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.enName))).toList(),
                  onChanged: (itemId) {
                    setState(() {
                      // Find the full FoodItem object from the ID
                      _selectedFoodItem = foodItems.firstWhere((item) => item.id == itemId);
                    });
                    _calculateMacros();
                  },
                  validator: (v) => v == null ? 'Selection is required' : null,
                );
              },
            ),
            const SizedBox(height: 15),

            // --- Quantity Input ---
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity (in ${_selectedFoodItem?.servingUnitId ?? 'units'}) *',
                border: const OutlineInputBorder(),
                hintText: 'e.g., 100 or 1.5',
              ),
              validator: (v) => v!.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0
                  ? 'Valid quantity required' : null,
            ),
            const SizedBox(height: 20),

            // --- Calculated Macros Display ---
            Card(
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroStat('KCal', _calculatedCalories, Colors.red),
                    _buildMacroStat('Protein', _calculatedProteinG, Colors.blue),
                    _buildMacroStat('Carbs', _calculatedCarbsG, Colors.green),
                    _buildMacroStat('Fat', _calculatedFatG, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Save Button ---
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm Item and Quantity'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Widget _buildMacroStat(String label, double value, Color color) {
  return Column(
    children: [
      Text(
        value.toStringAsFixed(1),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}