import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nutricare_client_management/admin/labvital/global_service_provider.dart';
import 'package:nutricare_client_management/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/master/model/food_item.dart';
import 'package:nutricare_client_management/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/client/screen/premium_meal_entry_list.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/master/screen/master_meal_name_list_page.dart';
import 'package:nutricare_client_management/modules/master/service/master_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/master_diet_planner/generic_multi_select_dialogg.dart';
import 'package:nutricare_client_management/admin/generic_clinical_master_entry_screen.dart';
import 'package:nutricare_client_management/master/model/master_constants.dart';


// Extension (Retained)
extension IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) { if (test(element)) return element; }
    return null;
  }
}

enum PlanCycleType { singleDay, weekly }

class MasterDietPlanEntryPage extends ConsumerStatefulWidget {
  final String? planId;
  final MasterDietPlanModel? initialPlan;
  final PlanCycleType? initialCycleType;

  const MasterDietPlanEntryPage({super.key, this.planId, this.initialPlan, this.initialCycleType});

  @override
  ConsumerState<MasterDietPlanEntryPage> createState() => _MasterDietPlanEntryPageState();
}

class _MasterDietPlanEntryPageState extends ConsumerState<MasterDietPlanEntryPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TabController? _dayTabController;
  TabController? _mealTabController;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedCategoryIds = [];

  MasterDietPlanModel _currentPlan = const MasterDietPlanModel();

  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)>? _initialDataFuture;
  List<FoodItem> _allFoodItems = [];
  List<MasterMealName> _allMealNames = [];
  List<DietPlanCategory> _allCategories = [];
  bool _isSaving = false;

  late PlanCycleType _activeCycleType;
  final List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];


  @override
  void initState() {
    super.initState();
    // Determine active cycle type immediately based on navigation or existing plan
    _activeCycleType = widget.initialCycleType ?? (widget.initialPlan?.days.length == 7 ? PlanCycleType.weekly : PlanCycleType.singleDay);

    _initialDataFuture = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialDataFuture == null) {
      _initialDataFuture = _loadData();
    }
  }


  Future<(List<FoodItem>, List<MasterMealName>, List<DietPlanCategory>)> _loadData() async {
    // Services access is implicitly available via ref.watch in Riverpod ConsumerState
    final foods = await ref.watch(foodItemServiceProvider).fetchAllActiveFoodItems();
    final meals = await ref.watch(masterMealNameServiceProvider).fetchAllMealNames();
    final cats = await ref.watch(dietPlanCategoryServiceProvider).fetchAllActiveCategories();
    meals.sort((a,b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));

    MasterDietPlanModel plan;

    // --- 1. Load Existing Plan or Create Base Structure ---
    if (widget.planId != null || widget.initialPlan != null) {
      plan = widget.initialPlan ?? await ref.watch(masterDietPlanServiceProvider).fetchPlanById(widget.planId!);
    } else {
      // New plan: Build structure based on selected cycle type
      final List<MasterDayPlanModel> initialDays = [];
      final initialMeals = meals.map((m) => DietPlanMealModel(id: m.id, mealNameId: m.id, mealName: m.name, items: [], order: m.order)).toList();

      if (_activeCycleType == PlanCycleType.weekly) {
        for(int i = 0; i < 7; i++) {
          initialDays.add(MasterDayPlanModel(id: 'd${i+1}', dayName: _dayNames[i], meals: initialMeals));
        }
      } else {
        initialDays.add(MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day', meals: initialMeals));
      }
      plan = MasterDietPlanModel(days: initialDays);
    }

    // --- 3. Sync Meals (Preserve content, update to latest meal names) ---
    final List<MasterDayPlanModel> finalDays = [];
    final int targetLength = _activeCycleType == PlanCycleType.weekly ? 7 : 1;
    final List<MasterMealName> masterMeals = meals;

    for (int i = 0; i < targetLength; i++) {
      final String dayName = (i < _dayNames.length && _activeCycleType == PlanCycleType.weekly) ? _dayNames[i] : 'Fixed Day';
      // Get the saved day data if available, otherwise fallback to the first saved day's structure
      final MasterDayPlanModel sourceDay = plan.days.length > i ? plan.days[i] : (plan.days.isNotEmpty ? plan.days.first : MasterDayPlanModel(id: 'd1', dayName: 'Fixed Day'));

      final List<DietPlanMealModel> syncedMeals = [];
      for (var masterMeal in masterMeals) {
        final existingMeal = IterableExt(sourceDay.meals).firstWhereOrNull((cm) => cm.mealNameId == masterMeal.id);

        syncedMeals.add(
            existingMeal?.copyWith(mealName: masterMeal.name)
                ??
                DietPlanMealModel(id: masterMeal.id, mealNameId: masterMeal.id, mealName: masterMeal.name, items: [], order: masterMeal.order)
        );
      }

      finalDays.add(sourceDay.copyWith(dayName: dayName, meals: syncedMeals.where((m) => m.id.isNotEmpty).toList()));
    }


    _nameController.text = plan.name;
    _descriptionController.text = plan.description;

    // MODIFIED LOAD: Populate the List of IDs
    _selectedCategoryIds = List.from(plan.dietPlanCategoryIds);

    if (mounted) {
      setState(() {
        _currentPlan = plan.copyWith(days: finalDays);
        _allFoodItems = foods;
        _allMealNames = meals;
        _allCategories = cats;

        if (_currentPlan.days.isNotEmpty && _currentPlan.days.first.meals.isNotEmpty) {
          _dayTabController = TabController(length: _currentPlan.days.length, vsync: this);
          _mealTabController = TabController(length: _currentPlan.days.first.meals.length, vsync: this);
        } else {
          _dayTabController = null;
          _mealTabController = null;
        }
      });
    }
    return (foods, meals, cats);
  }

  void _updateMealItems(String mealId, List<DietPlanItemModel> items) {
    if (_dayTabController == null) return;

    final currentDayIndex = _dayTabController!.index;
    final day = _currentPlan.days[currentDayIndex];
    final idx = day.meals.indexWhere((m) => m.id == mealId);

    final updatedMeals = List<DietPlanMealModel>.from(day.meals);
    updatedMeals[idx] = updatedMeals[idx].copyWith(items: items);

    final updatedDays = List<MasterDayPlanModel>.from(_currentPlan.days);
    updatedDays[currentDayIndex] = day.copyWith(meals: updatedMeals);

    setState(() {
      _currentPlan = _currentPlan.copyWith(days: updatedDays);
    });
  }

  void _cloneDay(int sourceIndex, int targetIndex) {
    if (_currentPlan.days.length <= sourceIndex || _currentPlan.days.length <= targetIndex) return;

    final sourceDay = _currentPlan.days[sourceIndex];
    final targetDay = _currentPlan.days[targetIndex];

    final clonedMeals = sourceDay.meals.map((meal) {
      final clonedItems = meal.items.map((item) => item.copyWith()).toList();
      return meal.copyWith(items: clonedItems);
    }).toList();

    final updatedTargetDay = targetDay.copyWith(meals: clonedMeals);

    final updatedDays = List<MasterDayPlanModel>.from(_currentPlan.days);
    updatedDays[targetIndex] = updatedTargetDay;

    setState(() {
      _currentPlan = _currentPlan.copyWith(days: updatedDays);
    });

    if (_dayTabController!.index != targetIndex) {
      _dayTabController!.animateTo(targetIndex);
    } else {
      _mealTabController = TabController(length: _currentPlan.days.first.meals.length, vsync: this, initialIndex: _mealTabController!.index);
    }
  }

  // NEW: Function to open the Multi-Select Category Dialog
  void _openCategorySelector() async {
    // Check if categories are loaded
    if (_allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category data not loaded yet. Please wait.")));
      return;
    }

    // 1. Prepare data for the dialog (Name -> ID map)
    final categoryNameIdMap = { for (var c in _allCategories) c.name: c.id };

    // 2. Determine currently selected names (IDs to Names)
    final currentSelectedNames = _allCategories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => GenericMultiSelectDialog(
        title: "Select Goal Categories",
        items: _allCategories.map((c) => c.name).toList(),
        itemNameIdMap: categoryNameIdMap,
        initialSelectedItems: currentSelectedNames,
        singleSelect: false, // Ensure multi-select is enabled
        onAddMaster: () {
          // Close the bottom sheet and open the master entry screen
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => GenericClinicalMasterEntryScreen(
              entityName: MasterEntity.entity_DietPlanCategories,
            ),
          )).then((_) {
            // Re-load data if a new category was added
            setState(() => _initialDataFuture = _loadData());
          });
        },
      ),
    );

    if (result != null) {
      // 3. Convert selected names back to IDs and update state
      final selectedIds = result.map((name) {
        // Find the ID corresponding to the selected name
        final entry = categoryNameIdMap.entries.firstWhere((e) => e.key == name, orElse: () => const MapEntry('', ''));
        return entry.value;
      }).where((id) => id.isNotEmpty).toList();

      setState(() {
        _selectedCategoryIds = selectedIds;
      });
    }
  }


  // 🎯 NEW: Deletion Confirmation Logic
  Future<void> _confirmDelete() async {
    if (_currentPlan.id.isEmpty) return; // Should not happen on an edit page

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to permanently delete the template '${_currentPlan.name}'? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSaving = true);
      try {
        await ref.read(masterDietPlanServiceProvider).deletePlan(_currentPlan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Template deleted successfully!")));
          // Pop twice: once for the entry page, once for the list page refresh if needed
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }


  Future<void> _save() async {
    // MODIFIED VALIDATION: Check if at least one category is selected
    if (!_formKey.currentState!.validate() || _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one Goal Category.")));
      return;
    }

    if (_activeCycleType == PlanCycleType.weekly) {
      final isAllDaysEdited = _currentPlan.days.every((day) => day.meals.any((meal) => meal.items.isNotEmpty));
      if (!isAllDaysEdited) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill meals for all 7 days or clone a day."), backgroundColor: Colors.orange));
        return;
      }
    }


    setState(() => _isSaving = true);
    try {
      await ref.read(masterDietPlanServiceProvider).savePlan(_currentPlan.copyWith(
          id: widget.planId ?? _currentPlan.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),

          // MODIFIED SAVE: Pass the List of IDs
          dietPlanCategoryIds: _selectedCategoryIds,

          days: _currentPlan.days
      ));
      if (mounted) Navigator.pop(context);
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if(mounted) setState(() => _isSaving = false);
    }
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final isWeekly = _activeCycleType == PlanCycleType.weekly;
    final isEditMode = widget.initialPlan != null || widget.planId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 80, spreadRadius: 30)]))),
          Column(
            children: [
              _buildHeader(widget.planId == null ? "New Template" : "Edit Template", onSave: _save, isLoading: _isSaving, isEditMode: isEditMode),
              Expanded(
                child: FutureBuilder(
                  future: _initialDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());

                    if (_allMealNames.isEmpty) {
                      return _buildMealDependencyError();
                    }

                    if (_dayTabController == null || _mealTabController == null) {
                      return _buildMealDependencyError();
                    }

                    final currentDayIndex = _dayTabController?.index ?? 0;
                    final currentDay = _currentPlan.days[currentDayIndex];


                    return Column(
                      children: [
                        // --- 0. MODE DISPLAY ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _buildModeDisplay(isWeekly),
                        ),

                        // --- 1. DETAILS CARD (MODIFIED) ---
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: Form(
                            key: _formKey,
                            child: Column(children: [
                              _buildTextField(_nameController, "Template Name", Icons.label, required: true),
                              const SizedBox(height: 12),

                              // NEW: Multi-Select Category Selector
                              _buildCategorySelectorField(),

                              const SizedBox(height: 12),
                              _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 2),
                            ]),
                          ),
                        ),

                        // --- 2. DAY SELECTOR TABS (If Weekly) ---
                        if (isWeekly)
                          Container(
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TabBar(
                                    controller: _dayTabController, isScrollable: true, labelColor: Colors.white, unselectedLabelColor: Colors.grey,
                                    indicator: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20)),
                                    tabs: _currentPlan.days.asMap().entries.map((entry) {
                                      final day = entry.value;
                                      return Tab(child: Text(day.dayName.length > 5 ? day.dayName.substring(0, 3) : day.dayName, style: const TextStyle(fontWeight: FontWeight.bold)));
                                    }).toList(),
                                  ),
                                ),
                                // Clone Button
                                PopupMenuButton<int>(
                                  icon: const Icon(Icons.copy_all, color: Colors.indigo),
                                  onSelected: (targetIndex) => _cloneDay(currentDayIndex, targetIndex),
                                  itemBuilder: (ctx) => [
                                    ..._currentPlan.days.asMap().entries
                                        .where((e) => e.key != currentDayIndex)
                                        .map((e) => PopupMenuItem<int>(
                                        value: e.key,
                                        child: Text("Clone to ${e.value.dayName}")
                                    ))
                                  ],
                                  tooltip: "Clone Meals to Another Day",
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 10),

                        // --- 3. MEAL CONTENT FOR SELECTED DAY (Adaptive) ---
                        Expanded(
                            child: isWeekly
                                ? TabBarView( // Weekly: Use Day Tabs
                              controller: _dayTabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: _currentPlan.days.map((day) => _buildMealContent(day)).toList(),
                            )
                                : _buildMealContent(_currentPlan.days.first) // Single Day: Direct Meal Content
                        )
                      ],
                    );
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // NEW: Widget to display multi-select category field
  Widget _buildCategorySelectorField() {
    // 1. Get names of selected categories for display
    final selectedNames = _allCategories
        .where((c) => _selectedCategoryIds.contains(c.id))
        .map((c) => c.name)
        .toList();

    // 2. Determine display label
    String categoryLabel;
    Color borderColor;

    if (_selectedCategoryIds.isEmpty) {
      categoryLabel = "Select Goal Categories (Required)";
      borderColor = Colors.red;
    } else if (_selectedCategoryIds.length == 1) {
      categoryLabel = "Category: ${selectedNames.first}";
      borderColor = Colors.grey.shade300;
    } else {
      categoryLabel = "Categories selected: ${_selectedCategoryIds.length}";
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: _openCategorySelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel,
              style: TextStyle(
                  color: _selectedCategoryIds.isEmpty ? Colors.red : Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 16
              ),
            ),
            if (selectedNames.isNotEmpty && selectedNames.length > 1)
              const SizedBox(height: 8),
            if (selectedNames.length > 1)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedNames.map((name) => Chip(
                  label: Text(name, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.teal.shade50,
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers (Retained/Adapted) ---

  Widget _buildMealContent(MasterDayPlanModel day) {
    if (_mealTabController == null) return const Center(child: Text("No meals configured in Master Meal Names."));

    final meals = day.meals;

    if (_mealTabController!.length != meals.length) {
      _mealTabController = TabController(length: meals.length, vsync: this);
    }


    return Column(
      children: [
        // Meal Tab Bar (Inner Tabs: Breakfast, Lunch, etc.)
        Container(
          height: 40, margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _mealTabController, isScrollable: true, labelColor: Colors.white, unselectedLabelColor: Colors.grey,
            indicator: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20)),
            tabs: meals.map((m) => Tab(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(m.mealName)))).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Meal Tab Content (The core meal entry list)
        Expanded(
          child: TabBarView(
            controller: _mealTabController,
            children: meals.map((m) => PremiumMealEntryList(
              meal: m, allFoodItems: _allFoodItems,
              onUpdate: (items) => _updateMealItems(m.id, items),
            )).toList(),
          ),
        )
      ],
    );
  }

  // Mode Display (Adaptive, replaces the chips)
  Widget _buildModeDisplay(bool isWeekly) {
    Color color = isWeekly ? Colors.teal : Colors.blueGrey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isWeekly ? "WEEKLY CYCLE (7 DAYS)" : "SINGLE DAY CYCLE (FIXED)",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Dependency Error Widget
  Widget _buildMealDependencyError() {
    final mealCount = _allMealNames.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("CRITICAL: Meal Configuration Missing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
            const SizedBox(height: 10),
            Text("The system requires Master Meal Names (Breakfast, Lunch, etc.) to build a template. The database currently returned $mealCount configured meal slots. Please ensure they are added in the Meal Master Setup.", style: TextStyle(color: Colors.grey, )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterMealNameListPage())),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("Go to Meal Master Setup"),
            )
          ],
        ),
      ),
    );
  }

  // 🎯 MODIFIED: Header to include delete button when in edit mode
  Widget _buildHeader(String title, {required VoidCallback onSave, required bool isLoading, required bool isEditMode}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back)),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),

            // 🎯 DELETE BUTTON
            if (isEditMode)
              IconButton(
                  onPressed: isLoading ? null : _confirmDelete,
                  icon: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28)
              ),
            const SizedBox(width: 10),

            // SAVE BUTTON
            IconButton(
                onPressed: isLoading ? null : onSave,
                icon: isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.save, color: Colors.teal, size: 28)
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String l, IconData i, {bool isNumber = false, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _inputDec(l, i),
      validator: (v) => required && (v == null || v.isEmpty) ? "$l is required" : null,
    );
  }

  InputDecoration _inputDec(String label, IconData icon) {
    return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)
    );
  }
}