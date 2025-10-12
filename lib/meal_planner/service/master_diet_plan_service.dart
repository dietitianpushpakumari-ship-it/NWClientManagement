// lib/services/master_diet_plan_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/master_diet_plan_model.dart';
// Note: Assuming DietPlanCategory is defined elsewhere
// Note: Assuming FoodItem and MasterMealName are the placeholder versions from master_diet_plan_model.dart

// --- PLACEHOLDER CLASSES (Assume these are defined elsewhere) ---
class DietPlanCategory { final String id; final String enName; DietPlanCategory({required this.id, required this.enName});}

class DependencyServices {
  // Placeholder methods to simulate fetching/caching master data
  List<DietPlanCategory> fetchAllActiveCategories() => [DietPlanCategory(id: 'cat1', enName: 'Weight Loss')];
  Future<List<FoodItem>> fetchAllActiveFoodItems() async {
    return const [
      FoodItem(id: 'f1', enName: 'Oats', servingUnitId: 'g', standardServingSizeG: 40, caloriesPerStandardServing: 150, proteinG: 5, carbsG: 27, fatG: 3),
      FoodItem(id: 'f2', enName: 'Egg White', servingUnitId: 'pc', standardServingSizeG: 30, caloriesPerStandardServing: 17, proteinG: 3.5, carbsG: 0.3, fatG: 0.1),
    ];
  }
  Map<String, FoodItem> getFoodItemCache() => {
    'f1': const FoodItem(id: 'f1', enName: 'Oats', servingUnitId: 'g', standardServingSizeG: 40, caloriesPerStandardServing: 150, proteinG: 5, carbsG: 27, fatG: 3),
    'f2': const FoodItem(id: 'f2', enName: 'Egg White', servingUnitId: 'pc', standardServingSizeG: 30, caloriesPerStandardServing: 17, proteinG: 3.5, carbsG: 0.3, fatG: 0.1),
  };
  Map<String, MasterMealName> getMealNameCache() => {
    'm1': const MasterMealName(id: 'm1', enName: 'Breakfast'),
    'm2': const MasterMealName(id: 'm2', enName: 'Lunch'),
  };
}


class MasterDietPlanService {
  // A mock collection reference for demonstration
  final CollectionReference _collection = FirebaseFirestore.instance.collection('masterDietPlans');
  final DependencyServices _deps = DependencyServices();

  // --- CORE METHODS ---

  /// Helper to reconstruct the complex model from a Firestore snapshot.
  MasterDietPlanModel _createModelFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 1. Fetch all dependencies (FoodItems, MealNames) to map the IDs back to objects
    final Map<String, FoodItem> foodItemCache = _deps.getFoodItemCache();
    final Map<String, MasterMealName> mealNameCache = _deps.getMealNameCache();

    // 2. Reconstruct dailyPlan
    List<MealPlanSlot> dailyPlan = [];
    final dailyPlanMap = data['dailyPlan'] as Map<String, dynamic>? ?? {};

    dailyPlanMap.forEach((mealNameId, slotData) {
      final mealName = mealNameCache[mealNameId];
      if (mealName == null) return;

      final List<dynamic> foodItemGroupsData = slotData['foodItemGroups'] ?? [];
      List<MealFoodItemOptionGroup> mealOptionGroups = [];

      for (var groupData in foodItemGroupsData) {
        // Reconstruct Primary Item
        final primaryItemData = groupData['primaryItem'];
        final primaryFoodItem = foodItemCache[primaryItemData['foodItemId']];
        if (primaryFoodItem == null) continue;
        final primaryMealFoodItem = MealFoodItem.fromMap(primaryItemData, primaryFoodItem);

        // Reconstruct Alternative Items
        final List<dynamic> alternativeItemsData = groupData['alternativeItems'] ?? [];
        List<MealFoodItem> alternativeMealFoodItems = [];
        for (var itemData in alternativeItemsData) {
          final foodItem = foodItemCache[itemData['foodItemId']];
          if (foodItem != null) {
            alternativeMealFoodItems.add(MealFoodItem.fromMap(itemData, foodItem));
          }
        }

        mealOptionGroups.add(MealFoodItemOptionGroup(
          primaryItem: primaryMealFoodItem,
          alternativeItems: alternativeMealFoodItems,
        ));
      }

      dailyPlan.add(MealPlanSlot(
        mealName: mealName,
        foodItemGroups: mealOptionGroups,
      ));
    });

    // 3. Reconstruct the main model
    return MasterDietPlanModel(
      id: doc.id,
      categoryId: data['categoryId'] ?? '',
      enName: data['enName'] ?? '',
      description: data['description'] ?? '',
      nameLocalized: Map<String, String>.from(data['nameLocalized'] ?? {}),
      dailyPlan: dailyPlan,
      isDeleted: data['isDeleted'] ?? false,
      createdDate: (data['createdDate'] as Timestamp?)?.toDate(), isActive: true,
    );
  }

  /// Saves or updates the diet plan.
  Future<void> savePlan(MasterDietPlanModel plan) async {
    final docRef = _collection.doc(plan.id.isEmpty ? null : plan.id);
    await docRef.set(plan.toMap(), SetOptions(merge: true));
  }
}