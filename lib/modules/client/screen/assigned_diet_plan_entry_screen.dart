// lib/screens/master_diet_plan_entry_page.dart (Refactored to Two-Screen Flow)

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:nutricare_client_management/helper/meal_planner/meal_entry_list.dart';

// 🎯 ADJUST/RETAIN NECESSARY IMPORTS
import 'package:nutricare_client_management/modules/client/model/client_diet_plan_model.dart';
import 'package:nutricare_client_management/modules/client/screen/assignment_details_screen.dart';
import 'package:nutricare_client_management/modules/client/services/client_diet_plan_service.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_item_model.dart';
import 'package:nutricare_client_management/modules/master/model/food_item.dart';
import 'package:nutricare_client_management/modules/master/model/meal_master_name.dart';
import 'package:nutricare_client_management/modules/master/service/food_item_service.dart';
import 'package:nutricare_client_management/modules/master/service/master_meal_name_service.dart';

class ClientDietPlanEntryPage extends StatefulWidget {
  // NOTE: You may need to replace 'CLIENT_ID_STUB' with an actual value

  final String? planId;
  final ClientDietPlanModel? initialPlan;
  final VoidCallback onMealPlanSaved;

  const ClientDietPlanEntryPage({super.key, this.planId, this.initialPlan,required this.onMealPlanSaved});

  @override
  State<ClientDietPlanEntryPage> createState() =>
      _ClientDietPlanEntryPageState();
}

class _ClientDietPlanEntryPageState extends State<ClientDietPlanEntryPage>
    with TickerProviderStateMixin {
  Logger logger = Logger();

  // --- STATE ---
  TabController? _tabController;
  bool _isSaving = false;

  // Plan Details (Now managed and retrieved from the new screen)
  String _planName = '';
  String? _linkedVitalsId;
  List<String> _selectedDiagnosisIds = [];
  List<String> _selectedGuidelineIds = [];
  List<String> _selectedSuppliments = [];
  List<String> _selectedInvestigations = [];
  String _instructions = '';
  String _initialClinicalNotes = '';
  int? _followUpDays = 0;
  String _primaryComplaint =
      ''; // New field to capture context from the details screen
  bool _isProvisional = false;

  // Data for the entire screen
  ClientDietPlanModel _currentPlan = const ClientDietPlanModel();
  Future<(List<FoodItem>, List<MasterMealName>)>? _initialDataFuture;
  List<FoodItem> _allFoodItems = const [];
  List<MasterMealName> _allMealNames = const [];

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _fetchInitialData(widget.planId, widget.initialPlan);

    // Initialize details from initialPlan if cloning
    if (widget.initialPlan != null) {
      _planName = widget.initialPlan!.name;
      _selectedDiagnosisIds = List.from(widget.initialPlan!.diagnosisIds);
      _linkedVitalsId = widget.initialPlan!.linkedVitalsId;
      _selectedGuidelineIds = List.from(widget.initialPlan!.guidelineIds);
      _selectedSuppliments = List.from(widget.initialPlan!.suplimentIds);
      _instructions = widget.initialPlan!.instructions;
      _selectedInvestigations = widget.initialPlan!.investigationIds;
      _isProvisional = widget.initialPlan!.isProvisional;
    }
  }

  Future<(List<FoodItem>, List<MasterMealName>)> _fetchInitialData(
    String? planId,
    ClientDietPlanModel? initialPlan,
  ) async {
    final foodItems = await FoodItemService().fetchAllActiveFoodItems();
    final mealNames = await MasterMealNameService().fetchAllMealNames();

    ClientDietPlanModel planToEdit = const ClientDietPlanModel();

    if (planId != null) {
      planToEdit = await ClientDietPlanService().fetchPlanById(planId);
    } else if (initialPlan != null) {
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

    if (planToEdit.days.isNotEmpty) {
      final currentDay = planToEdit.days.first;
      final orderedMeals = <DietPlanMealModel>[];
      for (var canonicalMealName in mealNames) {
        // Assuming firstWhereOrNull extension is available
        final mealInPlan = currentDay.meals.firstWhereOrNull(
          (m) => m.mealNameId == canonicalMealName.id,
        );

        if (mealInPlan != null) {
          orderedMeals.add(mealInPlan);
        } else {
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
      planToEdit = planToEdit.copyWith(
        days: [currentDay.copyWith(meals: orderedMeals)],
      );
    }

    setState(() {
      _currentPlan = planToEdit;
      _allFoodItems = foodItems;
      _allMealNames = mealNames;
      _planName = planToEdit.name;
      _selectedGuidelineIds = planToEdit.guidelineIds;
      _linkedVitalsId = planToEdit.linkedVitalsId;
      _selectedDiagnosisIds = planToEdit.diagnosisIds;
      _instructions = planToEdit.instructions;
      _selectedSuppliments = planToEdit.suplimentIds;
      _selectedInvestigations = planToEdit.investigationIds;
      _followUpDays = planToEdit.followUpDays;
      _initialClinicalNotes = planToEdit.clinicalNotes;
      _primaryComplaint = planToEdit.complaints;
      _isProvisional = planToEdit.isProvisional;

      if (planToEdit.days.isNotEmpty &&
          planToEdit.days.first.meals.isNotEmpty) {
        final mealCount = planToEdit.days.first.meals.length;
        if (mealCount > 0) {
          if (_tabController != null) {
            _tabController!.dispose();
          }
          _tabController = TabController(length: mealCount, vsync: this);
        } else {
          if (_tabController != null) {
            _tabController!.dispose();
            _tabController = null;
          }
        }
      }
    });

    return (foodItems, mealNames);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // --- NAVIGATION METHOD to the new screen ---
  void _editAssignmentDetails() async {
    final result = await Navigator.of(context).push<AssignmentDetailsResult>(
      MaterialPageRoute(
        builder: (context) => AssignmentDetailsScreen(
          clientId: widget.initialPlan!.clientId,
          initialPlanName: _planName,
          initialLinkedVitalsId: _linkedVitalsId,
          initialSelectedDiagnosisIds: _selectedDiagnosisIds,
          initialSelectedGuidelineIds: _selectedGuidelineIds,
          initialClinicalNotes: _initialClinicalNotes,
          initialFollowUpDays: _followUpDays,
          initialPrimaryComplaints: _primaryComplaint,
          initialSelectedSupplementationIds: _selectedSuppliments,
          initialGeneralPlanNotes: _instructions,
          initialSelectedInvestigationIds: _selectedInvestigations,
        ),
      ),
    );

    if (result is AssignmentDetailsResult) {
      setState(() {
        _planName = result.planName;
        _linkedVitalsId = result.linkedVitalsId;
        _selectedDiagnosisIds = result.selectedDiagnosisIds;
        _selectedGuidelineIds = result.selectedGuidelineIds;
        _initialClinicalNotes = result.clinicalNotes;
        _followUpDays = result.followUpDays;
        _primaryComplaint = result.primaryComplaints;
        _instructions = result.generalPlanNotes;
        _selectedSuppliments = result.selectedSupplementationIds;
        _selectedInvestigations = result.selectedInvestigationIds;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment details updated!')),
      );
    }
  }

  // --- MUTATOR METHODS (Kept for Meal Planning logic) ---

  void _addItemToMeal(DietPlanItemModel newItem) {
    setState(() {
      final currentDay = _currentPlan.days.first;
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

  void _addAlternativeToItem(
    DietPlanItemModel item,
    FoodItemAlternative alternative,
  ) {
    setState(() {
      final currentDay = _currentPlan.days.first;
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

  void _removeAlternativeFromItem(
    DietPlanItemModel item,
    FoodItemAlternative alternativeToRemove,
  ) {
    setState(() {
      final currentDay = _currentPlan.days.first;
      final currentMealId = _allMealNames[_tabController!.index].id;

      final mealIndex = currentDay.meals.indexWhere(
        (m) => m.id == currentMealId,
      );
      final currentMeal = currentDay.meals[mealIndex];
      final itemIndex = currentMeal.items.indexWhere((i) => i.id == item.id);
      final targetItem = currentMeal.items[itemIndex];

      final updatedAlternatives = List<FoodItemAlternative>.from(
        targetItem.alternatives,
      )..removeWhere((a) => a == alternativeToRemove);
      final updatedItem = targetItem.copyWith(
        alternatives: updatedAlternatives,
      );

      final updatedItems = List<DietPlanItemModel>.from(currentMeal.items);
      updatedItems[itemIndex] = updatedItem;

      final updatedMeal = currentMeal.copyWith(items: updatedItems);

      final updatedMeals = List<DietPlanMealModel>.from(currentDay.meals);
      updatedMeals[mealIndex] = updatedMeal;

      _currentPlan = _currentPlan.copyWith(
        days: [currentDay.copyWith(meals: updatedMeals)],
      );
    });
  }

  void _removeItemFromMeal(DietPlanItemModel item) {
    setState(() {
      final currentDay = _currentPlan.days.first;
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
    // 1. Validation (now using fields from state updated by the details screen)
    if (_planName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan Name is required. Edit Assignments to set it.'),
        ),
      );
      return;
    }
    if (_linkedVitalsId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please link a Vitals record before saving. Edit Assignments to link it.',
          ),
        ),
      );
      return;
    }

    final planToSave = _currentPlan.copyWith(
      id: widget.planId ?? _currentPlan.id,
      name: _planName,
      guidelineIds: _selectedGuidelineIds,
      diagnosisIds: _selectedDiagnosisIds,
      linkedVitalsId: _linkedVitalsId,
      followUpDays: _followUpDays,
      clinicalNotes: _initialClinicalNotes,
      complaints: _primaryComplaint,
      investigationIds: _selectedInvestigations,
      instruction: _instructions,
      suplimentIds: _selectedSuppliments,
      isProvisionals: _isProvisional,

      // You may need to update ClientDietPlanModel to include _followUpNotes
      // description: _followUpNotes, // If using the description field for notes
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
      widget.onMealPlanSaved();
      Navigator.of(context).pop(true);
    } catch (e) {
      logger.e('Error saving plan: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
    }
  }

  // --- MAIN WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planning'),
        actions: [
          Row(
            children: [
              Text(
                _isProvisional ? 'PROVISIONAL' : 'FINAL',
                style: TextStyle(
                  color: _isProvisional
                      ? Colors.amber.shade200
                      : Colors.lightGreen.shade200,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _isProvisional,
                onChanged: (bool newValue) {
                  setState(() {
                    _isProvisional = newValue;
                  });
                },
                activeColor: Colors.amber,
              ),

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
        ],
      ),
      body: FutureBuilder(
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

          if (_tabController == null) {
            return const Center(
              child: Text('Tab Controller initialization failed.'),
            );
          }

          return Column(
            children: [
              // 🎯 The button/ListTile to navigate to the separate Assignment Details Screen
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.blue),
                    title: Text(
                      _planName.isNotEmpty
                          ? 'Plan: $_planName'
                          : 'Set Assignment Details',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Vitals Linked: ${_linkedVitalsId != null ? 'Yes' : 'No'} | Diagnosis: ${_selectedDiagnosisIds.length} | Guidelines: ${_selectedGuidelineIds.length}',
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.indigo),
                    onTap: _editAssignmentDetails,
                  ),
                ),
              ),

              const Divider(height: 1),

              // --- MEAL PLANNER TABS ---
              Material(
                elevation: 2,
                child: meals.isEmpty
                    ? null
                    : TabBar(
                        controller: _tabController!,
                        isScrollable: true,
                        labelColor: Colors.indigo,
                        unselectedLabelColor: Colors.grey,
                        tabs: meals.map((m) => Tab(text: m.mealName)).toList(),
                      ),
              ),

              // --- MEAL PLANNER CONTENT ---
              Expanded(
                child: TabBarView(
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
            ],
          );
        },
      ),
    );
  }
}
