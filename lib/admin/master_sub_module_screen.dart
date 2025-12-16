// lib/screens/dash/MasterDataSubModuleScreen.dart

import 'package:flutter/material.dart';
import 'package:nutricare_client_management/admin/clinical_note_master_list_page.dart';
import 'package:nutricare_client_management/admin/generic_list_page_v2.dart' hide GenericListPageV2;
import 'dart:ui'; // Required for BackdropFilter (Glassmorphism effect)
import 'package:nutricare_client_management/master/model/master_constants.dart';
import 'package:nutricare_client_management/admin/generic_list_screen.dart';

// --- Specific Master Screens Imports (Needed for Navigation Logic) ---
import 'package:nutricare_client_management/master/screen/disease_master_list_screen.dart';
import 'package:nutricare_client_management/master/screen/supplementation_master_screen.dart';
import 'package:nutricare_client_management/master/screen/InvestigationMasterScreen.dart';
import 'package:nutricare_client_management/master/screen/habit_master_list_page.dart';
import 'package:nutricare_client_management/master/screen/food_category_list_page.dart';
import 'package:nutricare_client_management/master/screen/food_item_list_page.dart';
import 'package:nutricare_client_management/master/screen/master_meal_name_list_page.dart';
import 'package:nutricare_client_management/master/screen/serving_unit_list_page.dart';
import 'package:nutricare_client_management/master/screen/guideline_list_page.dart';
import 'package:nutricare_client_management/master_diet_planner/diet_plan_category_list_page.dart';
import 'package:nutricare_client_management/modules/master/screen/diagonosis_master_screen.dart';
import 'package:nutricare_client_management/modules/master/screen/master_diet_plan_list_screen.dart';
import 'package:nutricare_client_management/screens/package_list_page.dart';


class MasterDataSubModuleScreen extends StatelessWidget {
  final String moduleTitle;
  final List<Map<String, dynamic>> masters;
  final Color color;

  const MasterDataSubModuleScreen({
    super.key,
    required this.moduleTitle,
    required this.masters,
    required this.color,
  });

  // 🎯 NEW: Custom Header with Back Button (replaces AppBar)
  Widget _buildCustomHeaderWithBack(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, MediaQuery.of(context).padding.top + 5, 20, 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                color: Colors.black87,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              // Title
              Expanded(
                  child: Text(
                    moduleTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Re-used navigation logic from MasterSetupPage
  Widget _getNavigationWidget(String entityName, String collectionPath, String title) {
    switch (entityName) {
      case MasterEntity.entity_packages:
        return PackageListPage();
       // return GenericListPageV2(title: title, entityName: entityName, collectionPath: collectionPath);
      case MasterEntity.entity_MealNames:
        return const MasterMealNameListPage();
      case MasterEntity.entity_ServingUnits:
        return const ServingUnitListPage();
      case MasterEntity.entity_FoodItem:
        return const FoodItemListPage();
     // case MasterEntity.entity_FoodCategory:
       // return const FoodCategoryListPage();
      case MasterEntity.entity_MealNames:
        return const MasterMealNameListPage();
      case MasterEntity.entity_ServingUnits:
        return const ServingUnitListPage();
     case MasterEntity.entity_mealTemplates:
        return const MasterDietPlanListScreen();
      //case MasterEntity.entity_DietPlanCategories:
        //return const DietPlanCategoryListPage();
      default:
      // GenericListScreen requires the entityName and collectionPath for CRUD
        return GenericListPageV2(title: title, entityName: entityName, collectionPath: collectionPath);

    }
  }

  // Re-used premium tile logic
  Widget _buildMasterTile(BuildContext context, Map<String, dynamic> master) {
    final title = master['title'] as String;
    final entityName = master['entity'] as String;
    final icon = master['icon'] as IconData;
    final tileColor = master['color'] as Color;

    try {
      final collectionPath = MasterCollectionMapper.getPath(entityName);
      final targetWidget = _getNavigationWidget(entityName, collectionPath, title);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => targetWidget));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: tileColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: tileColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: tileColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink(); // Hide unmapped entities gracefully
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      // 🎯 FIX: Body uses Column with custom header and expanded ListView
      body: Column(
        children: [
          // Custom Header with Back Button
          _buildCustomHeaderWithBack(context),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              children: masters.map((master) => _buildMasterTile(context, master)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}