// lib/models/master_diet_plan_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// --- PLACEHOLDER MODELS (Assume these are defined elsewhere) ---

// Placeholder for FoodItem (Must have id, enName, standardServingSizeG, servingUnitId, and macro fields)
class FoodItem  {
  final String id;
  final String enName;
  final String servingUnitId;
  final double standardServingSizeG;
  final double caloriesPerStandardServing;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const FoodItem({
    required this.id,
    required this.enName,
    required this.servingUnitId,
    this.standardServingSizeG = 100.0,
    this.caloriesPerStandardServing = 0.0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
  });

  @override
  List<Object?> get props => [id];
}

// Placeholder for MasterMealName
class MasterMealName  {
  final String id;
  final String enName;
  const MasterMealName({required this.id, required this.enName});
  @override
  List<Object?> get props => [id];
}

// --- CORE MODELS ---

/// Represents a single food item with a specified quantity within a meal.
class MealFoodItem   {
  final FoodItem foodItem;
  final double quantityValue;

  // Calculated Macros based on quantityValue and FoodItem's data
  final double calculatedCalories;
  final double calculatedProteinG;
  final double calculatedCarbsG;
  final double calculatedFatG;

  MealFoodItem({
    required this.foodItem,
    required this.quantityValue,
  }) :
  // Calculation: multiplier = quantityValue / standardServingSizeG
  // Ensure division by zero safety
        calculatedCalories = foodItem.standardServingSizeG > 0
            ? foodItem.caloriesPerStandardServing * (quantityValue / foodItem.standardServingSizeG)
            : 0.0,
        calculatedProteinG = foodItem.standardServingSizeG > 0
            ? foodItem.proteinG * (quantityValue / foodItem.standardServingSizeG)
            : 0.0,
        calculatedCarbsG = foodItem.standardServingSizeG > 0
            ? foodItem.carbsG * (quantityValue / foodItem.standardServingSizeG)
            : 0.0,
        calculatedFatG = foodItem.standardServingSizeG > 0
            ? foodItem.fatG * (quantityValue / foodItem.standardServingSizeG)
            : 0.0;

  // Factory to convert from Firestore map (requires FoodItem data)
  factory MealFoodItem.fromMap(Map<String, dynamic> data, FoodItem foodItem) {
    return MealFoodItem(
      foodItem: foodItem,
      quantityValue: (data['quantityValue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItem.id,
      'quantityValue': quantityValue,
      'calculatedCalories': calculatedCalories,
      'calculatedProteinG': calculatedProteinG,
      'calculatedCarbsG': calculatedCarbsG,
      'calculatedFatG': calculatedFatG,
    };
  }

  // Used for editing/updating without recreating the object if necessary
  MealFoodItem copyWith({
    FoodItem? foodItem,
    double? quantityValue,
  }) {
    return MealFoodItem(
      foodItem: foodItem ?? this.foodItem,
      quantityValue: quantityValue ?? this.quantityValue,
    );
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


/// Represents one group of choices (a primary item and its alternatives).
class MealFoodItemOptionGroup  {
  final MealFoodItem primaryItem;
  final List<MealFoodItem> alternativeItems; // Optional alternatives for the client

  // Macros for the group are based on the primary item only
  double get groupCalories => primaryItem.calculatedCalories;
  double get groupProteinG => primaryItem.calculatedProteinG;
  double get groupCarbsG => primaryItem.calculatedCarbsG;
  double get groupFatG => primaryItem.calculatedFatG;

  const MealFoodItemOptionGroup({
    required this.primaryItem,
    this.alternativeItems = const [],
  });

  // Convert to map for storage (simplified for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'primaryItem': primaryItem.toMap(),
      'alternativeItems': alternativeItems.map((item) => item.toMap()).toList(),
    };
  }

  // Used for editing/updating without recreating the object
  MealFoodItemOptionGroup copyWith({
    MealFoodItem? primaryItem,
    List<MealFoodItem>? alternativeItems,
  }) {
    return MealFoodItemOptionGroup(
      primaryItem: primaryItem ?? this.primaryItem,
      alternativeItems: alternativeItems ?? this.alternativeItems,
    );
  }

  @override
  List<Object?> get props => [primaryItem, alternativeItems];
}


/// Represents a single meal (e.g., Breakfast) within a Master Diet Plan.
class MealPlanSlot  {
  final MasterMealName mealName;
  final List<MealFoodItemOptionGroup> foodItemGroups; // The list of item options

  // Total calculated macros for this meal slot (Sum of primary items in all groups)
  double get totalCalories => foodItemGroups.fold(0.0, (sum, group) => sum + group.groupCalories);
  double get totalProteinG => foodItemGroups.fold(0.0, (sum, group) => sum + group.groupProteinG);
  double get totalCarbsG => foodItemGroups.fold(0.0, (sum, group) => sum + group.groupCarbsG);
  double get totalFatG => foodItemGroups.fold(0.0, (sum, group) => sum + group.groupFatG);

  const MealPlanSlot({
    required this.mealName,
    this.foodItemGroups = const [],
  });

  @override
  List<Object?> get props => [mealName.id, foodItemGroups];
}


/// The main model representing the entire diet plan template.
class MasterDietPlanModel  {
  final String id;
  final String categoryId;
  final String enName;
  final Map<String, String> nameLocalized;
  final String description;
  final List<MealPlanSlot> dailyPlan;
  final bool isDeleted;
  final DateTime? createdDate;

  const MasterDietPlanModel({
    this.id = '',
    this.categoryId = '',
    this.enName = '',
    this.nameLocalized = const {},
    this.description = '',
    this.dailyPlan = const [],
    this.isDeleted = false,
    this.createdDate, required bool isActive,
  });

  @override
  List<Object?> get props => [id];

  // Helper to convert model to map for saving (simplified for Firestore)
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> dailyPlanMap = {};
    for (var slot in dailyPlan) {
      dailyPlanMap[slot.mealName.id] = {
        'mealNameId': slot.mealName.id,
        // Convert list of groups to map list
        'foodItemGroups': slot.foodItemGroups.map((group) => group.toMap()).toList(),
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