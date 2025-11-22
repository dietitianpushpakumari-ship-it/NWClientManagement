// lib/screens/master_diet_plan_entry_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';
import 'package:nutricare_client_management/helper/meal_planner/meal_entry_list.dart';
import 'package:nutricare_client_management/modules/client/services/vitals_service.dart';

import 'package:nutricare_client_management/modules/master/model/diagonosis_master.dart';
import 'package:nutricare_client_management/modules/master/service/diagonosis_master_service.dart';
import 'package:nutricare_client_management/tt/client_plan_detail_model.dart';
import 'package:nutricare_client_management/tt/plan_details_result.dart';
import 'package:nutricare_client_management/widgets/GuidelineWidget.dart';
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/modules/master/model/guidelines.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/diet_plan_category_service.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/guideline_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';
import 'dart:math';

import 'package:nutricare_client_management/modules/client/model/vitals_model.dart';
import 'package:nutricare_client_management/widgets/diagonosis_multi_select_dialog.dart';

class ClientDietPlanEntryPage extends StatefulWidget {
  // NEW: Optional ID for editing existing plan
  final String? planId;

  // NEW: Optional plan model for cloning
  final ClientDietPlanModel? initialPlan;

  const ClientDietPlanEntryPage({super.key, this.planId, this.initialPlan});

  @override
  State<ClientDietPlanEntryPage> createState() =>
      _ClientDietPlanEntryPageState();
}

// 識 FIX: Switched to TickerProviderStateMixin to allow safe re-initialization of TabController.
class _ClientDietPlanEntryPageState extends State<ClientDietPlanEntryPage>
    with TickerProviderStateMixin {
  Logger logger = Logger();

  // --- STATE ---
  final _formKey = GlobalKey<FormState>();

  // Change to nullable TabController
  TabController? _tabController;
  List<String> _selectedGuidelineIds = [];
  bool _isSaving = false;

  // Template Details
  final _nameController = TextEditingController();

  //final _descriptionController = TextEditingController();

  // Data for the entire screen
  ClientDietPlanModel _currentPlan = const ClientDietPlanModel();

  // Future Builders for dependencies
  Future<(List<FoodItem>, List<MasterMealName>)>? _initialDataFuture;
  List<FoodItem> _allFoodItems = const [];
  // 🎯 FIX: This state variable MUST be correctly named _allMealNames.
  List<MasterMealName> _allMealNames = const [];

  //List<DietPlanCategory> _allCategories = const [];
  List<DiagnosisMasterModel> _allDiagnoses = [];
  List<VitalsModel> _clientVitals = [];
  String _planName = '';
  List<String> _selectedDiagnosisIds = [];
  String? _linkedVitalsId;
  VitalsModel? _linkedVitalsRecord;

  bool _isLinkageExpanded = false;
  bool _isGuidelinesExpanded = false;
  bool _isPlanDetailExpanded = false;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _fetchInitialData(widget.planId, widget.initialPlan);
    if (widget.initialPlan != null) {
      _selectedDiagnosisIds = List.from(widget.initialPlan!.diagnosisIds);
      _linkedVitalsId = widget.initialPlan!.linkedVitalsId;
    }
  }

  Future<(List<FoodItem>, List<MasterMealName>)> _fetchInitialData(
      String? planId,
      ClientDietPlanModel? initialPlan,
      ) async {
    // 1. Fetch dependencies
    final foodItems = await FoodItemService().fetchAllActiveFoodItems();
    final mealNames = await MasterMealNameService().fetchAllMealNames();

    ///  final categories = await DietPlanCategoryService().fetchAllActiveCategories();

    ClientDietPlanModel planToEdit = const ClientDietPlanModel();

    if (planId != null) {
      // EDIT MODE: Fetch the existing plan by ID
      planToEdit = await ClientDietPlanService().fetchPlanById(planId);
    } else if (initialPlan != null) {
      // CLONE MODE: Use the provided, already-cloned plan
      planToEdit = initialPlan;
    } else {
      // NEW MODE: Initialize the empty plan structure
      final initialMeals = mealNames
          .map(
            (m) => DietPlanMealModel(
          id: m.id,
          mealNameId: m.id,
          mealName: m.enName,
          items: [],
          order: m.order,
        ),
      )
          .toList();
      planToEdit = ClientDietPlanModel(
        days: [
          MasterDayPlanModel(
            id: 'd1',
            dayName: 'Fixed Day',
            meals: initialMeals,
          ),
        ],
      );
    }
    _loadLinkageData(planToEdit.clientId);
    // 2. Set up local state from the loaded/cloned/new plan
    _nameController.text = planToEdit.name;
    //   _descriptionController.text = planToEdit.description;

    if (planToEdit.days.isNotEmpty) {
      final currentDay = planToEdit.days.first;
      final orderedMeals = <DietPlanMealModel>[];

      // Iterate through the canonical, ordered list of meal names
      for (var canonicalMealName in mealNames) {
        // Find the corresponding meal in the fetched plan using the unique ID
        final mealInPlan = currentDay.meals.firstWhereOrNull(
              (m) => m.mealNameId == canonicalMealName.id,
        );

        if (mealInPlan != null) {
          orderedMeals.add(mealInPlan);
        } else {
          // If a new meal name was added to the master list but not the plan (for NEW plans)
          orderedMeals.add(
            DietPlanMealModel(
              id: canonicalMealName.id,
              mealNameId: canonicalMealName.id,
              mealName: canonicalMealName.enName,
              items: [],
              order: canonicalMealName.order,
            ),
          );
        }
      }

      // Replace the unordered meals list with the newly ordered list
      planToEdit = planToEdit.copyWith(
        days: [currentDay.copyWith(meals: orderedMeals)],
      );
    }

    setState(() {
      _currentPlan = planToEdit;
      _allFoodItems = foodItems;
      _allMealNames = mealNames;
      _selectedGuidelineIds = planToEdit.guidelineIds;
      _linkedVitalsId = planToEdit.linkedVitalsId;
      _selectedDiagnosisIds = planToEdit.diagnosisIds;

      if (planToEdit.days.isNotEmpty &&
          planToEdit.days.first.meals.isNotEmpty) {
        // Use the length of the meals in the initialized plan
        final mealCount = planToEdit.days.first.meals.length;
        if (mealCount > 0) {
          // Dispose of the old controller if it exists and length is different
          if (_tabController != null) {
            _tabController!.dispose();
          }
          // 識 FIX: Instantiate the controller with the correct length
          _tabController = TabController(length: mealCount, vsync: this);
        } else {
          // Set to null if no meals, so the UI checks don't fail
          if (_tabController != null) {
            _tabController!.dispose();
            _tabController = null;
          }
        }
      } else {}
    });

    return (foodItems, mealNames);
  }

  void _loadLinkageData(String clientId) async {
    // 1. Load Diagnoses Master List
    final diagnoses = await DiagnosisMasterService().fetchAllDiagnosisMaster();

    // 2. Load Client Vitals History
    final vitals = await VitalsService().getClientVitals(clientId);
    vitals.sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending

    setState(() {
      _allDiagnoses = diagnoses;
      _clientVitals = vitals;
      // 3. Set the linked Vitals record object if ID exists
      if (_linkedVitalsId != null) {
        _linkedVitalsRecord = vitals.firstWhereOrNull(
              (v) => v.id == _linkedVitalsId,
        );
      }
    });
  }

  Future<void> _showDiagnosisSelectionDialog() async {
    final List<String> initialSelection = List.from(_selectedDiagnosisIds);

    final List<String>? finalSelection = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return DiagnosisMultiSelectDialog(
          allDiagnoses: _allDiagnoses,
          initialSelectedIds: initialSelection,
        );
      },
    );

    if (finalSelection != null) {
      setState(() {
        _selectedDiagnosisIds = finalSelection;
      });
    }
  }

  // 識 UI: Diagnosis Chip Display and Picker Button
  Widget _buildDiagnosisChipDisplay() {
    final selectedDiagnoses = _selectedDiagnosisIds
        .map((id) {
      return _allDiagnoses.firstWhereOrNull((d) => d.id == id);
    })
        .whereType<DiagnosisMasterModel>()
        .toList(); // Filter out nulls

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ...selectedDiagnoses.map((diagnosis) {
              return Chip(
                label: Text(diagnosis.enName),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedDiagnosisIds.remove(diagnosis.id);
                  });
                },
                backgroundColor: Colors.red.shade100,
                labelStyle: TextStyle(color: Colors.red.shade800),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    //    _descriptionController.dispose();
    super.dispose();
  }

  // --- MUTATOR METHODS ---

  // 1. Adds a new DietPlanItemModel to the currently selected meal
  void _addItemToMeal(DietPlanItemModel newItem) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // 🎯 FIX: Use _allMealNames here (State variable), NOT _mealNames (local typo)
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere(
            (m) => m.id == currentMealId,
      );
      final currentMeal = currentDay.meals[mealIndex];

      final updatedItems = List<DietPlanItemModel>.from(currentMeal.items)
        ..add(newItem);

      final updatedMeal = currentMeal.copyWith(items: updatedItems);

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = updatedMeal;

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // 2. Adds an alternative to an existing item
  void _addAlternativeToItem(
      DietPlanItemModel item,
      FoodItemAlternative alternative,
      ) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // 🎯 FIX: Use _allMealNames here (State variable), NOT _mealNames (local typo)
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere(
            (m) => m.id == currentMealId,
      );
      final itemIndex = currentDay.meals[mealIndex].items.indexWhere(
            (i) => i.id == item.id,
      );
      final targetItem = currentDay.meals[mealIndex].items[itemIndex];

      final updatedAlternatives = List<FoodItemAlternative>.from(
        targetItem.alternatives,
      )..add(alternative);

      final updatedItem = targetItem.copyWith(
        alternatives: updatedAlternatives,
      );

      final updatedItems = List<DietPlanItemModel>.from(
        currentDay.meals[mealIndex].items,
      );
      updatedItems[itemIndex] = updatedItem;

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = currentDay.meals[mealIndex].copyWith(
        items: updatedItems,
      );

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  // 3. Removes an alternative from an existing item
  void _removeAlternativeFromItem(
      DietPlanItemModel item,
      FoodItemAlternative alternativeToRemove,
      ) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      // 🎯 FIX: Use _allMealNames here (State variable), NOT _mealNames (local typo)
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere(
            (m) => m.id == currentMealId,
      );
      final currentMeal = currentDay.meals[mealIndex];
      final itemIndex = currentMeal.items.indexWhere((i) => i.id == item.id);
      final targetItem = currentMeal.items[itemIndex];

      // Create the updated list of alternatives
      final updatedAlternatives = List<FoodItemAlternative>.from(
        targetItem.alternatives,
      )..removeWhere((a) => a == alternativeToRemove);

      // Recreate the item with the new alternatives list
      final updatedItem = targetItem.copyWith(
        alternatives: updatedAlternatives,
      );

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
      // 🎯 FIX: Use _allMealNames here (State variable), NOT _mealNames (local typo)
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere(
            (m) => m.id == currentMealId,
      );
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

  //[ --- CORE LOGIC: SAVE PLAN ---
  void _savePlan() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all plan details')),
      );
      return; // Exit if validation fails or form key is unattached.
    }

    if (_linkedVitalsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please link a Vitals record before saving.'),
        ),
      );
      return;
    }

    final planToSave = _currentPlan.copyWith(
      // Use existing ID for UPDATE, or generate new ID for NEW/CLONE
      id: widget.planId ?? _currentPlan.id,
      name: _nameController.text.trim(),
      //  description: _descriptionController.text.trim(),
      guidelineIds: _selectedGuidelineIds,
      diagnosisIds: _selectedDiagnosisIds,
      linkedVitalsId: _linkedVitalsId,
    );
    // Basic validation: Check if any meal has items
    final totalItems = planToSave.days.first.meals.fold(
      0,
          (sum, meal) => sum + meal.items.length,
    );
    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan must contain at least one food item.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.planId != null ? 'Updating' : 'Saving'} plan...',
        ),
      ),
    );
    try {
      await ClientDietPlanService().savePlan(planToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diet Plan Template saved successfully!')),
      );
      // Clear or navigate away on success
      // On success, return to the list screen
      Navigator.of(context).pop(true);
    } catch (e) {
      logger.e('Error saving plan: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
    }
  }

  // --- UI COMPONENTS (Unchanged) ---

  // 識 NEW: Guideline Selection and Display Section
  Widget _buildGuidelineSelectionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Guidelines',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Edit Guidelines'),
                onPressed: () async {
                  // Launch the Multi-Select Dialog
                  final selected = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => GuidelineMultiSelect(
                      initialSelectedIds: _selectedGuidelineIds,
                    ),
                  );

                  if (selected != null) {
                    setState(() {
                      _selectedGuidelineIds = selected;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Display the selected count or chips (if GUIDELINE objects are available)
          _selectedGuidelineIds.isEmpty
              ? const Text(
            'No guidelines tagged.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          )
          // Display a summary of selected guidelines
              : FutureBuilder<List<Guideline>>(
            future: GuidelineService().fetchGuidelinesByIds(
              _selectedGuidelineIds,
            ), // Placeholder service call
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final guidelines = snapshot.data ?? [];

              return Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: guidelines
                    .map(
                      (g) => Chip(
                    label: Text(
                      g.enTitle,
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: Colors.blue.shade50,
                    deleteIcon: const Icon(Icons.cancel, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedGuidelineIds.remove(g.id);
                      });
                    },
                  ),
                )
                    .toList(),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

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
              decoration: const InputDecoration(
                labelText: 'Plan Name (e.g., Keto 1500 KCal)',
              ),
              validator: (value) => value!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 10),
            /* TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Plan Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),*/
          ],
        ),
      ),
    );
  }

  // 識 UI: Vitals Linker
  Widget _buildVitalsLinker() {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.all(8),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Vitals Record Date',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _linkedVitalsId,
            hint: const Text('Select Vitals entry to link report to'),
            isExpanded: true,
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('--- Clear Link ---'),
              ),
              ..._clientVitals.map((vitals) {
                return DropdownMenuItem<String>(
                  value:  vitals.id,
                  child: Text(
                    '${DateFormat.yMMMd().format(vitals.date)} - ${vitals.weightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontWeight: _linkedVitalsId == vitals.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _linkedVitalsId = newValue;
                _linkedVitalsRecord = _clientVitals.firstWhereOrNull(
                      (v) => v.id == newValue,
                );
              });
            },
          ),
        ),
        if (_linkedVitalsRecord != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8),
            child: Text(
              'Linked Vitals: Weight ${_linkedVitalsRecord!.weightKg} kg, BFP ${_linkedVitalsRecord!.bodyFatPercentage}%',
              style: TextStyle(color: Colors.green.shade700, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- MAIN WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: CustomGradientAppBar(
          title: const Text('Meal Planning'),
          actions: [
            IconButton(
              icon: _isSaving
                  ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _savePlan,
              tooltip: 'Save Diet Plan',
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder(
          future: _initialDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                _currentPlan.days.isEmpty ||
                _allFoodItems.isEmpty) {
              return Center(
                child: Text(
                  'Error loading data: ${snapshot.error ?? 'Missing Food Items/Meals'}',
                ),
              );
            }
      
            final meals = _currentPlan.days.first.meals;
      
            // Check if controller is null (shouldn't happen here if data loaded, but for safety)
            if (_tabController == null) {
              return const Center(
                child: Text('Tab Controller initialization failed.'),
              );
            }
      
            return Column(
              children: [
                // 🎯 CHANGE: Set initiallyExpanded to true to show the Plan details by default
                ExpansionTile(
                  initiallyExpanded: true,
                  onExpansionChanged: (expanded) =>
                      setState(() => _isGuidelinesExpanded = expanded),
                  leading: const Icon(Icons.list_alt, color: Colors.blueGrey),
                  title: const Text(
                    'Assignments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    _buildMasterPlanDetailsForm(),
                    _buildVitalsLinker(),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: 4.0,
                                bottom: 4.0,
                                left: 10.0,
                                right: 10.0,
                              ),
                              child: Text(
                                'Diagnosis',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              icon: Icon(
                                Icons.search,
                                size: 18,
                                color: Colors.indigo,
                              ),
                              label: Text(
                                _selectedDiagnosisIds.isEmpty
                                    ? 'Select Diagnosis'
                                    : 'Edit Diagnoses (${_selectedDiagnosisIds.length})',
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: _showDiagnosisSelectionDialog,
                              // backgroundColor: Colors.indigo.shade50,
                              // side: BorderSide(color: Colors.indigo.shade100),
                            ),
                          ],
                        ),
      
                        const Divider(),
                        _buildDiagnosisChipDisplay(),
                      ],
                    ),
      
                    _buildGuidelineSelectionSection(context),
                  ],
                ),
      
                const Divider(height: 1),
                Material(
                  elevation: 2,
                  child: meals.isEmpty
                      ? null
                      : TabBar(
                    // Use the null-checked controller
                    controller: _tabController!,
                    isScrollable: true,
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    tabs: meals.map((m) => Tab(text: m.mealName)).toList(),
                  ),
                ),
      
                Expanded(
                  child: TabBarView(
                    // Use the null-checked controller
                    controller: _tabController!,
                    children: meals
                        .map(
                          (meal) => MealEntryList(
                        meal: meal,
                        allFoodItems: _allFoodItems,
                        addItemToMeal: _addItemToMeal,
                        addAlternativeToItem: _addAlternativeToItem,
                        removeAlternativeFromItem: _removeAlternativeFromItem,
                        removeItemFromMeal: _removeItemFromMeal,
                      ),
                    )
                        .toList(),
                  ),
                ),
      
                //     _buildSaveButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}