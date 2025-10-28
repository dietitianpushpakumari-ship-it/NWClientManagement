// lib/services/dependency_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nutricare_client_management/modules/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/modules/master/model/diet_plan_category.dart';
// Note: Replace with actual imports for your project structure
import '../../modules/master/model/food_category.dart';

class DependencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<FoodCategory>> fetchAllActiveFoodCategories() async {
    final snapshot = await _db
        .collection('foodCategories')
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .get();
    return snapshot.docs.map(FoodCategory.fromFirestore).toList();
  }

  Future<List<ServingUnit>> fetchAllActiveServingUnits() async {
    final snapshot = await _db
        .collection('servingUnits')
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .get();
    return snapshot.docs.map(ServingUnit.fromFirestore).toList();
  }
  Future<List<DietPlanCategory>> fetchAllActiveDietPlanCategories() async {
    // NOTE: Implement actual Firestore fetching here
    // Example only:
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      const DietPlanCategory(id: 'wgt-loss', enName: 'Weight Loss'),
      const DietPlanCategory(id: 'mus-gain', enName: 'Muscle Gain'),
      const DietPlanCategory(id: 'pcos-mgt', enName: 'PCOS Management'),
    ];
  }
}