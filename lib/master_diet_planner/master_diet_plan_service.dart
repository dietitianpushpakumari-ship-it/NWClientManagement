// lib/services/master_diet_plan_service.dart

import 'dart:math';

import 'diet_plan_item_model.dart';


// --- Mock Data Store (Simulates database) ---
final List<MasterDietPlanModel> _mockPlansStore = [
  MasterDietPlanModel(
    id: 'plan_1',
    name: 'Beginner Weight Loss Plan',
    description: 'A simple plan focused on calorie deficit and high protein.',
    dietPlanCategoryIds: const ['cat1'],
    isActive: true,
    days: [
      MasterDayPlanModel(
        dayNameId: 'fixed_day_id',
        dayNameEn: 'Fixed Day Plan',
        meals: [
          // Breakfast
          DietPlanMealModel(mealNameId: 'm1', mealNameEn: 'Breakfast', items: [
            DietPlanItemModel(
                id: 'item_1_1', foodItemId: 'f1', foodItemName: 'Oats (40g=150KCal)', quantity: 80, unit: 'g', notes: '',
                foodItem: const FoodItem(id: 'f1', enName: 'Oats', servingUnitId: 'g', standardServingSizeG: 40, caloriesPerStandardServing: 150),
                alternatives: [
                  FoodItemAlternative(foodItemId: 'f2', foodItemName: 'Egg White (1pc=17KCal)', quantity: 10, unit: 'pc',
                      foodItem: const FoodItem(id: 'f2', enName: 'Egg White', servingUnitId: 'pc', standardServingSizeG: 30, caloriesPerStandardServing: 17))
                ]
            ),
          ]),
          // Lunch
          DietPlanMealModel(mealNameId: 'm2', mealNameEn: 'Lunch', items: [
            DietPlanItemModel(
              id: 'item_1_2', foodItemId: 'f3', foodItemName: 'Chicken Breast (100g=165KCal)', quantity: 150, unit: 'g', notes: '',
              foodItem: const FoodItem(id: 'f3', enName: 'Chicken Breast', servingUnitId: 'g', standardServingSizeG: 100, caloriesPerStandardServing: 165),
            ),
          ]),
          DietPlanMealModel(mealNameId: 'm3', mealNameEn: 'Dinner', items: []),
          DietPlanMealModel(mealNameId: 'm4', mealNameEn: 'Snack', items: []),
        ],
      ),
    ],
  ),
  MasterDietPlanModel(
    id: 'plan_2',
    name: 'Advanced Muscle Gain Plan',
    description: 'High calorie and protein intake for muscle growth.',
    dietPlanCategoryIds: const ['cat2'],
    isActive: true,
    days: const [], // Empty for brevity
  ),
];

// --- Service Class ---
class MasterDietPlanService {

  // 🎯 READ (LIST): Fetch all plans
  Future<List<MasterDietPlanModel>> fetchAllPlans() async {
    await Future.delayed(const Duration(milliseconds: 700)); // Simulate network delay
    // Return a deep copy to prevent external modification of the mock store
    return List<MasterDietPlanModel>.from(_mockPlansStore);
  }

  // 🎯 SAVE (CREATE/UPDATE): Save a plan
  Future<void> savePlan(MasterDietPlanModel plan) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockPlansStore.indexWhere((p) => p.id == plan.id);

    if (index != -1) {
      // Update (Edit mode)
      _mockPlansStore[index] = plan;
      print('Mock Service: Plan ${plan.id} updated.');
    } else {
      // Create (New plan)
      final newPlan = plan.copyWith(id: 'plan_${Random().nextInt(100000)}');
      _mockPlansStore.add(newPlan);
      print('Mock Service: New plan created with ID ${newPlan.id}.');
    }
  }

  // 🎯 DELETE: Soft delete (or hard delete for mock) a plan
  Future<void> deletePlan(String planId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final initialLength = _mockPlansStore.length;
    _mockPlansStore.removeWhere((p) => p.id == planId);
    if (_mockPlansStore.length < initialLength) {
      print('Mock Service: Plan $planId deleted.');
    } else {
      throw Exception('Plan with ID $planId not found.');
    }
  }
}