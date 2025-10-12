// lib/screens/master_diet_plan_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

// ----------------------------------------------------------------------
// --- PLACEHOLDER MODELS/SERVICES (Synthesized for runnability) ---
// ----------------------------------------------------------------------

// Placeholder for a Diet Plan Category (e.g., Weight Loss)
class DietPlanCategory { final String id; final String enName; const DietPlanCategory({required this.id, required this.enName});}
// Placeholder for a Master Meal Name (e.g., Breakfast)
class MasterMealName { final String id; final String enName; const MasterMealName({this.id = '', this.enName = ''});}

// FoodItem (Critical: Must have operator== and hashCode for Dropdown)
class FoodItem {
  final String id; final String enName; final String servingUnitId;
  final double standardServingSizeG; final double caloriesPerStandardServing;
  final double proteinG; final double carbsG; final double fatG;

  const FoodItem({
    required this.id, required this.enName, required this.servingUnitId,
    this.standardServingSizeG = 100, this.caloriesPerStandardServing = 100,
    this.proteinG = 0, this.carbsG = 0, this.fatG = 0
  });

  @override
  bool operator ==(Object other) => other is FoodItem && other.id == id;
  @override
  int get hashCode => id.hashCode;

  Map<String, double> calculateMacros(double quantity) {
    if (standardServingSizeG == 0) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    final ratio = quantity / standardServingSizeG;
    return {
      'calories': caloriesPerStandardServing * ratio,
      'protein': proteinG * ratio,
      'carbs': carbsG * ratio,
      'fat': fatG * ratio,
    };
  }
}

// 🎯 UPDATED: Added 'id' and 'operator==' for reliable list removal
class FoodItemAlternative {
  final String id; // Unique ID for reliable removal
  final String foodItemId; final String foodItemName; final double quantity; final String unit;

  const FoodItemAlternative({
    required this.id,
    required this.foodItemId,
    required this.foodItemName,
    required this.quantity,
    required this.unit
  });

  @override
  bool operator ==(Object other) => other is FoodItemAlternative && other.id == id;
  @override
  int get hashCode => id.hashCode;

  // Added helper method for display in the manager modal
  String get displayQuantity => '${quantity.toStringAsFixed(1)} $unit';
}

class DietPlanItemModel {
  final String id; final String foodItemId; final String foodItemName; final double quantity; final String unit; final String notes; final List<FoodItemAlternative> alternatives;
  const DietPlanItemModel({required this.id, required this.foodItemId, required this.foodItemName, required this.quantity, required this.unit, this.notes = '', this.alternatives = const []});

  DietPlanItemModel copyWith({List<FoodItemAlternative>? alternatives, double? quantity}) => DietPlanItemModel(
      id: id, foodItemId: foodItemId, foodItemName: foodItemName, quantity: quantity ?? this.quantity, unit: unit, notes: notes,
      alternatives: alternatives ?? this.alternatives
  );
}

class DietPlanMealModel {
  final String id; final String mealNameId; final String mealName; final List<DietPlanItemModel> items;
  const DietPlanMealModel({required this.id, required this.mealNameId, required this.mealName, this.items = const []});

  DietPlanMealModel copyWith({List<DietPlanItemModel>? items}) => DietPlanMealModel(
      id: id, mealNameId: mealNameId, mealName: mealName, items: items ?? this.items
  );
}

class MasterDayPlanModel {
  final String id; final String dayName; final List<DietPlanMealModel> meals;
  const MasterDayPlanModel({required this.id, required this.dayName, this.meals = const []});

  MasterDayPlanModel copyWith({List<DietPlanMealModel>? meals}) => MasterDayPlanModel(
      id: id, dayName: dayName, meals: meals ?? this.meals
  );

  Map<String, double> get dayMacros {
    double calories = 0, protein = 0, carbs = 0, fat = 0;
    return {'calories': calories, 'protein': protein, 'carbs': carbs, 'fat': fat};
  }
}

class MasterDietPlanModel {
  final String id;
  final String name;
  final String description;
  final List<String> dietPlanCategoryIds;
  final List<MasterDayPlanModel> days; // Should contain only ONE fixed day

  const MasterDietPlanModel({
    this.id = '',
    this.name = '',
    this.description = '',
    this.dietPlanCategoryIds = const [],
    this.days = const [],
  });

  MasterDietPlanModel copyWith({
    String? id, String? name, String? description, List<String>? dietPlanCategoryIds, List<MasterDayPlanModel>? days,
  }) => MasterDietPlanModel(
    id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
    dietPlanCategoryIds: dietPlanCategoryIds ?? this.dietPlanCategoryIds, days: days ?? this.days,
  );
}

class DependencyServices {
  Future<List<DietPlanCategory>> fetchAllActiveCategories() async => Future.value(const [
    DietPlanCategory(id: 'cat1', enName: 'Weight Loss'),
    DietPlanCategory(id: 'cat2', enName: 'Muscle Gain'),
  ]);
  Future<List<MasterMealName>> fetchAllMealNames() async => Future.value(const [
    MasterMealName(id: 'm1', enName: 'Breakfast'), MasterMealName(id: 'm2', enName: 'Lunch'),
    MasterMealName(id: 'm3', enName: 'Dinner'), MasterMealName(id: 'm4', enName: 'Snack'),
  ]);
  Future<List<FoodItem>> fetchAllActiveFoodItems() async {
    final Random random = Random();
    String generateId() => String.fromCharCode(97 + random.nextInt(26)) + random.nextInt(9999).toString();

    return [
      FoodItem(id: generateId(), enName: 'Oats (40g=150KCal)', servingUnitId: 'g', standardServingSizeG: 40, caloriesPerStandardServing: 150, proteinG: 5, carbsG: 27, fatG: 3),
      FoodItem(id: generateId(), enName: 'Egg White (1pc=17KCal)', servingUnitId: 'pc', standardServingSizeG: 30, caloriesPerStandardServing: 17, proteinG: 3.5, carbsG: 0.3, fatG: 0.1),
      FoodItem(id: generateId(), enName: 'Broccoli (100g=34KCal)', servingUnitId: 'g', standardServingSizeG: 100, caloriesPerStandardServing: 34, proteinG: 2.8, carbsG: 6.6, fatG: 0.4),
      FoodItem(id: generateId(), enName: 'Chicken Breast (100g=165KCal)', servingUnitId: 'g', standardServingSizeG: 100, caloriesPerStandardServing: 165, proteinG: 31, carbsG: 0, fatG: 3.6),
      FoodItem(id: generateId(), enName: 'Paneer (100g=265KCal)', servingUnitId: 'g', standardServingSizeG: 100, caloriesPerStandardServing: 265, proteinG: 18, carbsG: 1.2, fatG: 20),
    ];
  }
}

class MasterDietPlanService {
  Future<void> savePlan(MasterDietPlanModel plan) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print('Plan Saved: ${plan.name} (${plan.days.first.meals.length} meals)');
  }
}
// ----------------------------------------------------------------------
// --- END PLACEHOLDERS ---
// ----------------------------------------------------------------------

class MasterDietPlanEntryPage extends StatefulWidget {
  const MasterDietPlanEntryPage({super.key});

  @override
  State<MasterDietPlanEntryPage> createState() => _MasterDietPlanEntryPageState();
}

// 🎯 FIX: Switched to TickerProviderStateMixin to allow safe re-initialization of TabController.
class _MasterDietPlanEntryPageState extends State<MasterDietPlanEntryPage> with TickerProviderStateMixin {

  // --- STATE ---
  final _formKey = GlobalKey<FormState>();

  // Change to nullable TabController
  TabController? _tabController;

  // Template Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DietPlanCategory? _selectedCategory;

  // Data for the entire screen
  MasterDietPlanModel _currentPlan = const MasterDietPlanModel();

  // Future Builders for dependencies
  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)>? _initialDataFuture;
  List<FoodItem> _allFoodItems = const [];
  List<MasterMealName> _allMealNames = const [];
  List<DietPlanCategory> _allCategories = const [];

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _fetchInitialData();
  }

  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)> _fetchInitialData() async {
    final foodItems = await DependencyServices().fetchAllActiveFoodItems();
    final mealNames = await DependencyServices().fetchAllMealNames();
    final categories = await DependencyServices().fetchAllActiveCategories();

    // Initialize the main plan structure (Single Day, all meals)
    final initialMeals = mealNames.map((m) => DietPlanMealModel(
      id: m.id,
      mealNameId: m.id,
      mealName: m.enName,
      items: [],
    )).toList();

    _currentPlan = MasterDietPlanModel(
      days: [MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals)],
    );

    // Dispose old controller before creating a new one
    if (_tabController != null) {
      _tabController!.dispose();
    }

    // Initialize Tab Controller
    _tabController = TabController(length: mealNames.length, vsync: this);

    setState(() {
      _allFoodItems = foodItems;
      _allMealNames = mealNames;
      _allCategories = categories;

      _selectedCategory = categories.isNotEmpty ? categories.first : null;
    });

    return (foodItems, mealNames, categories);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- MUTATOR METHODS ---

  // 1. Adds a new DietPlanItemModel to the currently selected meal
  void _addItemToMeal(DietPlanItemModel newItem) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // Use null-checked controller's index, safe due to FutureBuilder
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere((m) => m.id == currentMealId);
      final currentMeal = currentDay.meals[mealIndex];

      final updatedItems = List<DietPlanItemModel>.from(currentMeal.items)..add(newItem);

      final updatedMeal = currentMeal.copyWith(items: updatedItems);

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = updatedMeal;

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // 2. Adds an alternative to an existing item
  void _addAlternativeToItem(DietPlanItemModel item, FoodItemAlternative alternative) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // Use null-checked controller's index, safe due to FutureBuilder
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere((m) => m.id == currentMealId);
      final itemIndex = currentDay.meals[mealIndex].items.indexWhere((i) => i.id == item.id);
      final targetItem = currentDay.meals[mealIndex].items[itemIndex];

      final updatedAlternatives = List<FoodItemAlternative>.from(targetItem.alternatives)..add(alternative);

      final updatedItem = targetItem.copyWith(alternatives: updatedAlternatives);

      final updatedItems = List<DietPlanItemModel>.from(currentDay.meals[mealIndex].items);
      updatedItems[itemIndex] = updatedItem;

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = currentDay.meals[mealIndex].copyWith(items: updatedItems);

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // 3. Removes an alternative from an existing item
  void _removeAlternativeFromItem(DietPlanItemModel item, FoodItemAlternative alternativeToRemove) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // Use null-checked controller's index, safe due to FutureBuilder
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere((m) => m.id == currentMealId);
      final currentMeal = currentDay.meals[mealIndex];
      final itemIndex = currentMeal.items.indexWhere((i) => i.id == item.id);
      final targetItem = currentMeal.items[itemIndex];

      // Create the updated list of alternatives
      final updatedAlternatives = List<FoodItemAlternative>.from(targetItem.alternatives)
        ..removeWhere((a) => a == alternativeToRemove);

      // Recreate the item with the new alternatives list
      final updatedItem = targetItem.copyWith(alternatives: updatedAlternatives);

      // Recreate the item list for the meal
      final updatedItems = List<DietPlanItemModel>.from(currentMeal.items);
      updatedItems[itemIndex] = updatedItem;

      // Recreate the meal model
      final updatedMeal = currentMeal.copyWith(items: updatedItems);

      // Recreate the day model
      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = updatedMeal;

      // Update the main plan state
      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // 4. Removes an item from the meal
  void _removeItemFromMeal(DietPlanItemModel item) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // Use null-checked controller's index, safe due to FutureBuilder
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere((m) => m.id == currentMealId);
      final currentMeal = currentDay.meals[mealIndex];

      final updatedItems = List<DietPlanItemModel>.from(currentMeal.items)
        ..removeWhere((i) => i.id == item.id);

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = currentMeal.copyWith(items: updatedItems);

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // --- CORE LOGIC: SAVE PLAN ---
  void _savePlan() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all plan details and select a category.')));
      return;
    }

    // Finalize the model with top-level details
    final planToSave = _currentPlan.copyWith(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      dietPlanCategoryIds: [_selectedCategory!.id],
    );

    // Basic validation: Check if any meal has items
    final totalItems = planToSave.days.first.meals.fold(0, (sum, meal) => sum + meal.items.length);
    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan must contain at least one food item.')));
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving plan...')));

    try {
      await MasterDietPlanService().savePlan(planToSave);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diet Plan Template saved successfully!')));
      // Clear or navigate away on success
      setState(() {
        _nameController.clear();
        _descriptionController.clear();
        // Re-initialize state for a new entry, now safely disposing the old controller
        _initialDataFuture = _fetchInitialData();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
    }
  }


  // --- UI COMPONENTS (Unchanged) ---

  Widget _buildMasterPlanDetailsForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Plan Name (e.g., Keto 1500 KCal)'),
              validator: (value) => value!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Plan Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<DietPlanCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _allCategories.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat.enName),
              )).toList(),
              onChanged: (cat) => setState(() => _selectedCategory = cat),
              validator: (value) => value == null ? 'Select a category' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _savePlan,
        icon: const Icon(Icons.save),
        label: const Text('Save Complete Master Diet Plan'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }


  // --- MAIN WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Master Diet Plan Template')),
      body: FutureBuilder(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || _currentPlan.days.isEmpty || _allFoodItems.isEmpty) {
            return Center(child: Text('Error loading data: ${snapshot.error ?? 'Missing Food Items/Meals'}'));
          }

          final meals = _currentPlan.days.first.meals;

          // Check if controller is null (shouldn't happen here if data loaded, but for safety)
          if (_tabController == null) {
            return const Center(child: Text('Tab Controller initialization failed.'));
          }

          return Column(
            children: [
              // 1. Template Form
              _buildMasterPlanDetailsForm(),

              // 2. Meal Tabs (Breakfast, Lunch, Dinner, etc.)
              Material(
                elevation: 2,
                child: TabBar(
                  // Use the null-checked controller
                  controller: _tabController!,
                  isScrollable: true,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  tabs: meals.map((m) => Tab(text: m.mealName)).toList(),
                ),
              ),

              // 3. Tab Content (List of Food Items for the selected meal)
              Expanded(
                child: TabBarView(
                  // Use the null-checked controller
                  controller: _tabController!,
                  children: meals.map((meal) => MealEntryList(
                    meal: meal,
                    allFoodItems: _allFoodItems,
                    addItemToMeal: _addItemToMeal,
                    addAlternativeToItem: _addAlternativeToItem,
                    removeAlternativeFromItem: _removeAlternativeFromItem,
                    removeItemFromMeal: _removeItemFromMeal,
                  )).toList(),
                ),
              ),

              // 4. Save Button
              _buildSaveButton(),
            ],
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- WIDGET: MealEntryList (Handles the Item Management for a Tab) ---
// ----------------------------------------------------------------------

class MealEntryList extends StatelessWidget {
  final DietPlanMealModel meal;
  final List<FoodItem> allFoodItems;
  final void Function(DietPlanItemModel) addItemToMeal;
  final void Function(DietPlanItemModel, FoodItemAlternative) addAlternativeToItem;
  final void Function(DietPlanItemModel, FoodItemAlternative) removeAlternativeFromItem;
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
              ? Center(child: Text('No items added to ${meal.mealName}.', style: const TextStyle(color: Colors.grey)))
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
            Text('${item.alternatives.length} Alternatives defined',
                style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
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
      builder: (context) => FoodItemEntryForm(
        foodItems: allFoodItems,
      ),
    );

    if (newItem != null) {
      addItemToMeal(newItem);
    }
  }

  // Launch the new Manager Modal
  void _showManageAlternativesModal(BuildContext context, DietPlanItemModel item) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => AlternativeManagerModal(
        item: item,
        allFoodItems: allFoodItems,
        // Pass the necessary callbacks from the main state
        onAddAlternative: (alternative) => addAlternativeToItem(item, alternative),
        onRemoveAlternative: (alternative) => removeAlternativeFromItem(item, alternative),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- WIDGET: AlternativeManagerModal (View, Add, Remove) ---
// ----------------------------------------------------------------------
class AlternativeManagerModal extends StatefulWidget {
  final DietPlanItemModel item;
  final List<FoodItem> allFoodItems;
  final void Function(FoodItemAlternative) onAddAlternative;
  final void Function(FoodItemAlternative) onRemoveAlternative;

  const AlternativeManagerModal({
    super.key,
    required this.item,
    required this.allFoodItems,
    required this.onAddAlternative,
    required this.onRemoveAlternative,
  });

  @override
  State<AlternativeManagerModal> createState() => _AlternativeManagerModalState();
}

class _AlternativeManagerModalState extends State<AlternativeManagerModal> {
  // Local flag to control the visibility of the Add Alternative form
  bool _isAddingNew = false;

  void _startAddingNew() {
    setState(() {
      _isAddingNew = true;
    });
  }

  void _finishAddingNew() {
    // 🎯 FIX: Only call setState to hide the form if the widget is still mounted
    if (mounted) {
      setState(() {
        _isAddingNew = false;
      });
    }
  }

  // 🎯 FIX APPLIED HERE: Delay the hiding of the form until the next frame
  void _onAlternativeAdded(FoodItemAlternative alternative) {
    // 1. Trigger parent state update immediately
    widget.onAddAlternative(alternative);

    // 2. Wait until the end of the current frame (where the parent rebuild happens)
    //    before calling setState to hide the form. This guarantees the list reads
    //    the new, updated 'item' property passed by the parent rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _finishAddingNew();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The main item's information
    final mainItem = widget.item;
    final alternatives = mainItem.alternatives;

    return Padding(
      // Only pad for the keyboard when the 'add' form is visible
      padding: EdgeInsets.only(bottom: _isAddingNew ? MediaQuery.of(context).viewInsets.bottom : 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Text('Manage Alternatives for', style: Theme.of(context).textTheme.titleLarge),
            Text('${mainItem.foodItemName} (${mainItem.quantity.toStringAsFixed(1)} ${mainItem.unit})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey)),
            const Divider(),

            // --- Alternatives List Section ---
            if (alternatives.isEmpty && !_isAddingNew)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(child: Text('No alternatives added yet.', style: TextStyle(color: Colors.grey))),
              ),

            if (!_isAddingNew && alternatives.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alternatives.length,
                  itemBuilder: (context, index) {
                    final alternative = alternatives[index];
                    return Card(
                      color: Colors.orange.shade50,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: ListTile(
                        title: Text(alternative.foodItemName),
                        subtitle: Text(alternative.displayQuantity),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () {
                            // Call the removal callback
                            widget.onRemoveAlternative(alternative);
                            // Parent state updates, which forces a rebuild of this modal
                            // with the new, shorter alternatives list.
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // --- Action and Add Form Section ---
            const SizedBox(height: 10),
            if (!_isAddingNew)
              ElevatedButton.icon(
                onPressed: _startAddingNew,
                icon: const Icon(Icons.add),
                label: const Text('Add New Alternative'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              )
            else
            // The Add Alternative Form is displayed here when _isAddingNew is true
              AlternativeEntryForm(
                foodItems: widget.allFoodItems,
                onSave: _onAlternativeAdded,
                onCancel: _finishAddingNew,
              ),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- FOOD ITEM ENTRY FORM (Unchanged) ---
// ----------------------------------------------------------------------
class FoodItemEntryForm extends StatefulWidget {
  final List<FoodItem> foodItems;
  const FoodItemEntryForm({super.key, required this.foodItems});
  @override
  State<FoodItemEntryForm> createState() => _FoodItemEntryFormState();
}

class _FoodItemEntryFormState extends State<FoodItemEntryForm> {
  FoodItem? _selectedFoodItem;
  final _quantityController = TextEditingController(text: '1.0');
  double _calculatedCalories = 0.0;
  double _calculatedProteinG = 0.0;
  double _calculatedCarbsG = 0.0;
  double _calculatedFatG = 0.0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedFoodItem = widget.foodItems.isNotEmpty ? widget.foodItems.first : null;
    _quantityController.addListener(_onQuantityChanged);
    _calculateMacros();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    _calculateMacros(quantityValue: double.tryParse(_quantityController.text));
  }

  void _calculateMacros({FoodItem? item, double? quantityValue}) {
    final itemToUse = item ?? _selectedFoodItem;
    final quantity = quantityValue ?? (double.tryParse(_quantityController.text) ?? 0.0);

    if (itemToUse == null || quantity <= 0) {
      if (_calculatedCalories != 0.0) {
        setState(() {
          _calculatedCalories = _calculatedProteinG = _calculatedCarbsG = _calculatedFatG = 0.0;
        });
      }
      return;
    }

    final macros = itemToUse.calculateMacros(quantity);

    setState(() {
      _calculatedCalories = macros['calories']!;
      _calculatedProteinG = macros['protein']!;
      _calculatedCarbsG = macros['carbs']!;
      _calculatedFatG = macros['fat']!;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFoodItem != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;

      final newItem = DietPlanItemModel(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        foodItemId: _selectedFoodItem!.id,
        foodItemName: _selectedFoodItem!.enName,
        quantity: quantity,
        unit: _selectedFoodItem!.servingUnitId,
      );
      Navigator.of(context).pop(newItem);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a food item and enter a valid quantity.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Food Item', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              DropdownButtonFormField<FoodItem>(
                value: _selectedFoodItem,
                decoration: InputDecoration(
                  labelText: 'Select Food Item',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                isExpanded: true,
                items: widget.foodItems.map<DropdownMenuItem<FoodItem>>((item) {
                  return DropdownMenuItem<FoodItem>(
                    value: item,
                    child: Text(item.enName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedFoodItem = item;
                    _calculateMacros(item: item);
                  });
                },
                validator: (value) => value == null ? 'Select an item' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: _selectedFoodItem?.servingUnitId ?? 'Unit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter valid quantity' : null,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
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
      ),
    );
  }
}

// ----------------------------------------------------------------------
// --- ALTERNATIVE ENTRY FORM (Unchanged) ---
// ----------------------------------------------------------------------
class AlternativeEntryForm extends StatefulWidget {
  final List<FoodItem> foodItems;
  final void Function(FoodItemAlternative) onSave;
  final VoidCallback onCancel;

  const AlternativeEntryForm({
    super.key,
    required this.foodItems,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<AlternativeEntryForm> createState() => _AlternativeEntryFormState();
}

class _AlternativeEntryFormState extends State<AlternativeEntryForm> {
  FoodItem? _selectedFoodItem;
  final _quantityController = TextEditingController(text: '1.0');
  double _calculatedCalories = 0.0;
  double _calculatedProteinG = 0.0;
  double _calculatedCarbsG = 0.0;
  double _calculatedFatG = 0.0;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedFoodItem = widget.foodItems.isNotEmpty ? widget.foodItems.first : null;
    _quantityController.addListener(_onQuantityChanged);
    _calculateMacros();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    _calculateMacros(quantityValue: double.tryParse(_quantityController.text));
  }

  void _calculateMacros({FoodItem? item, double? quantityValue}) {
    final itemToUse = item ?? _selectedFoodItem;
    final quantity = quantityValue ?? (double.tryParse(_quantityController.text) ?? 0.0);

    if (itemToUse == null || quantity <= 0) {
      if (_calculatedCalories != 0.0) {
        setState(() {
          _calculatedCalories = _calculatedProteinG = _calculatedCarbsG = _calculatedFatG = 0.0;
        });
      }
      return;
    }

    final macros = itemToUse.calculateMacros(quantity);

    setState(() {
      _calculatedCalories = macros['calories']!;
      _calculatedProteinG = macros['protein']!;
      _calculatedCarbsG = macros['carbs']!;
      _calculatedFatG = macros['fat']!;
    });
  }

  void _save() {
    if (_formKey.currentState!.validate() && _selectedFoodItem != null) {
      final quantity = double.tryParse(_quantityController.text) ?? 0.0;

      final newAlternative = FoodItemAlternative(
        // IMPORTANT: Generate a unique ID for reliable removal
        id: 'alt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}',
        foodItemId: _selectedFoodItem!.id,
        foodItemName: _selectedFoodItem!.enName,
        quantity: quantity,
        unit: _selectedFoodItem!.servingUnitId,
      );
      widget.onSave(newAlternative);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a food item and enter a valid quantity.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text('Add New Alternative', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<FoodItem>(
                value: _selectedFoodItem,
                decoration: InputDecoration(
                    labelText: 'Food Item (Alternative)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                ),
                isExpanded: true,
                items: widget.foodItems.map<DropdownMenuItem<FoodItem>>((item) {
                  return DropdownMenuItem<FoodItem>(
                    value: item,
                    child: Text(item.enName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedFoodItem = item;
                    _calculateMacros(item: item);
                  });
                },
                validator: (value) => value == null ? 'Select an item' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                    labelText: 'Quantity',
                    suffixText: _selectedFoodItem?.servingUnitId ?? 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter valid quantity' : null,
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
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
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}


// ----------------------------------------------------------------------
// --- UTILITIES (Shared by all forms - Unchanged) ---
// ----------------------------------------------------------------------

// Utility helper to display macro stats (used by both forms)
Widget _buildMacroStat(String label, double value, Color color) {
  return Column(
    children: [
      Text(
        value.toStringAsFixed(1),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}