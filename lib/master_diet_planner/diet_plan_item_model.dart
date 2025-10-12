// lib/models/master_diet_plan_models.dart



// --- Placeholder Food Item (Must contain nutritional data for calculations) ---
class FoodItem {
  final String id; final String enName; final String servingUnitId;
  final double standardServingSizeG; // size of the standard serving in grams
  final double caloriesPerStandardServing;
  final double proteinG;
  final double carbsG;
  final double fatG;

  // NOTE: Mock data in DependencyServices uses a more descriptive enName
  const FoodItem({
    required this.id, required this.enName, required this.servingUnitId,
    this.standardServingSizeG = 100, this.caloriesPerStandardServing = 100,
    this.proteinG = 0, this.carbsG = 0, this.fatG = 0
  });
  FoodItem copyWith({
    String? id, String? enName, String? servingUnitId,
    double? standardServingSizeG, double? caloriesPerStandardServing,
    double? proteinG, double? carbsG, double? fatG,
  }) {
    return FoodItem(
      id: id ?? this.id,
      enName: enName ?? this.enName,
      servingUnitId: servingUnitId ?? this.servingUnitId,
      standardServingSizeG: standardServingSizeG ?? this.standardServingSizeG,
      caloriesPerStandardServing: caloriesPerStandardServing ?? this.caloriesPerStandardServing,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
    );
  }

  @override
  bool operator ==(Object other) {
    // Check if the other object is a FoodItem and has the same unique ID.
    return identical(this, other) ||
        other is FoodItem &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to calculate macros for a given quantity
  Map<String, double> calculateMacros(double quantity) {
    if (standardServingSizeG == 0) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};

    // Assuming quantity is in the food item's serving unit
    final ratio = quantity / standardServingSizeG;

    return {
      'calories': caloriesPerStandardServing * ratio,
      'protein': proteinG * ratio,
      'carbs': carbsG * ratio,
      'fat': fatG * ratio,
    };
  }
}
// --------------------------------------------------------------------------

// 1. Food Item Alternative
class FoodItemAlternative {
  final String foodItemId;
  final String foodItemName;
  final double quantity;
  final String unit;
  // Add reference to the FoodItem object for detailed view calculation
  final FoodItem? foodItem;

  const FoodItemAlternative({
    required this.foodItemId,
    required this.foodItemName,
    required this.quantity,
    required this.unit,
    this.foodItem,
  });

  FoodItemAlternative copyWith({FoodItem? foodItem}) =>
      FoodItemAlternative(
          foodItemId: foodItemId, foodItemName: foodItemName,
          quantity: quantity, unit: unit,
          foodItem: foodItem ?? this.foodItem
      );


  @override
  List<Object?> get props => [foodItemId, quantity, unit];
}

// 2. Diet Plan Item Model
class DietPlanItemModel {
  final String id;
  final String foodItemId;
  final String foodItemName;
  final double quantity;
  final String unit;
  final String notes;
  final List<FoodItemAlternative> alternatives;
  final FoodItem? foodItem; // Reference to the actual FoodItem for calculations

  const DietPlanItemModel({
    required this.id,
    required this.foodItemId,
    required this.foodItemName,
    required this.quantity,
    required this.unit,
    this.notes = '',
    this.alternatives = const [],
    this.foodItem,
  });

  DietPlanItemModel copyWith({List<FoodItemAlternative>? alternatives, FoodItem? foodItem}) =>
      DietPlanItemModel(
          id: id, foodItemId: foodItemId, foodItemName: foodItemName, quantity: quantity,
          unit: unit, notes: notes, alternatives: alternatives ?? this.alternatives, foodItem: foodItem ?? this.foodItem
      );

  // Method to get the total macros for this item
  Map<String, double> get itemMacros {
    if (foodItem == null) return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    return foodItem!.calculateMacros(quantity);
  }

  @override
  List<Object?> get props => [id, foodItemId, quantity, unit, notes, alternatives];
}

// 3. Diet Plan Meal Model
class DietPlanMealModel  {
  final String mealNameId;
  final String mealNameEn;
  final List<DietPlanItemModel> items;

  const DietPlanMealModel({required this.mealNameId, required this.mealNameEn, this.items = const []});
  DietPlanMealModel copyWith({List<DietPlanItemModel>? items}) => DietPlanMealModel(mealNameId: mealNameId, mealNameEn: mealNameEn, items: items ?? this.items);

  // Method to get the total macros for this meal
  Map<String, double> get mealMacros {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    for (var item in items) {
      final macros = item.itemMacros;
      totalCalories += macros['calories']!;
      totalProtein += macros['protein']!;
      totalCarbs += macros['carbs']!;
      totalFat += macros['fat']!;
    }
    return {'calories': totalCalories, 'protein': totalProtein, 'carbs': totalCarbs, 'fat': totalFat};
  }

  @override
  List<Object?> get props => [mealNameId, items];
}

// 4. Master Day Plan Model
class MasterDayPlanModel  {
  final String dayNameId;
  final String dayNameEn;
  final List<DietPlanMealModel> meals;

  const MasterDayPlanModel({required this.dayNameId, required this.dayNameEn, this.meals = const []});
  MasterDayPlanModel copyWith({List<DietPlanMealModel>? meals}) => MasterDayPlanModel(dayNameId: dayNameId, dayNameEn: dayNameEn, meals: meals ?? this.meals);

  // Method to get the total macros for this day
  Map<String, double> get dayMacros {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    for (var meal in meals) {
      final macros = meal.mealMacros;
      totalCalories += macros['calories']!;
      totalProtein += macros['protein']!;
      totalCarbs += macros['carbs']!;
      totalFat += macros['fat']!;
    }
    return {'calories': totalCalories, 'protein': totalProtein, 'carbs': totalCarbs, 'fat': totalFat};
  }

  @override
  List<Object?> get props => [dayNameId, meals];
}

// 5. Master Diet Plan Model (The main object)
class MasterDietPlanModel {
  final String id;
  final String name;
  final String description;
  final List<String> dietPlanCategoryIds;
  final bool isActive;

  // For a repeating plan, this list will only contain ONE MasterDayPlanModel
  final List<MasterDayPlanModel> days;

  const MasterDietPlanModel({
    required this.id,
    required this.name,
    required this.description,
    this.dietPlanCategoryIds = const [],
    this.isActive = true,
    this.days = const []
  });

  MasterDietPlanModel copyWith(
      {bool? isActive, String? name, String? description, List<
          MasterDayPlanModel>? days, required String id}) =>
      MasterDietPlanModel(
          id: id,
          name: name ?? this.name,
          description: description ?? this.description,
          dietPlanCategoryIds: dietPlanCategoryIds,
          isActive: isActive ?? this.isActive,
          days: days ?? this.days
      );

  // Method to get the total macros for the entire plan (Average of all days, but here, just the one day)
  Map<String, double> get planMacros {
    if (days.isEmpty)
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    // For a single fixed day plan, we just return the day's macros
    return days.first.dayMacros;
  }
}
  class MasterDayName { final String id; final String enName; const MasterDayName({this.id = '', this.enName = ''});}
  class MasterMealName { final String id; final String enName; const MasterMealName({this.id = '', this.enName = ''}); }
  class DietPlanCategory { final String id; final String enName; DietPlanCategory({required this.id, required this.enName, required bool isDeleted});}
// --- Other necessary utility models (placeholders) ---