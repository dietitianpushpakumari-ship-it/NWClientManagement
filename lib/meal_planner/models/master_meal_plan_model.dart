// lib/models/master_diet_plan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:nutricare_client_management/meal_planner/models/meal_master_name.dart';

import '../screen/master_diet_plan_entry_page.dart' show FoodItem;
import 'master_diet_plan_model.dart' hide MasterMealName;

/// Represents a single food item with a specified quantity within a meal.
class MealFoodItem {
  final FoodItem foodItem;
  final double quantityValue; // The quantity entered by the admin (e.g., 2.0 for 2 cups)

  // Calculated Macros based on quantityValue * FoodItem's standard serving size (or 100g)
  final double calculatedCalories;
  final double calculatedProteinG;
  final double calculatedCarbsG;
  final double calculatedFatG;

  // NOTE: In a real app, calculation logic would live in a helper/service.
  // For the model, we can pre-calculate it at the time of creation.

  MealFoodItem({
    required this.foodItem,
    required this.quantityValue,
    double? calculatedCalories,
    double? calculatedProteinG,
    double? calculatedCarbsG,
    double? calculatedFatG,
  }) :
  // Calculate values if not provided (e.g., on object creation/edit)
        calculatedCalories = calculatedCalories ?? (foodItem.caloriesPerStandardServing * (quantityValue / foodItem.standardServingSizeG)),
        calculatedProteinG = calculatedProteinG ?? (foodItem.proteinG * (quantityValue / foodItem.standardServingSizeG)),
        calculatedCarbsG = calculatedCarbsG ?? (foodItem.carbsG * (quantityValue / foodItem.standardServingSizeG)),
        calculatedFatG = calculatedFatG ?? (foodItem.fatG * (quantityValue / foodItem.standardServingSizeG));

  // Factory to convert from Firestore map (requires FoodItem data)
  factory MealFoodItem.fromMap(Map<String, dynamic> data, FoodItem foodItem) {
    return MealFoodItem(
      foodItem: foodItem,
      quantityValue: (data['quantityValue'] as num?)?.toDouble() ?? 0.0,
      calculatedCalories: (data['calculatedCalories'] as num?)?.toDouble() ?? 0.0,
      calculatedProteinG: (data['calculatedProteinG'] as num?)?.toDouble() ?? 0.0,
      calculatedCarbsG: (data['calculatedCarbsG'] as num?)?.toDouble() ?? 0.0,
      calculatedFatG: (data['calculatedFatG'] as num?)?.toDouble() ?? 0.0,
      // Note: foodItem is reconstructed via a lookup service/cache in the real app flow
    );
  }

  // Convert to map for storage (only storing the foodItem's ID and quantity/calculated values)
  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItem.id, // Store ID only
      'quantityValue': quantityValue,
      'calculatedCalories': calculatedCalories,
      'calculatedProteinG': calculatedProteinG,
      'calculatedCarbsG': calculatedCarbsG,
      'calculatedFatG': calculatedFatG,
    };
  }

  @override
  List<Object?> get props => [
    foodItem.id,
    quantityValue,
    calculatedCalories,
    calculatedProteinG,
    calculatedCarbsG,
    calculatedFatG
  ];
}


/// Represents a single meal (e.g., Breakfast) within a Master Diet Plan.
class MealPlanSlot  {
  final MasterMealName mealName;
  final List<MealFoodItem> foodItems; // The list of main food items (alternatives are within this list)

  // Total calculated macros for this meal slot
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  MealPlanSlot({
    required this.mealName,
    this.foodItems = const [],
  }) :
        totalCalories = foodItems.fold(0, (sum, item) => sum + item.calculatedCalories),
        totalProteinG = foodItems.fold(0, (sum, item) => sum + item.calculatedProteinG),
        totalCarbsG = foodItems.fold(0, (sum, item) => sum + item.calculatedCarbsG),
        totalFatG = foodItems.fold(0, (sum, item) => sum + item.calculatedFatG);

  @override
  List<Object?> get props => [mealName.id, foodItems];

// Note: Conversion from/to Map for this level is complex as it requires
// the entire food item object. This will be handled in the main model.
}


/// The main model representing the entire diet plan template (e.g., for Diabetic).
class MasterDietPlanModel  {
  final String id;
  final String categoryId; // References DietPlanCategory.id
  final String enName; // e.g., "Standard Diabetic Plan"
  final Map<String, String> nameLocalized;
  final String description;
  final List<MealPlanSlot> dailyPlan; // The structured plan for one full day
  final bool isDeleted;
  final DateTime? createdDate;

  MasterDietPlanModel({
    required this.id,
    required this.categoryId,
    required this.enName,
    this.nameLocalized = const {},
    this.description = '',
    this.dailyPlan = const [],
    this.isDeleted = false,
    this.createdDate,
  });

  // Note: Full fromFirestore/toMap logic is complex due to nested models
  // and will be handled by the service layer during persistence/retrieval.

  @override
  List<Object?> get props => [id, categoryId, enName, description, dailyPlan, isDeleted, createdDate];

  // Helper to convert model to map for saving (simplified for Firestore)
  Map<String, dynamic> toMap() {
    // This is the structure we save to Firestore.
    // Daily plan is converted to a Map keyed by MealName ID.
    final Map<String, dynamic> dailyPlanMap = {};
    for (var slot in dailyPlan) {
      dailyPlanMap[slot.mealName.id] = {
        'mealNameId': slot.mealName.id,
        'foodItems': slot.foodItems.map((item) => item.toMap()).toList(),
        // Total macros are denormalized for easy viewing/filtering
        'totalCalories': slot.totalCalories,
        'totalProteinG': slot.totalProteinG,
        'totalCarbsG': slot.totalCarbsG,
        'totalFatG': slot.totalFatG,
      };
    }

    return {
      'categoryId': categoryId,
      'enName': enName,
      'nameLocalized': nameLocalized,
      'description': description,
      'dailyPlan': dailyPlanMap,
      'isDeleted': isDeleted,
      'createdDate': createdDate != null ? Timestamp.fromDate(createdDate!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}