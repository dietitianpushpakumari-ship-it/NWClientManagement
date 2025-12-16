// lib/services/dependency_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutricare_client_management/admin/database_provider.dart';
import 'package:nutricare_client_management/master/model/ServingUnit.dart';
import 'package:nutricare_client_management/master/model/diet_plan_category.dart';
// Note: Replace with actual imports for your project structure
import '../../master/model/food_category.dart';

class DependencyService {
  final Ref _ref; // Store Ref to access dynamic providers
  DependencyService(this._ref);

  // 🎯 DYNAMIC GETTERS (Switch based on Tenant)
  // These will now automatically point to 'Guest', 'Live', or 'Clinic A' DB
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);


  Future<List<FoodCategory>> fetchAllActiveFoodCategories() async {
    final snapshot = await _firestore
        .collection('foodCategories')
        .where('isDeleted', isEqualTo: false)
        .orderBy('enName')
        .get();
    return snapshot.docs.map(FoodCategory.fromFirestore).toList();
  }

  Future<List<ServingUnit>> fetchAllActiveServingUnits() async {
    final snapshot = await _firestore
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
      const DietPlanCategory(id: 'wgt-loss', name: 'Weight Loss'),
      const DietPlanCategory(id: 'mus-gain', name: 'Muscle Gain'),
      const DietPlanCategory(id: 'pcos-mgt', name: 'PCOS Management'),
    ];
  }
}